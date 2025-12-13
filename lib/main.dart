import 'package:cobra_apps/pages/patroli_page.dart';
import 'package:cobra_apps/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cobra_apps/pages/account_setting_page.dart';
import 'package:cobra_apps/pages/login_page.dart';
import 'package:cobra_apps/pages/patrol_page.dart';
import 'package:cobra_apps/pages/dashboard_page.dart';
import 'package:cobra_apps/pages/slip_gaji_page.dart';
import 'package:cobra_apps/pages/absen_page.dart';
import 'package:cobra_apps/pages/kinerja_page.dart';
// import 'package:cobra_apps/providers/auth_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final env = const String.fromEnvironment('ENV', defaultValue: 'dev');
  await dotenv.load(fileName: '.env.$env');
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Cobra Apps',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        // Ensure text is white by default across the app
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        primaryTextTheme: ThemeData.dark().textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        // Make icons default to white where possible
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/absen': (context) => const AbsenPage(),
        '/patrol': (context) => const PatrolPage(),
        '/patroli': (context) => const PatroliPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/kinerja': (context) => const KinerjaPage(),
        '/account_setting': (context) => const AccountSettingPage(),
        '/slip_gaji': (context) => const SlipGajiPage(),
      },
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return authState.when(
      loading: () => Scaffold(
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset('assets/jpg/bg_blur.jpg', fit: BoxFit.cover),
            ),
            const SafeArea(child: Center(child: CircularProgressIndicator())),
          ],
        ),
      ),
      error: (error, stack) => const LoginPage(), // On error, show login
      data: (user) => user != null ? const DashboardPage() : const LoginPage(),
    );
  }
}
