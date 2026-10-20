import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reservation_workshop/core/network/local/cache_helper.dart';
import 'package:reservation_workshop/core/utils/strings/prefkeys.dart';

class GuestModeState {
  final bool isGuest;
  final bool isLoading;
  final String? error;

  const GuestModeState({
    this.isGuest = false,
    this.isLoading = false,
    this.error,
  });

  GuestModeState copyWith({
    bool? isGuest,
    bool? isLoading,
    String? error,
  }) {
    return GuestModeState(
      isGuest: isGuest ?? this.isGuest,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class GuestModeCubit extends Cubit<GuestModeState> {
  GuestModeCubit() : super(const GuestModeState());

  Future<void> loadGuestMode() async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true));
    try {
      final isGuest = await CacheHelper.getDataAsync<bool>(key: PrefKeys.kIsGuestMode) ?? false;
      if (isClosed) return;
      emit(state.copyWith(isGuest: isGuest, isLoading: false));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
