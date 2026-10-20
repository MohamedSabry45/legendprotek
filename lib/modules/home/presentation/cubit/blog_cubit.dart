import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reservation_workshop/core/network/local/cache_helper.dart';
import 'package:reservation_workshop/core/utils/strings/prefkeys.dart';

import '../../data/datasources/blog_remote_datasource.dart';
import 'blog_state.dart';

class BlogCubit extends Cubit<BlogState> {
  BlogCubit() : super(BlogInitial());

  static BlogCubit get(context) => BlocProvider.of<BlogCubit>(context);

  late final BlogRemoteDataSource _remote = BlogRemoteDataSource();

  Future<bool> _isGuestMode() async {
    return await CacheHelper.getDataAsync<bool>(key: PrefKeys.kIsGuestMode) ?? false;
  }

  Future<void> loadFirst({String? localeCode}) async {
    if (isClosed) return;
    emit(BlogLoading());
    try {
      if (await _isGuestMode()) {
        if (isClosed) return;
        emit(BlogSuccess(const []));
        return;
      }
      final posts = await _remote.getBlogPosts(localeCode: localeCode);
      if (isClosed) return;
      emit(BlogSuccess(posts));
    } catch (e) {
      if (isClosed) return;
      emit(BlogError(e.toString()));
    }
  }
}
