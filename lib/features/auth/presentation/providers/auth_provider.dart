import 'package:flutter_riverpod/legacy.dart';
import 'package:pdf_summerizer/core/injection/injection.dart';
import 'package:pdf_summerizer/features/auth/domain/entity/user_entity.dart';
import 'package:pdf_summerizer/features/auth/domain/repo/user_repo.dart';

// ─────────────────────────────────────────
// STATE
// ─────────────────────────────────────────

enum AuthStatus {
  unknown,        // initial — still checking session
  unauthenticated,
  awaitingConfirmation, // signed up, email not yet confirmed
  authenticated,
}

class AuthState {
  final UserEntity? user;
  final AuthStatus status;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.status = AuthStatus.unknown,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    UserEntity? user,
    AuthStatus? status,
    bool? isLoading,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

// ─────────────────────────────────────────
// NOTIFIER
// ─────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final UserRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    final user = await _repository.getCurrentUser();
    state = state.copyWith(
      user: user,
      status: user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
      isLoading: false,
    );

    // Listen to Supabase auth changes (login, logout, session expiry)
    _repository.authStateChanges().listen((user) {
      if (user != null) {
        state = state.copyWith(
          user: user,
          status: AuthStatus.authenticated,
          clearError: true,
        );
      } else {
        // Only reset to unauthenticated if we are not in awaitingConfirmation
        if (state.status != AuthStatus.awaitingConfirmation) {
          state = state.copyWith(
            clearUser: true,
            status: AuthStatus.unauthenticated,
            clearError: true,
          );
        }
      }
    });
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.signIn(email, password);
      state = state.copyWith(
        user: user,
        status: AuthStatus.authenticated,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _parseError(e),
      );
    }
  }

  Future<void> signUp(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.signUp(email, password);
      // Supabase with email confirmation enabled returns a user whose session
      // is null until they click the link. Detect that here.
      if (user.emailConfirmedAt == null) {
        state = state.copyWith(
          user: user,
          status: AuthStatus.awaitingConfirmation,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          user: user,
          status: AuthStatus.authenticated,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _parseError(e),
      );
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.signOut();
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _parseError(e),
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String _parseError(Object e) {
    final message = e.toString();
    if (message.contains('Invalid login credentials')) {
      return 'Wrong email or password';
    } else if (message.contains('User already registered')) {
      return 'An account with this email already exists';
    } else if (message.contains('network')) {
      return 'No internet connection';
    }
    return 'Something went wrong, please try again';
  }
}

// ─────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(userRepositoryProvider));
});
