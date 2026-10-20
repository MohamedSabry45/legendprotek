import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/about_us_remote_datasource.dart';
import 'about_us_state.dart';

class AboutUsCubit extends Cubit<AboutUsState> {
  AboutUsCubit() : super(AboutUsInitial());

  static AboutUsCubit get(context) => BlocProvider.of<AboutUsCubit>(context);

  late final AboutUsRemoteDataSource _remote = AboutUsRemoteDataSource();

  Future<void> load() async {
    if (isClosed) return;
    emit(AboutUsLoading());
    try {
      final data = await _remote.getAboutUs();
      if (isClosed) return;
      emit(AboutUsSuccess(data));
    } catch (e) {
      if (isClosed) return;
      emit(AboutUsError(e.toString()));
    }
  }
}
