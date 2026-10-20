import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reservation_workshop/core/network/local/cache_helper.dart';
import 'package:reservation_workshop/core/utils/strings/prefkeys.dart';
import 'package:reservation_workshop/modules/customer/domain/entities/customer_car.dart';

class CarSelectionState {
  final int? selectedCarId;
  final String? selectedCarLabel;
  final String? selectedCarLogo;
  final bool isLoading;
  final String? error;

  const CarSelectionState({
    this.selectedCarId,
    this.selectedCarLabel,
    this.selectedCarLogo,
    this.isLoading = false,
    this.error,
  });

  CarSelectionState copyWith({
    int? selectedCarId,
    String? selectedCarLabel,
    String? selectedCarLogo,
    bool? isLoading,
    String? error,
  }) {
    return CarSelectionState(
      selectedCarId: selectedCarId ?? this.selectedCarId,
      selectedCarLabel: selectedCarLabel ?? this.selectedCarLabel,
      selectedCarLogo: selectedCarLogo ?? this.selectedCarLogo,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class CarSelectionCubit extends Cubit<CarSelectionState> {
  CarSelectionCubit() : super(const CarSelectionState());

  Future<void> loadSelectedCar() async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true));
    try {
      final carId = await CacheHelper.getDataAsync<int>(key: PrefKeys.kSelectedCarId);
      final carLabel = await CacheHelper.getDataAsync<String>(key: PrefKeys.kSelectedCarLabel);
      final carLogo = await CacheHelper.getDataAsync<String>(key: PrefKeys.kSelectedCarLogo);
      if (isClosed) return;
      emit(state.copyWith(
        selectedCarId: carId,
        selectedCarLabel: carLabel,
        selectedCarLogo: carLogo,
        isLoading: false,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> selectCar(CustomerCar car) async {
    final label = _carLabel(car);
    final logo = (car.carLogo ?? '').trim();
    
    await CacheHelper.saveData(key: PrefKeys.kSelectedCarId, value: car.id);
    await CacheHelper.saveData(key: PrefKeys.kSelectedCarLabel, value: label);
    await CacheHelper.saveData(key: PrefKeys.kSelectedCarLogo, value: logo);
    
    if (isClosed) return;
    emit(state.copyWith(
      selectedCarId: car.id,
      selectedCarLabel: label,
      selectedCarLogo: logo,
    ));
  }

  String _carLabel(CustomerCar car) {
    final plate = (car.plateNumber ?? '').trim();
    return '${car.device} ${car.model} ${plate.isEmpty ? '' : plate}'.trim();
  }

  String getCarLabel(CustomerCar car) => _carLabel(car);
}
