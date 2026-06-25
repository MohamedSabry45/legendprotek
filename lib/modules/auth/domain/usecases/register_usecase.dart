import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class RegisterUsecase {
  final AuthRepository _repo;

  const RegisterUsecase(this._repo);

  Future<AuthSession> call({
    required String name,
    required String mobile,
    required String password,
  }) {
    return _repo.register(
      name: name,
      mobile: mobile,
      password: password,
    );
  }
}
