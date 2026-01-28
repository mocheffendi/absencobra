import 'dart:developer';
import 'dart:ui' as ui;

import 'package:cobra_apps/widgets/gradient_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/slip_gaji_provider.dart';
import '../providers/user_provider.dart';
import 'pdf_preview_page.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../utility/file_utils.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';

class SlipGajiPage extends ConsumerStatefulWidget {
  const SlipGajiPage({super.key});

  @override
  ConsumerState<SlipGajiPage> createState() => _SlipGajiPageState();
}

class _SlipGajiPageState extends ConsumerState<SlipGajiPage> {
  @override
  Widget build(BuildContext context) {
    final slipGajiState = ref.watch(slipGajiProvider);
    final isLoading = slipGajiState.isLoading;
    // final slipData = slipGajiState.slipData; // unused here
    final selectedMonth = slipGajiState.selectedMonth;
    final selectedYear = slipGajiState.selectedYear;

    // Listen to error changes
    ref.listen<String?>(slipGajiErrorProvider, (previous, next) {
      if (next != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next)));
        // Clear error after showing in the next frame to avoid provider rebuild
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) ref.read(slipGajiProvider.notifier).clearError();
        });
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 50,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('Slip Gaji', style: TextStyle(color: Colors.white)),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset('assets/jpg/bg_blur.jpg', fit: BoxFit.cover),
          ),
          // Frosted glass overlay: blur the background image beneath the content
          // Positioned.fill(
          //   child: ClipRect(
          //     child: BackdropFilter(
          //       filter: ui.ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          //       child: Container(
          //         // subtle dark tint so content remains readable
          //         color: Colors.black.withValues(alpha: 0.12),
          //       ),
          //     ),
          //   ),
          // ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: InkWell(
                          onTap: () async {
                            final now = DateTime.now();
                            final picked = await showMonthYearPicker(
                              context: context,
                              initialDate: DateTime(now.year, now.month),
                              firstDate: DateTime(now.year - 5, 1),
                              lastDate: DateTime(now.year + 1, 12),
                            );
                            if (picked != null) {
                              ref
                                  .read(slipGajiProvider.notifier)
                                  .setSelectedPeriod(picked.month, picked.year);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Pilih Bulan & Tahun',
                              border: OutlineInputBorder(),
                              labelStyle: TextStyle(color: Colors.white),
                            ),
                            child: Text(
                              selectedMonth != null && selectedYear != null
                                  ? '${selectedMonth.toString().padLeft(2, '0')}/$selectedYear'
                                  : 'Belum dipilih',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: gradientPillButton(
                          label: 'Pdf',
                          onTap: _fetchAndPreview,
                          icon: Icons.picture_as_pdf_rounded,
                          colors: const [Color(0xff2dd7a6), Color(0xff46a6ff)],
                        ),
                      ),
                      // ElevatedButton(
                      //   onPressed: isLoading ? null : () => _fetchAndPreview(),
                      //   child: const Text('PDF'),
                      // ),
                    ],
                  ),
                  // const SizedBox(height: 16),
                  // if (isLoading) const CircularProgressIndicator(),
                  // if (slipData != null) _buildDataList(slipData),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Removed _buildDataList as it was unused. Keep implementation nearby
  // if needed for future UI listing of slip data.

  // ignore: unused_element
  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  Future<void> _fetchAndPreview() async {
    final user = ref.watch(userProvider);
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User tidak ditemukan')));
      }
      return;
    }

    await ref.read(slipGajiProvider.notifier).fetchSlipGaji(user);

    final state = ref.read(slipGajiProvider);
    if (state.slipData != null && mounted) {
      // Generate PDF and navigate to preview
      try {
        final selectedMonth = state.selectedMonth;
        final selectedYear = state.selectedYear;
        String? periodeStr;
        if (selectedMonth != null && selectedYear != null) {
          periodeStr =
              '${selectedMonth.toString().padLeft(2, '0')}/$selectedYear';
        }
        final pdfPath = await _generateAndSavePdf(
          state.slipData!,
          periodeOverride: periodeStr,
        );
        if (pdfPath != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PdfPreviewPage(filePath: pdfPath),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal membuat PDF: $e')));
          log('PDF generation error: $e');
        }
      }
    }
  }

  Future<String?> _generateAndSavePdf(
    SlipGajiData data, {
    String? periodeOverride,
  }) async {
    final pdf = pw.Document();

    String rp(dynamic v) {
      if (v == null) return '-';
      final intValue = v is int
          ? v
          : int.tryParse(v.toString().replaceAll(RegExp(r'[^0-9-]'), '')) ?? 0;
      final formatter = NumberFormat.currency(
        locale: 'id_ID',
        symbol: '',
        decimalDigits: 0,
      );
      final formatted = formatter.format(intValue);
      return 'Rp ${formatted.trim()}';
    }

    String terbilangInt(int n) {
      const satuan = [
        '',
        'satu',
        'dua',
        'tiga',
        'empat',
        'lima',
        'enam',
        'tujuh',
        'delapan',
        'sembilan',
      ];
      if (n == 0) return 'nol';
      if (n < 0) return 'minus ${terbilangInt(-n)}';
      if (n < 10) return satuan[n];
      if (n < 20) {
        if (n == 10) return 'sepuluh';
        if (n == 11) return 'sebelas';
        return '${terbilangInt(n - 10)} belas';
      }
      if (n < 100) {
        final puluh = n ~/ 10;
        final sisa = n % 10;
        return '${satuan[puluh]} puluh${sisa == 0 ? '' : ' ${terbilangInt(sisa)}'}';
      }
      if (n < 200) {
        return 'seratus${n == 100 ? '' : ' ${terbilangInt(n - 100)}'}';
      }
      if (n < 1000) {
        final ratus = n ~/ 100;
        final sisa = n % 100;
        return '${satuan[ratus]} ratus${sisa == 0 ? '' : ' ${terbilangInt(sisa)}'}';
      }
      if (n < 2000) {
        return 'seribu${n == 1000 ? '' : ' ${terbilangInt(n - 1000)}'}';
      }
      if (n < 1000000) {
        final ribu = n ~/ 1000;
        final sisa = n % 1000;
        return '${terbilangInt(ribu)} ribu${sisa == 0 ? '' : ' ${terbilangInt(sisa)}'}';
      }
      if (n < 1000000000) {
        final juta = n ~/ 1000000;
        final sisa = n % 1000000;
        return '${terbilangInt(juta)} juta${sisa == 0 ? '' : ' ${terbilangInt(sisa)}'}';
      }
      if (n < 1000000000000) {
        final miliar = n ~/ 1000000000;
        final sisa = n % 1000000000;
        return '${terbilangInt(miliar)} miliar${sisa == 0 ? '' : ' ${terbilangInt(sisa)}'}';
      }
      final triliun = n ~/ 1000000000000;
      final sisa = n % 1000000000000;
      return '${terbilangInt(triliun)} triliun${sisa == 0 ? '' : ' ${terbilangInt(sisa)}'}';
    }

    String toTerbilangRupiah(dynamic v) {
      final n = v is int
          ? v
          : int.tryParse(v.toString().replaceAll(RegExp(r'[^0-9-]'), '')) ?? 0;
      final words = terbilangInt(n);
      final capitalized = words
          .split(' ')
          .where((w) => w.isNotEmpty)
          .map((w) => w[0].toUpperCase() + w.substring(1))
          .join(' ');
      return '$capitalized Rupiah';
    }

    final logoBytes = await rootBundle.load('assets/png/logo.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    final qrPlaceholderBytes = await rootBundle.load(
      'assets/png/QRCodeGaji.png',
    );
    final qrPlaceholderImage = pw.MemoryImage(
      qrPlaceholderBytes.buffer.asUint8List(),
    );

    final int bpjsTotal = data.bpjsTk + data.bpjsKes;

    // Format periode: if periodeOverride like 'MM/YYYY' is provided,
    // convert month number to Indonesian month name (e.g. 'Oktober / 2025').
    String formatPeriode(String? override, String fallback) {
      if (override == null) return fallback;
      final m = RegExp(r'^(\d{1,2})\/(\d{4})').firstMatch(override);
      if (m != null) {
        final mon = int.tryParse(m.group(1) ?? '0') ?? 0;
        final yr = m.group(2) ?? '';
        const months = [
          'Januari',
          'Februari',
          'Maret',
          'April',
          'Mei',
          'Juni',
          'Juli',
          'Agustus',
          'September',
          'Oktober',
          'November',
          'Desember',
        ];
        final name = (mon >= 1 && mon <= 12) ? months[mon - 1] : override;
        return '$name $yr';
      }
      return override;
    }

    final displayPeriode = formatPeriode(periodeOverride, data.periode);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (c) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 60,
                      height: 60,
                      child: pw.Image(logoImage),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'PT. SYUKRI BHAKTI ABADI KOBRA SERPIS',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          pw.Text(
                            'Jl. Karang Satria Ruko Karang Satria Square Blok D No. 20 & 23',
                          ),
                          pw.Text(
                            'Karang Satria Tambun Utara Kota Bekasi Jawa Barat 17510',
                          ),
                          pw.Text(
                            'website : www.sbakobra.com    email : contact@sbakobra.com',
                          ),
                        ],
                      ),
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'SLIP GAJI',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          displayPeriode,
                          style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text('Nama Karyawan : '),
                        pw.Text(
                          data.nama,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.Text('Jabatan : ${data.jabatan}'),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('NIK : ${data.nik}'),
                    pw.Text('UNIT : ${data.unit}'),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Container(height: 1, color: PdfColors.black),
                pw.SizedBox(height: 2),
                pw.Container(height: 1, color: PdfColors.black),
                pw.SizedBox(height: 3),
                // PENDAPATAN / POTONGAN columns
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'PENDAPATAN',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 16),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'POTONGAN',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            children: [
                              pw.Expanded(child: pw.Text('GAJI POKOK')),
                              pw.Text(rp(data.gajiPokok)),
                            ],
                          ),
                          pw.Row(
                            children: [
                              pw.Expanded(child: pw.Text('TUNJANGAN JABATAN')),
                              pw.Text(rp(data.tunjanganJabatan)),
                            ],
                          ),
                          pw.Row(
                            children: [
                              pw.Expanded(
                                child: pw.Text('TUNJANGAN MAKAN/TRANSPOR'),
                              ),
                              pw.Text(rp(data.tunjanganMakanTransport)),
                            ],
                          ),
                          pw.Row(
                            children: [
                              pw.Expanded(child: pw.Text('LEMBUR WAJIB')),
                              pw.Text(rp(data.lemburTetap)),
                            ],
                          ),
                          pw.Row(
                            children: [
                              pw.Expanded(child: pw.Text('LEMBUR NASIONAL')),
                              pw.Text(rp(data.lemburNasional)),
                            ],
                          ),
                          pw.Row(
                            children: [
                              pw.Expanded(child: pw.Text('LEMBUR BACK UP')),
                              pw.Text(rp(data.lemburBackup)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 16),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            children: [
                              pw.Expanded(child: pw.Text('Pot. Absensi')),
                              pw.Text(rp(data.potonganAbsensi)),
                            ],
                          ),
                          pw.Row(
                            children: [
                              pw.Expanded(child: pw.Text('BPJS')),
                              pw.Text(rp(bpjsTotal)),
                            ],
                          ),
                          pw.Row(
                            children: [
                              pw.Expanded(child: pw.Text('Registrasi')),
                              pw.Text(rp(data.registrasi)),
                            ],
                          ),
                          pw.Row(
                            children: [
                              pw.Expanded(child: pw.Text('Seragam')),
                              pw.Text(rp(data.seragam)),
                            ],
                          ),
                          pw.Row(
                            children: [
                              pw.Expanded(child: pw.Text('Pph 21')),
                              pw.Text(rp(data.pph21)),
                            ],
                          ),
                          pw.Row(
                            children: [
                              pw.Expanded(child: pw.Text('Pot. Payroll')),
                              pw.Text(rp(data.adminBank)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Container(height: 1, color: PdfColors.black),
                pw.SizedBox(height: 16),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'JUMLAH PENDAPATAN',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(rp(data.totalBruto)),
                    pw.Text(
                      'JUMLAH POTONGAN',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(rp(data.totalPotongan)),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Row(
                  children: [
                    pw.Text(
                      'GAJI BERSIH                  : ',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 2,
                      ),
                      decoration: pw.BoxDecoration(border: pw.Border.all()),
                      child: pw.Text(
                        rp(data.totalBersih),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  '(${toTerbilangRupiah(data.totalBersih)})',
                  style: pw.TextStyle(
                    fontStyle: pw.FontStyle.italic,
                    fontSize: 10,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text('Diterbitkan Oleh'),
                        pw.SizedBox(height: 4),
                        if (data.qrcode != null && data.qrcode!.isNotEmpty)
                          pw.BarcodeWidget(
                            barcode: pw.Barcode.qrCode(),
                            data: data.qrcode!,
                            width: 60,
                            height: 60,
                          )
                        else
                          pw.Image(qrPlaceholderImage, width: 60, height: 60),
                        (data.penerbit != null &&
                                data.penerbit!.trim().isNotEmpty)
                            ? pw.Text(
                                data.penerbit!,
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              )
                            : pw.Text(
                                'Anggraini Pitaloka',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    final bytes = await pdf.save();
    // On web, open PDF in new tab using Blob URL (no filesystem)
    if (kIsWeb) {
      await openPdfOnWeb(bytes, filename: 'slip_gaji.pdf');
      return null;
    }

    // On non-web, save to temp directory and return path
    final path = await savePdfToTemp(bytes, filenamePrefix: 'slip_gaji');
    return path;
  }

  // Month/year picker helper (same as original)
  Future<DateTime?> showMonthYearPicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    // Use ValueNotifiers instead of local mutable variables to avoid setState
    // (actual values are held in the notifiers below)
    // int selectedYear = initialDate.year;
    // int selectedMonth = initialDate.month;
    final yearNotifier = ValueNotifier<int>(initialDate.year);
    final monthNotifier = ValueNotifier<int>(initialDate.month);

    return await showDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.12),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Pilih Bulan & Tahun',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<int>(
                      valueListenable: yearNotifier,
                      builder: (context, yearValue, _) {
                        return DropdownButton<int>(
                          value: yearValue,
                          items: [
                            for (
                              int y = firstDate.year;
                              y <= lastDate.year;
                              y++
                            )
                              DropdownMenuItem(
                                value: y,
                                child: Text(y.toString()),
                              ),
                          ],
                          onChanged: (y) {
                            if (y != null) yearNotifier.value = y;
                          },
                        );
                      },
                    ),
                    ValueListenableBuilder<int>(
                      valueListenable: monthNotifier,
                      builder: (context, monthValue, _) {
                        return DropdownButton<int>(
                          value: monthValue,
                          items: [
                            for (int m = 1; m <= 12; m++)
                              DropdownMenuItem(
                                value: m,
                                child: Text(m.toString().padLeft(2, '0')),
                              ),
                          ],
                          onChanged: (m) {
                            if (m != null) monthNotifier.value = m;
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Batal'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(
                            context,
                            DateTime(yearNotifier.value, monthNotifier.value),
                          ),
                          child: const Text('Pilih'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
