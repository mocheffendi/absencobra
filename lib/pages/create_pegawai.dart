import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cobra_apps/widgets/gradient_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
// cyan_field not used here; fields are custom rendered

class CreatePegawaiPage extends StatefulWidget {
  const CreatePegawaiPage({super.key});

  @override
  State<CreatePegawaiPage> createState() => _CreatePegawaiPageState();
}

class _CreatePegawaiPageState extends State<CreatePegawaiPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _ctrl = {};
  File? _avatarFile;
  bool _isSubmitting = false;
  final Map<String, bool> _obscure = {};

  final List<String> _fields = [
    'id_pegawai',
    'nama_pegawai',
    'jk',
    'nip',
    'nik',
    'no_kk',
    'tmpt_lahir',
    'tgl_lahir',
    'pendidikan',
    'alamat',
    'id_golongan',
    'agama',
    'id_jabatan',
    'tmpt_tugas',
    'status',
    'id_divisi',
    'id_cabang',
    'username',
    'psw',
    'temp',
    'kode_jam',
    'nama_jabatan',
    'id_grup',
    'face_descriptor',
    'create_date',
    'telp',
    'telp_darurat',
    'email',
    'auth',
    'tmt',
    'nosprint',
    'tgl_joint',
    'tgl_akhir_pkwt',
    'no_rekening',
    'npwp',
    'bpjs_tk',
    'bpjs_kes',
    'jml_tanggungan',
    'status_kawin',
    'nama_ibu',
    'id_jadwal',
  ];

  @override
  void initState() {
    super.initState();
    for (final f in _fields) {
      _ctrl[f] = TextEditingController();
      _obscure[f] = f == 'psw';
    }
  }

  @override
  void dispose() {
    for (final c in _ctrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    // Keep simple: ask user to provide path via file picker if available.
    // Placeholder: not implementing file picker dependency here.
    // You can integrate image_picker later.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Image picker not implemented. Integrate image_picker to pick avatar.',
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      String? baseUrl = prefs.getString('primary_url');
      if (baseUrl == null || baseUrl.isEmpty) {
        baseUrl = 'https://absencobra.cbsguard.co.id';
      }
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }

      final uri = Uri.parse('$baseUrl/api/create_pegawai_api.php');
      final req = http.MultipartRequest('POST', uri);
      for (final entry in _ctrl.entries) {
        if (entry.value.text.isNotEmpty) {
          req.fields[entry.key] = entry.value.text;
        }
      }
      if (_avatarFile != null && await _avatarFile!.exists()) {
        req.files.add(
          await http.MultipartFile.fromPath('avatar', _avatarFile!.path),
        );
      }
      final streamed = await req.send();
      final resp = await http.Response.fromStream(streamed);
      if (resp.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pegawai created successfully')),
        );
        Navigator.of(context).pop();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${resp.statusCode}')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Exception: $e')));
    } finally {
      setState(() => _isSubmitting = false);
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('Create Pegawai'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset('assets/jpg/bg_blur.jpg', fit: BoxFit.cover),
          ),
          Positioned.fill(child: Container(color: Colors.black.withAlpha(38))),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: _avatarFile != null
                            ? FileImage(_avatarFile!)
                            : null,
                        child: _avatarFile == null
                            ? const Icon(Icons.camera_alt)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _fields.length,
                        itemBuilder: (context, idx) {
                          final key = _fields[idx];
                          final icon = _iconForKey(key);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: _buildLabeledField(
                              keyName: key,
                              controller: _ctrl[key]!,
                              icon: icon,
                              obscure: key == 'psw',
                            ),
                          );
                        },
                      ),
                    ),
                    // Use app's gradient pill button
                    SizedBox(
                      width: double.infinity,
                      child: gradientPillButton(
                        label: _isSubmitting ? 'Submitting...' : 'Submit',
                        onTap: _isSubmitting ? null : _submit,
                        icon: Icons.save,
                        height: 48,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForKey(String k) {
    final map = {
      'id_pegawai': Icons.badge,
      'nama_pegawai': Icons.person,
      'nip': Icons.credit_card,
      'alamat': Icons.home,
      'id_jabatan': Icons.work,
      'tmpt_tugas': Icons.location_city,
      'tgl_lahir': Icons.cake,
      'id_cabang': Icons.business,
      'tgl_joint': Icons.calendar_today,
      'email': Icons.email,
      'telp': Icons.phone,
      'username': Icons.account_circle,
    };
    return map[k] ?? Icons.input;
  }

  Widget _buildLabeledField({
    required String keyName,
    required TextEditingController controller,
    required IconData icon,
    bool obscure = false,
  }) {
    final label = keyName.replaceAll('_', ' ');
    final isPassword = obscure;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyanAccent, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.cyanAccent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        obscureText: isPassword
                            ? (_obscure[keyName] ?? true)
                            : false,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                        ),
                        validator: (v) {
                          if (keyName == 'nama_pegawai' ||
                              keyName == 'username') {
                            if (v == null || v.isEmpty) return 'Wajib diisi';
                          }
                          return null;
                        },
                      ),
                    ),
                    if (isPassword)
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Icon(
                          Icons.fingerprint,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (isPassword)
            IconButton(
              icon: Icon(
                (_obscure[keyName] ?? true)
                    ? Icons.visibility
                    : Icons.visibility_off,
                color: Colors.yellow,
                size: 20,
              ),
              onPressed: () => setState(
                () => _obscure[keyName] = !(_obscure[keyName] ?? true),
              ),
            ),
        ],
      ),
    );
  }
}
