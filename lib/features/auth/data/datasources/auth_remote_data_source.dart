import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/app_logger.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signInWithEmailAndPassword(String email, String password);
  Future<UserModel> signUpWithEmailAndPassword(String email, String password);
  Future<UserModel> signInAnonymously();
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabaseClient;
  final AppLogger logger;

  AuthRemoteDataSourceImpl(this.supabaseClient, this.logger);

  @override
  Future<UserModel> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    logger.i('Signing in with email: $email');
    try {
      final response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) {
        logger.e('Sign in failed: User is null');
        throw ServerException();
      }
      logger.i('Sign in successful: ${response.user!.id}');
      return _getUserWithProfile(response.user!);
    } catch (e) {
      logger.e('Sign in error', e);
      throw ServerException();
    }
  }

  @override
  Future<UserModel> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    logger.i('Signing up with email: $email');
    try {
      final response = await supabaseClient.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user == null) {
        logger.e('Sign up failed: User is null');
        throw ServerException();
      }
      logger.i('Sign up successful: ${response.user!.id}');
      // For sign up, profile might not exist yet or triggers handle it.
      // We can try to fetch it or return basic user.
      // Triggers usually run immediately, so we can try fetching.
      return _getUserWithProfile(response.user!);
    } catch (e) {
      logger.e('Sign up error', e);
      throw ServerException();
    }
  }

  @override
  Future<UserModel> signInAnonymously() async {
    logger.i('Signing in anonymously');
    try {
      final response = await supabaseClient.auth.signInAnonymously();
      if (response.user == null) {
        logger.e('Anonymous sign in failed: User is null');
        throw ServerException();
      }
      logger.i('Anonymous sign in successful: ${response.user!.id}');
      return _getUserWithProfile(response.user!);
    } on AuthException catch (e) {
      logger.e(
        'Anonymous sign in AuthException: ${e.message}, StatusCode: ${e.statusCode}',
      );
      throw ServerException();
    } catch (e) {
      logger.e('Anonymous sign in error', e);
      throw ServerException();
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await supabaseClient.auth.signOut();
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = supabaseClient.auth.currentUser;
      if (user != null) {
        return _getUserWithProfile(user);
      }
      return null;
    } catch (e) {
      throw ServerException();
    }
  }

  Future<UserModel> _getUserWithProfile(User user) async {
    try {
      final data = await supabaseClient
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      return UserModel.fromSupabase(user, profileData: data);
    } catch (e) {
      logger.e('Error fetching profile for user ${user.id}', e);
      // Return user without profile data if fetch fails
      return UserModel.fromSupabase(user);
    }
  }
}
