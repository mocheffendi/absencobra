import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../user.dart';

class AbsenData {
  final List<Map<String, String>> absensi7;
  final String? wktMasukToday;
  final String? wktPulangToday;
  final bool isLoading;

  const AbsenData({
    required this.absensi7,
    this.wktMasukToday,
    this.wktPulangToday,
    this.isLoading = false,
  });

  AbsenData copyWith({
    List<Map<String, String>>? absensi7,
    String? wktMasukToday,
    String? wktPulangToday,
    bool? isLoading,
  }) {
    return AbsenData(
      absensi7: absensi7 ?? this.absensi7,
      wktMasukToday: wktMasukToday ?? this.wktMasukToday,
      wktPulangToday: wktPulangToday ?? this.wktPulangToday,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AbsenNotifier extends Notifier<AbsenData> {
  @override
  AbsenData build() => const AbsenData(absensi7: []);

  Future<void> loadAbsenData() async {
    try {
      state = state.copyWith(isLoading: true);

      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      User? user;
      if (userJson != null) {
        try {
          user = User.fromJson(json.decode(userJson));
        } catch (e) {
          // ignore parsing errors
        }
      }

      if (user == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final idPegawai = user.id_pegawai.toString();
      if (idPegawai.isEmpty) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final uri = Uri.parse(
        'https://absencobra.cbsguard.co.id/api/get_tb_absen.php?id_pegawai=$idPegawai',
      );
      final r = await http.get(uri);
      if (r.statusCode == 200) {
        final body = json.decode(r.body);
        List<dynamic> items = [];
        if (body is Map && body['data'] is List) {
          items = body['data'];
        } else if (body is List) {
          items = body;
        } else if (body is Map) {
          items = [body];
        }

        // Map to our simplified structure: tanggal (harimasuk), in (wktmasuk), out (wktpulang/wktkeluar)
        final List<Map<String, String>> rows = items.map<Map<String, String>>((
          it,
        ) {
          try {
            final m = Map<String, dynamic>.from(it as Map);
            String tanggalRaw = (m['harimasuk'] ?? m['tanggal'] ?? '')
                .toString();
            // Extract only date part (YYYY-MM-DD or DD-MM-YYYY)
            String tanggalOnly = tanggalRaw.split(' ').first;
            // Try to parse and reformat to DD-MM-YYYY
            String tanggalFormatted = tanggalOnly;
            try {
              // Accept both YYYY-MM-DD and DD-MM-YYYY
              DateTime? dt;
              if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(tanggalOnly) ||
                  tanggalOnly.contains('-')) {
                // Try YYYY-MM-DD
                dt = DateTime.tryParse(tanggalOnly);
                if (dt == null && tanggalOnly.contains('-')) {
                  // Try DD-MM-YYYY
                  final parts = tanggalOnly.split('-');
                  if (parts.length == 3) {
                    dt = DateTime.tryParse(
                      '${parts[2]}-${parts[1]}-${parts[0]}',
                    );
                  }
                }
              }
              if (dt != null) {
                tanggalFormatted =
                    '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
              }
            } catch (_) {}
            final masuk =
                (m['wktmasuk'] ?? m['jam_masuk'] ?? m['jammasuk'] ?? '')
                    .toString();
            final keluar =
                (m['wktpulang'] ??
                        m['wktkeluar'] ??
                        m['jam_keluar'] ??
                        m['jampulang'] ??
                        '')
                    .toString();
            return {'tanggal': tanggalFormatted, 'in': masuk, 'out': keluar};
          } catch (_) {
            return {'tanggal': '', 'in': '', 'out': ''};
          }
        }).toList();

        // find today's masuk and pulang (compare date part, support DD-MM-YYYY & YYYY-MM-DD)
        final today = DateTime.now();
        final todayStr1 =
            '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}'; // YYYY-MM-DD
        final todayStr2 =
            '${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}'; // DD-MM-YYYY
        String? todaysIn;
        String? todaysOut;
        for (final r in rows) {
          final t = r['tanggal'] ?? '';
          if (t == todayStr1 || t == todayStr2) {
            if ((r['in'] != null && r['in']!.isNotEmpty) && todaysIn == null) {
              todaysIn = r['in'];
            }
            if ((r['out'] != null && r['out']!.isNotEmpty) &&
                todaysOut == null) {
              todaysOut = r['out'];
            }
            if (todaysIn != null && todaysOut != null) break;
          }
        }

        state = state.copyWith(
          absensi7: rows,
          wktMasukToday: todaysIn,
          wktPulangToday: todaysOut,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final absenProvider = NotifierProvider<AbsenNotifier, AbsenData>(() {
  return AbsenNotifier();
});
