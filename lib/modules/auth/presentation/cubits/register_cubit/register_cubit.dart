import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reservation_workshop/constants/app_constants.dart';
import 'package:reservation_workshop/core/network/local/cache_helper.dart';
import 'package:reservation_workshop/core/utils/strings/prefkeys.dart';

import '../../../data/datasources/auth_remote_datasource.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../domain/usecases/register_usecase.dart';
import 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit() : super(RegisterInitial());

  static RegisterCubit get(context) => BlocProvider.of<RegisterCubit>(context);

  late final RegisterUsecase _usecase = RegisterUsecase(
    AuthRepositoryImpl(AuthRemoteDataSource()),
  );

  Future<void> register({
    required String name,
    required String mobile,
    required String password,
  }) async {
    emit(RegisterLoading());

    final n = name.trim();
    final m = mobile.trim();
    final p = password.trim();

    if (n.isEmpty || m.isEmpty || p.isEmpty) {
      emit(RegisterError('Required'));
      return;
    }

    try {
      final session = await _usecase.call(
        name: n,
        mobile: m,
        password: p,
      );

      if (session.token.trim().isNotEmpty) {
        AppConstants.token = session.token;
        await CacheHelper.saveData(key: PrefKeys.kAccessToken, value: session.token);
      }

      emit(RegisterSuccess(session));
    } catch (e) {
      emit(RegisterError(e.toString()));
    }
  }
}
