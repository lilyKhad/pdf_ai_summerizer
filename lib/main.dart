import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pdf_summerizer/core/router/app_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('>>> 1. Loading .env...');
    await dotenv.load(fileName: '.env');
    print('>>> SUPABASE_URL: ${dotenv.env['SUPABASE_URL']}');
    print('>>> SUPABASE_ANON_KEY: ${dotenv.env['SUPABASE_ANON_KEY']}');
    print('>>> GROQ_API_KEY: ${dotenv.env['GROQ_API_KEY']}');

    print('>>> 2. Initializing Hive...');
    await Hive.initFlutter();

    print('>>> 3. Initializing Supabase...');
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );

    print('>>> 4. Running app...');
    runApp(
      const ProviderScope(
        child: AppRouter(),
      ),
    );
    print('>>> 5. App started successfully');

  } catch (e, stackTrace) {
    print('>>> ❌ CRASH AT: $e');
    print('>>> STACK: $stackTrace');
  }
}