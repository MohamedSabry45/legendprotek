import '../entities/auth_session.dart';
import '../entities/check_phone_result.dart';

abstract class AuthRepository {
  Future<CheckPhoneResult> checkPhone({required String mobile});

  Future<AuthSession> register({
    required String name,
    required String mobile,
    required String password,
  });

  Future<AuthSession> login({
    required String mobile,
    required String password,
  });
}
