import 'dart:convert';
import 'package:cobra_apps/services/applog.dart';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UrlConfig {
  final int version;
  final String lastUpdate;
  String primaryUrl;
  List<String> fallbackUrls;
  final int timeoutMs;
  final int cacheTtlSeconds;
  final bool forceHttps;

  UrlConfig({
    required this.version,
    required this.lastUpdate,
    required this.primaryUrl,
    required this.fallbackUrls,
    required this.timeoutMs,
    required this.cacheTtlSeconds,
    required this.forceHttps,
  });

  factory UrlConfig.fromMap(Map<String, dynamic> m) {
    return UrlConfig(
      version: (m['version'] ?? 1) as int,
      lastUpdate: (m['last_update'] ?? '') as String,
      primaryUrl: (m['primary_url'] ?? '') as String,
      fallbackUrls: (m['fallback_urls'] is List)
          ? List<String>.from(m['fallback_urls'])
          : <String>[],
      timeoutMs: (m['timeout_ms'] ?? 5000) as int,
      cacheTtlSeconds: (m['cache_ttl_seconds'] ?? 86400) as int,
      forceHttps: (m['force_https'] ?? true) as bool,
    );
  }

  Map<String, dynamic> toMap() => {
    'version': version,
    'last_update': lastUpdate,
    'primary_url': primaryUrl,
    'fallback_urls': fallbackUrls,
    'timeout_ms': timeoutMs,
    'cache_ttl_seconds': cacheTtlSeconds,
    'force_https': forceHttps,
  };
}

class UrlConfigService {
  static const _prefsKey = 'app_url_config_v1';
  static const _remoteConfigUrl =
      'https://weathered-limit-c0a8.rohman-arif-it.workers.dev/config.json';

  /// Returns an active base URL (primary or one of fallbacks) following this flow:
  /// 1. Load config from SharedPreferences
  /// 2. If primary is reachable -> return it
  /// 3. Otherwise fetch remote config.json, test urls, persist, and return
  /// 4. Throws an Exception if no reachable URL found
  static Future<String> resolveBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();

    UrlConfig? cfg;
    final local = prefs.getString(_prefsKey);
    if (local != null) {
      try {
        final m = json.decode(local) as Map<String, dynamic>;
        cfg = UrlConfig.fromMap(m);
        LogService.log(
          level: 'INFO',
          source: 'UrlConfigService',
          action: 'load_prefs',
          message:
              'UrlConfigService: Loaded config from prefs: ${cfg.primaryUrl}',
        );
        // Mirror primary and fallback values to top-level prefs for easy inspection
        try {
          await saveConfig(cfg);
        } catch (_) {}
      } catch (e) {
        LogService.log(
          level: 'ERROR',
          source: 'UrlConfigService',
          action: 'parse_local_config',
          message: 'UrlConfigService: Failed parsing local config: $e',
        );
        cfg = null;
      }
    }

    // If we have local config, check primary and fallbacks
    if (cfg != null) {
      final selected = await _selectActiveUrl(cfg);
      if (selected != null) return selected;
      // fallthrough: try fetching remote
    }

    // Fetch remote config
    try {
      final remote = await _fetchRemoteConfig();
      if (remote != null) {
        // test and pick
        final picked = await _selectActiveUrl(remote);
        if (picked != null) {
          // save remote config to prefs (and mirror primary/fallback)
          await saveConfig(remote);
          LogService.log(
            level: 'INFO',
            source: 'UrlConfigService',
            action: 'save_remote_config',
            message: 'UrlConfigService: Saved remote config to prefs: $picked',
          );
          return picked;
        }
      }
    } catch (e) {
      LogService.log(
        level: 'ERROR',
        source: 'UrlConfigService',
        action: 'fetch_remote_config',
        message: 'UrlConfigService: Error fetching remote config: $e',
      );
    }

    // As a last resort, try primary from local even if it failed (to avoid crash)
    if (cfg != null && cfg.primaryUrl.isNotEmpty) return cfg.primaryUrl;

    throw Exception('No reachable base URL found');
  }

  static Future<UrlConfig?> _fetchRemoteConfig() async {
    try {
      final resp = await http
          .get(Uri.parse(_remoteConfigUrl))
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        final m = json.decode(resp.body) as Map<String, dynamic>;
        final cfg = UrlConfig.fromMap(m);
        LogService.log(
          level: 'INFO',
          source: 'UrlConfigService',
          action: 'fetched_remote',
          message:
              'UrlConfigService: Fetched remote config primary=${cfg.primaryUrl}',
        );
        return cfg;
      } else {
        LogService.log(
          level: 'WARNING',
          source: 'UrlConfigService',
          action: 'remote_config_status',
          message:
              'UrlConfigService: Remote config returned ${resp.statusCode}',
        );
      }
    } catch (e) {
      LogService.log(
        level: 'ERROR',
        source: 'UrlConfigService',
        action: 'fetch_remote_error',
        message: 'UrlConfigService: fetchRemote error: $e',
      );
    }
    return null;
  }

  static Future<String?> _selectActiveUrl(UrlConfig cfg) async {
    final timeout = Duration(milliseconds: cfg.timeoutMs);

    Future<bool> checkUrl(String url) async {
      try {
        var uri = Uri.parse(url);
        if (cfg.forceHttps && uri.scheme != 'https') {
          uri = uri.replace(scheme: 'https');
        }
        // try a light GET to the health endpoint (use /api/get_tb_absen.php if exists)
        final testUri = uri.replace(path: '/api/get_tb_absen.php');
        final r = await http.get(testUri).timeout(timeout);
        return r.statusCode == 200;
      } catch (e) {
        LogService.log(
          level: 'WARNING',
          source: 'UrlConfigService',
          action: 'check_url',
          message: 'UrlConfigService: checkUrl failed for $url -> $e',
        );
        return false;
      }
    }

    // Check primary first
    if (cfg.primaryUrl.isNotEmpty) {
      if (await checkUrl(cfg.primaryUrl)) return cfg.primaryUrl;
    }

    for (final fb in cfg.fallbackUrls) {
      if (fb.isEmpty) continue;
      if (await checkUrl(fb)) return fb;
    }

    return null;
  }

  /// Optional helper to save/update config in prefs
  static Future<void> saveConfig(UrlConfig cfg) async {
    final prefs = await SharedPreferences.getInstance();
    // Persist full config under the internal prefs key
    await prefs.setString(_prefsKey, json.encode(cfg.toMap()));
    // Also mirror values to top-level keys for UI/debug convenience
    try {
      await prefs.setString('primaryUrl', cfg.primaryUrl);
      // Use setStringList when possible; fallback to JSON string
      try {
        await prefs.setStringList('fallbackUrls', cfg.fallbackUrls);
      } catch (_) {
        await prefs.setString('fallbackUrls', json.encode(cfg.fallbackUrls));
      }
    } catch (e) {
      LogService.log(
        level: 'WARNING',
        source: 'UrlConfigService',
        action: 'mirror_prefs_failed',
        message:
            'UrlConfigService: Failed mirroring primary/fallback to prefs: $e',
      );
    }
  }
}
