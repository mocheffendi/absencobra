import 'package:flutter_dotenv/flutter_dotenv.dart';

String get kBaseApiUrl => dotenv.env['BASE_API_URL'] ?? '';
String get kBaseUrl => dotenv.env['BASE_URL'] ?? '';
String get kPatrolUrl => dotenv.env['PATROL_URL'] ?? '';

// const String kBaseApiUrl = 'https://absencobra.cbsguard.co.id/api';
// const String kBaseApiUrl = 'http://10.100.0.114/absencobra/api';
