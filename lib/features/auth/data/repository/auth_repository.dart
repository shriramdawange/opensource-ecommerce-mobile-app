import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/notifications/device_token_service.dart';
import '../models/auth_models.dart';

/// ArtBook authentication repository.
///
/// Supabase Auth is the identity provider. The CustomerLogin/Customer objects
/// are retained as an adapter for the existing Flutter authentication screens
/// while the remaining Bagisto-backed features are migrated incrementally.
class AuthRepository {
  final supabase.SupabaseClient client;

  AuthRepository({required this.client});

  supabase.Session? get currentSession => client.auth.currentSession;
  supabase.User? get currentUser => client.auth.currentUser;

  Future<CustomerLogin> login({
    required String email,
    required String password,
    String? deviceToken,
  }) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = response.user;
      final session = response.session;
      if (user == null || session == null) {
        throw const AuthException(
          'Sign-in did not return an active session. Please try again.',
        );
      }

      debugPrint('ArtBook Auth: signed in user ' + user.id);
      return CustomerLogin(
        id: user.id,
        token: session.accessToken,
        success: true,
        message: 'Signed in successfully.',
      );
    } on supabase.AuthException catch (error) {
      throw AuthException(error.message);
    } on AuthException {
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('ArtBook Auth login error: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw const AuthException(
        'Unable to sign in right now. Please try again.',
      );
    }
  }

  Future<Customer> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
    String? deviceToken,
    bool subscribeToNewsletter = true,
  }) async {
    if (password != confirmPassword) {
      throw const AuthException('Passwords do not match.');
    }

    final first = firstName.trim();
    final last = lastName.trim();
    final fullName = [first, last].where((part) => part.isNotEmpty).join(' ');

    try {
      final response = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName,
          'first_name': first,
          'last_name': last,
          'preferred_language': 'en-IN',
        },
      );

      final user = response.user;
      if (user == null) {
        throw const AuthException(
          'The account could not be created. Please try again.',
        );
      }

      // A null session is expected when email confirmation is enabled.
      // The database trigger creates the private profile row on auth.users INSERT.
      return Customer(
        id: user.id,
        firstName: first,
        lastName: last,
        email: user.email ?? email.trim(),
        name: fullName,
        token: response.session?.accessToken,
      );
    } on supabase.AuthException catch (error) {
      throw AuthException(error.message);
    } on AuthException {
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('ArtBook Auth registration error: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw const AuthException(
        'Unable to create your account right now. Please try again.',
      );
    }
  }

  Future<String> forgotPassword({required String email}) async {
    try {
      await client.auth.resetPasswordForEmail(email.trim());
      return 'Password reset instructions have been requested. Check your email.';
    } on supabase.AuthException catch (error) {
      throw AuthException(error.message);
    } catch (error, stackTrace) {
      debugPrint('ArtBook password reset error: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw const AuthException(
        'Unable to request a password reset right now.',
      );
    }
  }

  Future<bool> logout() async {
    try {
      await client.auth.signOut();
      return true;
    } on supabase.AuthException catch (error) {
      throw AuthException(error.message);
    } finally {
      await DeviceTokenService.clearDeviceToken();
    }
  }
}

/// User-facing authentication error used by the existing AuthBloc.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}
