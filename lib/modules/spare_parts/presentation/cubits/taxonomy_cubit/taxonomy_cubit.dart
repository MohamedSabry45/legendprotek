import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/datasources/taxonomy_remote_datasource.dart';
import 'taxonomy_state.dart';

class TaxonomyCubit extends Cubit<TaxonomyState> {
  TaxonomyCubit() : super(TaxonomyInitial());

  late final TaxonomyRemoteDataSource _remote = TaxonomyRemoteDataSource();

  Future<void> loadProductCategories({int page = 1}) async {
    if (isClosed) return;
    emit(TaxonomyLoading());
    try {
      final categories = await _remote.getProductCategories(page: page);
      if (isClosed) return;
      emit(TaxonomySuccess(categories));
    } catch (e) {
      if (isClosed) return;
      emit(TaxonomyError(e.toString()));
    }
  }
}
