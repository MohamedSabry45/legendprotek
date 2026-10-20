import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reservation_workshop/modules/spare_parts/data/datasources/products_remote_datasource.dart';

import 'products_state.dart';

class ProductsCubit extends Cubit<ProductsState> {
  ProductsCubit() : super(const ProductsInitial());

  late final ProductsRemoteDataSource _remote = ProductsRemoteDataSource();

  Future<void> load({
    int perPage = 30,
    int page = 1,
    int businessId = 1,
    int locationId = 1,
  }) async {
    if (isClosed) return;
    emit(const ProductsLoading());
    try {
      final products = await _remote.getProducts(
        perPage: perPage,
        page: page,
        businessId: businessId,
        locationId: locationId,
      );
      if (isClosed) return;
      emit(ProductsSuccess(products));
    } catch (e) {
      if (isClosed) return;
      emit(ProductsError(e.toString()));
    }
  }
}
