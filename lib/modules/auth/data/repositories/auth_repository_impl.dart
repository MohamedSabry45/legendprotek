import 'package:reservation_workshop/modules/auth/domain/entities/auth_session.dart';
import 'package:reservation_workshop/modules/auth/domain/entities/check_phone_result.dart';
import 'package:reservation_workshop/modules/auth/domain/repositories/auth_repository.dart';

import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;

  const AuthRepositoryImpl(this._remote);

  @override
  Future<CheckPhoneResult> checkPhone({required String mobile}) {
    return _remote.checkPhone(mobile: mobile);
  }

  @override
  Future<AuthSession> register({
    required String name,
    required String mobile,
    required String password,
  }) {
    return _remote.register(
      name: name,
      mobile: mobile,
      password: password,
    );
  }

  @override
  Future<AuthSession> login({
    required String mobile,
    required String password,
  }) {
    return _remote.login(mobile: mobile, password: password);
  }
}
