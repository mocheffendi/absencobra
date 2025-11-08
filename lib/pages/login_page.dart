import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cobra_apps/widgets/cyan_field.dart';
import 'package:cobra_apps/widgets/hexagon_button.dart';
import 'package:cobra_apps/providers/auth_provider.dart';
import 'package:cobra_apps/providers/user_provider.dart';
import 'package:cobra_apps/providers/avatar_provider.dart';
import 'package:cobra_apps/utility/avatar_utils.dart';

// Transient UI provider for login page (Notifier-based to avoid StateProvider import issues)
class LoginObscureNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() => state = !state;
}

final loginObscureProvider = NotifierProvider<LoginObscureNotifier, bool>(
  () => LoginObscureNotifier(),
);

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // (moved provider to top-level `loginObscureProvider`)

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final form = {
      'username': _emailController.text.trim(),
      'password': _passwordController.text.trim(),
    };
    final user = await ref.read(authProvider.notifier).login(form);
    if (user != null && mounted) {
      // Update user provider with the logged-in user
      ref.read(userProvider.notifier).setUser(user);
      // Download and cache avatar locally via shared utility, then refresh provider
      try {
        await downloadAndSaveAvatar(user.avatar, user.id_pegawai);
        await ref.read(avatarProvider.notifier).loadAvatarFromPrefs();
      } catch (_) {
        // ignore avatar caching errors
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login gagal')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;
    final error = authState.error;

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 50,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
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
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    Image.asset('assets/png/logo.png', height: 165),
                    const SizedBox(height: 12),
                    const Text(
                      'SYUKRI BHAKTI ABADI',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (error != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade700.withAlpha(30),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.red.shade700.withAlpha(45),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red.shade300,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        error.toString(),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            buildCyanField(
                              controller: _emailController,
                              label: 'USERNAME',
                              prefix: Icons.person,
                            ),
                            const SizedBox(height: 12),
                            buildCyanField(
                              controller: _passwordController,
                              label: 'PASSWORD',
                              prefix: Icons.lock,
                              obscure: ref.watch(loginObscureProvider),
                              toggle: true,
                              onToggle: () => ref
                                  .read(loginObscureProvider.notifier)
                                  .toggle(),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 60,
                              child: Center(
                                child: HexagonButton(
                                  width: 200,
                                  height: 60,
                                  borderColor: Colors.cyanAccent.shade400,
                                  glowColor: Colors.cyanAccent.withAlpha(66),
                                  backgroundColor: Colors.black87,
                                  onPressed: isLoading ? null : _handleLogin,
                                  child: isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            valueColor: AlwaysStoppedAnimation(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : const Text(
                                          'LOGIN',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
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
}
