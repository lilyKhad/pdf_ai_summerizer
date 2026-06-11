import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_summerizer/core/router/app_router.dart';
import 'package:pdf_summerizer/features/auth/presentation/providers/auth_provider.dart';

/// Shown after sign-up when Supabase requires email confirmation.
/// The user stays here until they click the link in their inbox.
/// The authStateChanges stream in AuthNotifier will automatically
/// transition them to HomeScreen once confirmed.
class ConfirmEmailScreen extends ConsumerWidget {
  const ConfirmEmailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(authProvider).user?.email ?? 'your email';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.accentSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.mark_email_unread_outlined,
                    color: AppTheme.accent, size: 28),
              ),
              const SizedBox(height: 28),

              const Text(
                'Check your inbox',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15, height: 1.5),
                  children: [
                    const TextSpan(text: "We sent a confirmation link to "),
                    TextSpan(
                      text: email,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const TextSpan(
                        text: ". Open it to activate your account — this screen will update automatically."),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Tip card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.textSecondary, size: 18),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Don't see it? Check your spam folder. The link expires in 24 hours.",
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Back to login
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    ref.read(authProvider.notifier).signOut();
                  },
                  child: const Text(
                    'Use a different account',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
