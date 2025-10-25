import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';
import 'package:absencobra/utility/settings.dart';
import '../user.dart';

// Model untuk slip gaji
class SlipGajiData {
  final String periode;
  final String nama;
  final String jabatan;
  final String nik;
  final String unit;
  final int gajiPokok;
  final int tunjanganJabatan;
  final int tunjanganMakanTransport;
  final int lemburTetap;
  final int lemburNasional;
  final int lemburBackup;
  final int potonganAbsensi;
  final int bpjsTk;
  final int bpjsKes;
  final int registrasi;
  final int seragam;
  final int pph21;
  final int adminBank;
  final int totalBruto;
  final int totalPotongan;
  final int totalBersih;
  final String? qrcode;
  final String? penerbit;

  SlipGajiData({
    required this.periode,
    required this.nama,
    required this.jabatan,
    required this.nik,
    required this.unit,
    required this.gajiPokok,
    required this.tunjanganJabatan,
    required this.tunjanganMakanTransport,
    required this.lemburTetap,
    required this.lemburNasional,
    required this.lemburBackup,
    required this.potonganAbsensi,
    required this.bpjsTk,
    required this.bpjsKes,
    required this.registrasi,
    required this.seragam,
    required this.pph21,
    required this.adminBank,
    required this.totalBruto,
    required this.totalPotongan,
    required this.totalBersih,
    this.qrcode,
    this.penerbit,
  });

  factory SlipGajiData.fromJson(Map<String, dynamic> json) {
    return SlipGajiData(
      periode: json['periode']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
      jabatan: json['jabatan']?.toString() ?? '',
      nik: json['nik']?.toString() ?? '',
      unit: json['unit']?.toString() ?? 'TBINA',
      gajiPokok: int.tryParse(json['gaji_pokok']?.toString() ?? '0') ?? 0,
      tunjanganJabatan:
          int.tryParse(json['tunjangan_jabatan']?.toString() ?? '0') ?? 0,
      tunjanganMakanTransport:
          int.tryParse(json['tunjangan_makan_transport']?.toString() ?? '0') ??
          0,
      lemburTetap: int.tryParse(json['lembur_tetap']?.toString() ?? '0') ?? 0,
      lemburNasional:
          int.tryParse(json['lembur_nasional']?.toString() ?? '0') ?? 0,
      lemburBackup: int.tryParse(json['lembur_backup']?.toString() ?? '0') ?? 0,
      potonganAbsensi:
          int.tryParse(json['potongan_absensi']?.toString() ?? '0') ?? 0,
      bpjsTk: int.tryParse(json['bpjs_tk']?.toString() ?? '0') ?? 0,
      bpjsKes: int.tryParse(json['bpjs_kes']?.toString() ?? '0') ?? 0,
      registrasi: int.tryParse(json['registrasi']?.toString() ?? '0') ?? 0,
      seragam: int.tryParse(json['seragam']?.toString() ?? '0') ?? 0,
      pph21: int.tryParse(json['pph21']?.toString() ?? '0') ?? 0,
      adminBank: int.tryParse(json['admin_bank']?.toString() ?? '0') ?? 0,
      totalBruto: int.tryParse(json['total_bruto']?.toString() ?? '0') ?? 0,
      totalPotongan:
          int.tryParse(json['total_potongan']?.toString() ?? '0') ?? 0,
      totalBersih: int.tryParse(json['total_bersih']?.toString() ?? '0') ?? 0,
      qrcode: json['qrcode']?.toString(),
      penerbit: json['penerbit']?.toString(),
    );
  }
}

// State untuk slip gaji
class SlipGajiState {
  final SlipGajiData? slipData;
  final bool isLoading;
  final String? error;
  final int? selectedMonth;
  final int? selectedYear;

  const SlipGajiState({
    this.slipData,
    this.isLoading = false,
    this.error,
    this.selectedMonth,
    this.selectedYear,
  });

  SlipGajiState copyWith({
    SlipGajiData? slipData,
    bool? isLoading,
    String? error,
    int? selectedMonth,
    int? selectedYear,
  }) {
    return SlipGajiState(
      slipData: slipData ?? this.slipData,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedYear: selectedYear ?? this.selectedYear,
    );
  }
}

// Slip Gaji Notifier
class SlipGajiNotifier extends Notifier<SlipGajiState> {
  @override
  SlipGajiState build() {
    return const SlipGajiState();
  }

  // Set selected month and year
  void setSelectedPeriod(int month, int year) {
    state = state.copyWith(
      selectedMonth: month,
      selectedYear: year,
      error: null,
    );
  }

  // Fetch slip gaji data
  Future<void> fetchSlipGaji(User user) async {
    if (state.selectedMonth == null || state.selectedYear == null) {
      state = state.copyWith(
        error: 'Pilih bulan & tahun terlebih dahulu',
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final idpegawai = user.id_pegawai.toString();

      log("id_pegawai : $idpegawai");

      final bulan = state.selectedMonth!;
      final tahun = state.selectedYear!;
      final url = Uri.parse('$kBaseUrl/include/slipgajiapi.php').replace(
        queryParameters: {
          'idpegawai': idpegawai,
          'periode_bulan': bulan.toString().padLeft(2, '0'),
          'periode_tahun': tahun.toString(),
        },
      );

      final response = await http.get(url);
      if (response.statusCode != 200) {
        state = state.copyWith(
          error: 'Status ${response.statusCode}',
          isLoading: false,
        );
        return;
      }

      final data = jsonDecode(response.body);
      final slipData = SlipGajiData.fromJson(data);

      log("data slip gaji: $data");

      state = state.copyWith(slipData: slipData, isLoading: false, error: null);
    } catch (e) {
      log('Slip gaji error: $e');
      state = state.copyWith(error: 'Error: $e', isLoading: false);
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Reset state
  void reset() {
    state = const SlipGajiState();
  }
}

// Provider untuk SlipGajiNotifier
final slipGajiProvider = NotifierProvider<SlipGajiNotifier, SlipGajiState>(() {
  return SlipGajiNotifier();
});

// Provider untuk slip gaji data
final slipGajiDataProvider = Provider<SlipGajiData?>((ref) {
  return ref.watch(slipGajiProvider).slipData;
});

// Provider untuk loading status
final slipGajiLoadingProvider = Provider<bool>((ref) {
  return ref.watch(slipGajiProvider).isLoading;
});

// Provider untuk error
final slipGajiErrorProvider = Provider<String?>((ref) {
  return ref.watch(slipGajiProvider).error;
});

// Provider untuk selected period
final selectedPeriodProvider = Provider<Map<String, int?>>((ref) {
  final state = ref.watch(slipGajiProvider);
  return {'month': state.selectedMonth, 'year': state.selectedYear};
});
