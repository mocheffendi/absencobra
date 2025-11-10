import 'dart:convert';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/absen_service.dart';

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

  void reset() {
    state = const AbsenData(
      absensi7: [],
      wktMasukToday: null,
      wktPulangToday: null,
      isLoading: false,
    );
  }

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

      final rows = await AbsenService.getAbsenData(idPegawai);
      // find today's masuk and pulang using the service helper
      final todaysData = AbsenService.getTodaysAbsen(rows);
      final todaysIn = todaysData?['in'];
      final todaysOut = todaysData?['out'];

      // Determine most recent 7 days from the returned rows.
      // Rows contain 'tanggal' in DD-MM-YYYY (or reformatted) as returned by AbsenService.
      // We'll parse the date, sort descending by date, take up to 7 most recent unique dates,
      // and then present them in chronological order (oldest -> newest) for UI display.
      List<Map<String, String>> last7 = [];
      try {
        final parsed = rows
            .map((r) {
              final t = (r['tanggal'] ?? '').toString();
              DateTime? dt;
              // Try parse DD-MM-YYYY
              try {
                final parts = t.split('-');
                if (parts.length == 3) {
                  final dd = int.tryParse(parts[0]);
                  final mm = int.tryParse(parts[1]);
                  final yy = int.tryParse(parts[2]);
                  if (dd != null && mm != null && yy != null) {
                    dt = DateTime(yy, mm, dd);
                  }
                }
              } catch (_) {
                dt = null;
              }
              // Fallback: try YYYY-MM-DD
              if (dt == null) {
                try {
                  dt = DateTime.tryParse(t);
                } catch (_) {
                  dt = null;
                }
              }
              return {'row': r, 'date': dt};
            })
            .where((e) => e['date'] != null)
            .toList();

        // Sort by date descending (newest first)
        parsed.sort(
          (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
        );

        // Keep unique dates (by formatted date string) and take up to 7
        final seen = <String>{};
        for (final e in parsed) {
          final r = e['row'] as Map<String, String>;
          final dateStr = r['tanggal'] ?? '';
          if (!seen.contains(dateStr)) {
            seen.add(dateStr);
            last7.add(r);
            if (last7.length >= 7) break;
          }
        }

        // Present in order newest -> oldest so the most recent day appears at the top
        // (do not reverse here; parsed was already sorted newest-first)
      } catch (_) {
        // If parsing fails for any reason, fall back to returning the raw rows (but this should be rare)
        last7 = rows;
      }

      // Reset today's data first, then set new values
      state = state.copyWith(
        absensi7: last7,
        wktMasukToday: null, // Reset first
        wktPulangToday: null, // Reset first
        isLoading: false,
      );

      // Then set today's data if available
      if (todaysData != null) {
        state = state.copyWith(
          wktMasukToday: todaysIn,
          wktPulangToday: todaysOut,
        );
      }

      log(
        'AbsenProvider: State updated - absensi7 length: ${rows.length}, wktMasukToday: ${state.wktMasukToday}, wktPulangToday: ${state.wktPulangToday}',
      );
    } catch (e) {
      log('AbsenProvider: Error loading absen data: $e');
      state = state.copyWith(isLoading: false);
    }
  }
}

final absenProvider = NotifierProvider<AbsenNotifier, AbsenData>(() {
  return AbsenNotifier();
});
