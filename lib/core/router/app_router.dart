import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_summerizer/features/auth/presentation/providers/auth_provider.dart';
import 'package:pdf_summerizer/features/auth/presentation/screens/login_screen.dart';
import 'package:pdf_summerizer/features/auth/presentation/screens/signup_screen.dart';
import 'package:pdf_summerizer/features/auth/presentation/screens/confirm_email_screen.dart';
import 'package:pdf_summerizer/features/flashcards/presentation/screens/flashcards_screen.dart';
import 'package:pdf_summerizer/features/pdf/presentation/screens/home_screen.dart';
import 'package:pdf_summerizer/features/pdf/presentation/screens/summary_screen.dart';

class AppRouter extends ConsumerWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return MaterialApp(
      title: 'PDF Summarizer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: _buildHome(auth),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/home': (_) => const HomeScreen(),
        '/confirm-email': (_) => const ConfirmEmailScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/summary') {
          final documentId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => SummaryScreen(documentId: documentId),
          );
        }
        if (settings.name == '/flashcards') {
          final documentId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => FlashcardScreen(documentId: documentId),
          );
        }
        return null;
      },
    );
  }

  Widget _buildHome(AuthState auth) {
    switch (auth.status) {
      case AuthStatus.unknown:
        return const _SplashScreen();
      case AuthStatus.awaitingConfirmation:
        return const ConfirmEmailScreen();
      case AuthStatus.authenticated:
        return const HomeScreen();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(
        child: CircularProgressIndicator(color: AppTheme.accent),
      ),
    );
  }
}

// ─────────────────────────────────────────
// THEME
// ─────────────────────────────────────────

class AppTheme {
  static const Color bg = Color(0xFF0F1117);
  static const Color surface = Color(0xFF1A1D27);
  static const Color surfaceAlt = Color(0xFF222638);
  static const Color accent = Color(0xFFFF6B35);
  static const Color accentSoft = Color(0x33FF6B35);
  static const Color textPrimary = Color(0xFFF0F0F5);
  static const Color textSecondary = Color(0xFF8B8FA8);
  static const Color border = Color(0xFF2C2F42);
  static const Color success = Color(0xFF3DD68C);
  static const Color error = Color(0xFFFF4D6A);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          surface: surface,
          error: error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          iconTheme: IconThemeData(color: textSecondary),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceAlt,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: accent, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: error),
          ),
          labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
          hintStyle: const TextStyle(color: textSecondary),
          prefixIconColor: textSecondary,
          suffixIconColor: textSecondary,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: accent),
        ),
        cardTheme: CardThemeData(
  color: surface,
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
    side: const BorderSide(color: border),
  ),
),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: surfaceAlt,
          contentTextStyle: const TextStyle(color: textPrimary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          behavior: SnackBarBehavior.floating,
        ),
      );
}