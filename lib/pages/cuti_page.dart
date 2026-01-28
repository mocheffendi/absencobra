import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:cobra_apps/widgets/gradient_button.dart';
import 'package:cobra_apps/widgets/cuti_data_card.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class CutiPage extends StatefulWidget {
  const CutiPage({super.key});

  @override
  State<CutiPage> createState() => _CutiPageState();
}

class _CutiPageState extends State<CutiPage> {
  // form controllers
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tglController = TextEditingController();
  final TextEditingController _tglSampaiController = TextEditingController();
  String? _selectedJenisCuti;
  final TextEditingController _ketController = TextEditingController();

  // uploaded file
  File? _lampiran;

  // UI state
  bool _loading = false;
  String? _message;

  // data list
  List<Map<String, dynamic>> _dataCuti = [];
  bool _loadingDataCuti = false;
  // date range info
  int? _totalDays;
  String? _dateRangeError;

  @override
  void initState() {
    super.initState();
    _fetchDataCuti();
  }

  // String _labelJenisCuti(dynamic val) {
  //   switch (val?.toString()) {
  //     case '1':
  //       return 'Cuti Tahunan';
  //     case '2':
  //       return 'Cuti Melahirkan';
  //     case '3':
  //       return 'Sakit';
  //     case '4':
  //       return 'Izin Karena Alasan Penting';
  //     case '5':
  //       return 'Izin Berduka';
  //     default:
  //       return val?.toString() ?? '-';
  //   }
  // }

  // String _labelStatus(dynamic st) {
  //   if (st == null) return '-';
  //   if (st.toString() == '1') return 'Disetujui';
  //   if (st.toString() == '0') return 'Ditolak';
  //   return st.toString();
  // }

  // Color _statusColor(dynamic st) {
  //   if (st == null) return Colors.grey;
  //   if (st.toString() == '1') return Colors.green;
  //   if (st.toString() == '0') return Colors.red;
  //   return Colors.grey;
  // }

  Future<void> _fetchDataCuti() async {
    setState(() {
      _loadingDataCuti = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      String? idPegawai;
      if (userJson != null) {
        try {
          final user = json.decode(userJson);
          idPegawai = user['id_pegawai']?.toString();
        } catch (_) {}
      }
      if (idPegawai == null) {
        setState(() {
          _loadingDataCuti = false;
        });
        return;
      }

      String? baseUrl = prefs.getString('primary_url');
      if (baseUrl == null || baseUrl.isEmpty) {
        baseUrl = 'https://absencobra.cbsguard.co.id';
      }
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }

      final url = Uri.parse(
        '$baseUrl/api/get_data_cuti.php?id_pegawai=$idPegawai',
      );
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data['success'] == true && data['data'] is List) {
          setState(() {
            _dataCuti = List<Map<String, dynamic>>.from(data['data']);
          });
        }
      }
    } catch (_) {
      // ignore errors silently for now
    }
    setState(() {
      _loadingDataCuti = false;
    });
  }

  Future<void> _pickLampiran() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _lampiran = File(picked.path);
      });
    }
  }

  DateTime? _parseDisplayDate(String s) {
    try {
      final parts = s.split('/');
      if (parts.length == 3) {
        final mm = int.parse(parts[0]);
        final dd = int.parse(parts[1]);
        final yyyy = int.parse(parts[2]);
        return DateTime(yyyy, mm, dd);
      }
    } catch (_) {}
    return null;
  }

  void _updateTotalDays() {
    final a = _parseDisplayDate(_tglController.text);
    final b = _parseDisplayDate(_tglSampaiController.text);
    if (a == null || b == null) {
      setState(() {
        _totalDays = null;
        _dateRangeError = null;
      });
      return;
    }
    final diff = b.difference(a).inDays;
    if (diff < 0) {
      setState(() {
        _totalDays = null;
        _dateRangeError = 'Tanggal selesai sebelum tanggal mulai';
      });
    } else {
      setState(() {
        _totalDays = diff + 1; // inclusive
        _dateRangeError = null;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _message = null;
    });
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    String? idPegawai;
    String? idCabang;
    if (userJson != null) {
      try {
        final user = json.decode(userJson);
        idPegawai = user['id_pegawai']?.toString();
        idCabang = user['id_cabang']?.toString();
      } catch (_) {}
    }
    if (idPegawai == null) {
      setState(() {
        _loading = false;
        _message = 'User tidak ditemukan';
      });
      return;
    }
    if (idCabang == null) {
      setState(() {
        _loading = false;
        _message = 'ID Cabang tidak ditemukan';
      });
      return;
    }

    String _displayToIso(String input) {
      try {
        final parts = input.split('/');
        if (parts.length == 3) {
          final mm = parts[0].padLeft(2, '0');
          final dd = parts[1].padLeft(2, '0');
          final yyyy = parts[2];
          return '$yyyy-$mm-$dd';
        }
      } catch (_) {}
      return input;
    }

    String? baseUrl = prefs.getString('primary_url');
    if (baseUrl == null || baseUrl.isEmpty) {
      baseUrl = 'https://absencobra.cbsguard.co.id';
    }
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }

    final uri = Uri.parse('$baseUrl/api/cutiapi.php');
    final request = http.MultipartRequest('POST', uri)
      ..fields['id_pegawai'] = idPegawai
      ..fields['tgl'] = _displayToIso(_tglController.text)
      ..fields['tgl_sampai'] = _displayToIso(_tglSampaiController.text)
      ..fields['jenis_cuti'] = _selectedJenisCuti ?? ''
      ..fields['ket'] = _ketController.text
      ..fields['id_cabang'] = idCabang;

    if (_lampiran != null) {
      request.files.add(
        await http.MultipartFile.fromPath('lampiran', _lampiran!.path),
      );
    }

    try {
      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);
      final data = json.decode(resp.body);
      setState(() {
        _loading = false;
        _message = data['message'] ?? 'Gagal';
      });
      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengajuan cuti berhasil!')),
        );
        _formKey.currentState?.reset();
        setState(() {
          _lampiran = null;
          _tglController.text = '';
          _tglSampaiController.text = '';
          _ketController.text = '';
          _selectedJenisCuti = null;
          _totalDays = null;
          _dateRangeError = null;
        });
        // refresh list
        await _fetchDataCuti();
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _message = 'Gagal mengirim data';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 50,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('Pengajuan Cuti/Izin'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset('assets/jpg/bg_blur.jpg', fit: BoxFit.cover),
          ),
          // reduced overlay so background remains visible through frosted elements
          Positioned.fill(
            child: Container(
              // subtle dark tint so content remains readable
              color: Colors.black.withValues(alpha: 0.15),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  FocusScope.of(
                                    context,
                                  ).requestFocus(FocusNode());
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                    builder: (context, child) => Theme(
                                      data: Theme.of(context).copyWith(
                                        dialogTheme: DialogThemeData(
                                          backgroundColor: Colors.black
                                              .withValues(alpha: 0.8),
                                        ),
                                      ),
                                      child: child!,
                                    ),
                                  );
                                  if (picked != null) {
                                    _tglController.text =
                                        '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
                                    _updateTotalDays();
                                  }
                                },
                                child: AbsorbPointer(
                                  child: TextFormField(
                                    controller: _tglController,
                                    decoration: InputDecoration(
                                      labelText: 'Mulai Izin/Cuti',
                                      hintText: 'MM/DD/YYYY',
                                      filled: true,
                                      fillColor: Colors.transparent,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 18,
                                          ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.white.withValues(
                                            alpha: 0.6,
                                          ),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary
                                              .withValues(alpha: 0.9),
                                          width: 1.8,
                                        ),
                                      ),
                                      suffixIcon: Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.calendar_today,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Wajib diisi'
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  FocusScope.of(
                                    context,
                                  ).requestFocus(FocusNode());
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                    builder: (context, child) => Theme(
                                      data: Theme.of(context).copyWith(
                                        dialogTheme: DialogThemeData(
                                          backgroundColor: Colors.black
                                              .withValues(alpha: 0.8),
                                        ),
                                      ),
                                      child: child!,
                                    ),
                                  );
                                  if (picked != null) {
                                    _tglSampaiController.text =
                                        '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
                                    _updateTotalDays();
                                  }
                                },
                                child: AbsorbPointer(
                                  child: TextFormField(
                                    controller: _tglSampaiController,
                                    decoration: InputDecoration(
                                      labelText: 'Selesai Izin/Cuti',
                                      hintText: 'MM/DD/YYYY',
                                      filled: true,
                                      fillColor: Colors.transparent,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 18,
                                          ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.white.withValues(
                                            alpha: 0.6,
                                          ),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary
                                              .withValues(alpha: 0.9),
                                          width: 1.8,
                                        ),
                                      ),
                                      suffixIcon: Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.calendar_today,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Wajib diisi'
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_dateRangeError != null) ...[
                          Text(
                            _dateRangeError!,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 8),
                        ] else if (_totalDays != null) ...[
                          Text(
                            'Lama Izin/Cuti: $_totalDays hari',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ] else
                          const SizedBox(height: 8),

                        DropdownButtonFormField<String>(
                          initialValue: _selectedJenisCuti,
                          decoration: InputDecoration(
                            labelText: 'Jenis Izin/Cuti',
                            // filled: true,
                            // fillColor: Colors.transparent,
                          ),
                          dropdownColor: Colors.black.withValues(alpha: 0.8),
                          items: const [
                            DropdownMenuItem(
                              value: '1',
                              child: Text('Cuti Tahunan'),
                            ),
                            DropdownMenuItem(
                              value: '2',
                              child: Text('Cuti Melahirkan'),
                            ),
                            DropdownMenuItem(value: '3', child: Text('Sakit')),
                            DropdownMenuItem(
                              value: '4',
                              child: Text('Izin Karena Alasan Penting'),
                            ),
                            DropdownMenuItem(
                              value: '5',
                              child: Text('Izin Berduka'),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedJenisCuti = v),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Wajib dipilih' : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _ketController,
                          decoration: const InputDecoration(
                            labelText: 'Keterangan',
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 8),
                        // ID Cabang diambil dari shared preferences, tidak perlu form
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: gradientPillButton(
                                label: 'Lampiran (foto/pdf)',
                                onTap: _pickLampiran,
                                icon: Icons.attach_file,
                                colors: const [
                                  Color(0xff2dd7a6),
                                  Color(0xff46a6ff),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: _lampiran != null
                                  ? Text(
                                      _lampiran!.path.split('/').last,
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_loading)
                          const Center(child: CircularProgressIndicator()),
                        if (_message != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _message!,
                            style: const TextStyle(color: Colors.green),
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: gradientPillButton(
                            label: _loading
                                ? 'Mengirim Data Izin/Cuti...'
                                : 'Ajukan Izin/Cuti',
                            onTap: _loading ? null : _submit,
                            icon: Icons.cloud_upload,
                            colors: const [
                              Color(0xff2dd7a6),
                              Color(0xff46a6ff),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          'Riwayat Pengajuan Izin/Cuti',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (_loadingDataCuti)
                          const Center(child: CircularProgressIndicator()),
                        if (!_loadingDataCuti && _dataCuti.isEmpty)
                          const Text('Belum ada data Izin/Cuti.'),
                        if (!_loadingDataCuti && _dataCuti.isNotEmpty)
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _dataCuti.length,
                            itemBuilder: (context, i) {
                              final d = _dataCuti[i];
                              return CutiDataCard(data: d);
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
