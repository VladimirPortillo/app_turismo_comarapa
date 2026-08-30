import 'dart:convert';

import 'package:flutter/services.dart';

class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabasePublishableKey,
  });

  final String supabaseUrl;
  final String supabasePublishableKey;

  static Future<AppConfig> load() async {
    final source = await rootBundle.loadString('config/local.json');
    final values = jsonDecode(source) as Map<String, dynamic>;
    final config = AppConfig(
      supabaseUrl: values['SUPABASE_URL']?.toString().trim() ?? '',
      supabasePublishableKey:
          values['SUPABASE_PUBLISHABLE_KEY']?.toString().trim() ?? '',
    );

    if (!config.hasSupabaseConfig) {
      throw StateError(
        'config/local.json debe incluir SUPABASE_URL y '
        'SUPABASE_PUBLISHABLE_KEY.',
      );
    }

    return config;
  }

  bool get hasSupabaseConfig =>
      supabaseUrl.trim().isNotEmpty && supabasePublishableKey.trim().isNotEmpty;

  String get modeLabel => 'SUPABASE';
}
