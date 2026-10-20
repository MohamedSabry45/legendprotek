import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/vehicle.dart';
import '../../data/datasources/vehicles_remote_datasource.dart';
import 'vehicles_state.dart';

class VehiclesCubit extends Cubit<VehiclesState> {
  VehiclesCubit() : super(VehiclesInitial());

  static VehiclesCubit get(BuildContext context) => BlocProvider.of<VehiclesCubit>(context);

  late final VehiclesRemoteDataSource _remote = VehiclesRemoteDataSource();

  int _page = 1;
  int _lastPage = 1;
  final List<Vehicle> _items = <Vehicle>[];

  // Filter parameters
  int? _brandId;
  int? _modelId;
  String? _cityName;
  String? _colorName;
  String? _bodyTypeName;
  String? _yearRangeName;
  String? _priceRangeName;

  bool get _hasMore => _page < _lastPage;

  Future<void> loadFirst() async {
    if (isClosed) return;
    emit(VehiclesLoading());
    try {
      _page = 1;
      print('Loading vehicles with filters: brandId=$_brandId, modelId=$_modelId, cityName=$_cityName, colorName=$_colorName, bodyTypeName=$_bodyTypeName, yearRangeName=$_yearRangeName, priceRangeName=$_priceRangeName');
      final result = await _remote.getVehicles(
        page: _page,
        brandId: _brandId,
        modelId: _modelId,
        cityName: _cityName,
        colorName: _colorName,
        bodyTypeName: _bodyTypeName,
        yearRangeName: _yearRangeName,
        priceRangeName: _priceRangeName,
      );
      print('Loaded ${result.vehicles.length} vehicles');
      _lastPage = result.lastPage;
      _items
        ..clear()
        ..addAll(result.vehicles);

      if (isClosed) return;
      emit(
        VehiclesSuccess(
          vehicles: List<Vehicle>.unmodifiable(_items),
          isRefreshing: false,
          isLoadingMore: false,
          hasMore: _hasMore,
        ),
      );
    } catch (e) {
      print('Error loading vehicles: $e');
      if (isClosed) return;
      emit(VehiclesError(e.toString()));
    }
  }

  Future<String> createSellerVehicle({required Map<String, dynamic> body}) async {
    final msg = await _remote.createSellerVehicle(body: body);
    await refresh();
    return msg;
  }

  Future<void> refresh() async {
    final current = state;
    if (current is VehiclesSuccess) {
      if (isClosed) return;
      emit(
        VehiclesSuccess(
          vehicles: current.vehicles,
          isRefreshing: true,
          isLoadingMore: current.isLoadingMore,
          hasMore: current.hasMore,
        ),
      );
    }

    try {
      _page = 1;
      final result = await _remote.getVehicles(
        page: _page,
        brandId: _brandId,
        modelId: _modelId,
        cityName: _cityName,
        colorName: _colorName,
        bodyTypeName: _bodyTypeName,
        yearRangeName: _yearRangeName,
        priceRangeName: _priceRangeName,
      );
      _lastPage = result.lastPage;
      _items
        ..clear()
        ..addAll(result.vehicles);

      if (isClosed) return;
      emit(
        VehiclesSuccess(
          vehicles: List<Vehicle>.unmodifiable(_items),
          isRefreshing: false,
          isLoadingMore: false,
          hasMore: _hasMore,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(VehiclesError(e.toString()));
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! VehiclesSuccess) return;
    if (current.isLoadingMore) return;
    if (!_hasMore) return;

    if (isClosed) return;
    emit(
      VehiclesSuccess(
        vehicles: current.vehicles,
        isRefreshing: current.isRefreshing,
        isLoadingMore: true,
        hasMore: current.hasMore,
      ),
    );

    try {
      final nextPage = _page + 1;
      final result = await _remote.getVehicles(
        page: nextPage,
        brandId: _brandId,
        modelId: _modelId,
      );
      _page = nextPage;
      _lastPage = result.lastPage;
      _items.addAll(result.vehicles);

      if (isClosed) return;
      emit(
        VehiclesSuccess(
          vehicles: List<Vehicle>.unmodifiable(_items),
          isRefreshing: false,
          isLoadingMore: false,
          hasMore: _hasMore,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        VehiclesSuccess(
          vehicles: current.vehicles,
          isRefreshing: current.isRefreshing,
          isLoadingMore: false,
          hasMore: current.hasMore,
        ),
      );
    }
  }

  void applyFilters({
    int? brandId,
    int? modelId,
    String? cityName,
    String? colorName,
    String? bodyTypeName,
    String? yearRangeName,
    String? priceRangeName,
  }) {
    _brandId = brandId;
    _modelId = modelId;
    _cityName = cityName;
    _colorName = colorName;
    _bodyTypeName = bodyTypeName;
    _yearRangeName = yearRangeName;
    _priceRangeName = priceRangeName;
    loadFirst(); // Reload with new filters
  }
}
