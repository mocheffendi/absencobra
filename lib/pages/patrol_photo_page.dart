import 'package:absencobra/utility/settings.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../user.dart';

class PatrolPhotoPage extends StatefulWidget {
  final String qrId;
  const PatrolPhotoPage({super.key, required this.qrId});

  @override
  State<PatrolPhotoPage> createState() => _PatrolPhotoPageState();
}

class _PatrolPhotoPageState extends State<PatrolPhotoPage> {
  final TextEditingController _keteranganController = TextEditingController();
  File? _imageFile;
  bool _loading = false;
  String _message = '';

  String? namaTmpt;
  bool loadingNama = true;
  bool namaValid = false;

  @override
  void initState() {
    super.initState();
    fetchNamaTmpt();
  }

  Future<void> fetchNamaTmpt() async {
    setState(() {
      loadingNama = true;
      namaValid = false;
      namaTmpt = null;
      _message = '';
    });
    try {
      final response = await http.get(
        Uri.parse('$kBaseApiUrl/cek_lokasi.php?qr_id=${widget.qrId}'),
      );
      final data = json.decode(response.body);
      if (data['success'] == true) {
        setState(() {
          namaTmpt = data['nama_tmpt'];
          namaValid = true;
          loadingNama = false;
        });
      } else {
        setState(() {
          namaTmpt = data['message'] ?? 'Lokasi tidak ditemukan';
          namaValid = false;
          loadingNama = false;
        });
      }
    } catch (e) {
      setState(() {
        namaTmpt = 'Gagal cek lokasi';
        namaValid = false;
        loadingNama = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _submit() async {
    if (_keteranganController.text.isEmpty || _imageFile == null) {
      setState(() {
        _message = "Keterangan dan foto wajib diisi";
      });
      return;
    }

    setState(() {
      _loading = true;
      _message = '';
    });

    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    User? user;
    if (userJson != null) {
      try {
        user = User.fromJson(json.decode(userJson));
      } catch (e) {
        setState(() {
          _message = "Data user tidak valid";
        });
        return;
      }
    }

    if (user == null || user.token == null || user.token!.isEmpty) {
      setState(() {
        _message = "Token autentikasi tidak tersedia";
      });
      return;
    }

    final token = user.token!;

    var uri = Uri.parse('$kBaseApiUrl/patrol_api2.php');
    var request = http.MultipartRequest('POST', uri)
      ..fields['qr_id'] = widget.qrId
      ..fields['keterangan'] = _keteranganController.text
      ..headers['Authorization'] = 'Bearer $token';

    request.files.add(
      await http.MultipartFile.fromPath('foto1', _imageFile!.path),
    );

    var response = await request.send();
    var respStr = await response.stream.bytesToString();
    var data = json.decode(respStr);

    setState(() {
      _loading = false;
      _message = data['message'] ?? 'Terjadi kesalahan';
    });

    if (data['success'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Patroli berhasil!")));
      Navigator.pop(context, true); // agar dashboard refresh
    }
  }

  @override
  void dispose() {
    _keteranganController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Foto & Submit Patroli')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Text(
            //   'QR ID: ${widget.qrId}',
            //   style: TextStyle(fontWeight: FontWeight.bold),
            // ),
            loadingNama
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Cek lokasi...'),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      namaTmpt != null
                          ? 'Lokasi: $namaTmpt'
                          : 'Lokasi tidak ditemukan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: namaValid ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
            TextField(
              controller: _keteranganController,
              decoration: InputDecoration(labelText: 'Keterangan'),
            ),
            SizedBox(height: 16),
            _imageFile == null
                ? Text('Belum ada foto')
                : Image.file(_imageFile!, height: 200),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.camera_alt),
              label: Text('Ambil Foto'),
            ),
            SizedBox(height: 16),
            _loading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: namaValid ? _submit : null,
                    child: Text('Kirim Patroli'),
                  ),
            SizedBox(height: 16),
            Text(_message, style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
