import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/loyalty_points_remote_datasource.dart';
import '../../data/models/loyalty_points_model.dart';
import 'loyalty_points_state.dart';

class LoyaltyPointsCubit extends Cubit<LoyaltyPointsState> {
  LoyaltyPointsCubit() : super(LoyaltyPointsInitial());

  static LoyaltyPointsCubit get(context) => BlocProvider.of<LoyaltyPointsCubit>(context);

  late final LoyaltyPointsRemoteDataSource _remote = LoyaltyPointsRemoteDataSource();

  int? _contactId;

  Future<void> load({required int contactId}) async {
    _contactId = contactId;
    if (isClosed) return;
    emit(LoyaltyPointsLoading());
    try {
      final res = await _remote.getPoints(contactId: contactId);
      if (isClosed) return;
      emit(LoyaltyPointsSuccess(res.data));
    } catch (e) {
      if (isClosed) return;
      emit(LoyaltyPointsError(e.toString()));
    }
  }

  Future<void> redeem({
    required int pointsToRedeem,
    required double orderTotal,
  }) async {
    final contactId = _contactId;
    final current = state is LoyaltyPointsSuccess
        ? (state as LoyaltyPointsSuccess).data
        : state is LoyaltyPointsRedeemLoading
            ? (state as LoyaltyPointsRedeemLoading).data
            : null;

    if (contactId == null) {
      if (isClosed) return;
      emit(LoyaltyPointsError('Missing contact_id'));
      return;
    }

    if (current != null) {
      if (isClosed) return;
      emit(LoyaltyPointsRedeemLoading(current));
    } else {
      if (isClosed) return;
      emit(LoyaltyPointsLoading());
    }

    try {
      final res = await _remote.redeem(
        contactId: contactId,
        pointsToRedeem: pointsToRedeem,
        orderTotal: orderTotal,
      );
      if (isClosed) return;
      emit(LoyaltyPointsSuccess(res.data));
    } catch (e) {
      if (isClosed) return;
      emit(LoyaltyPointsError(e.toString()));
    }
  }

  LoyaltyPointsData? get cachedData {
    final s = state;
    if (s is LoyaltyPointsSuccess) return s.data;
    if (s is LoyaltyPointsRedeemLoading) return s.data;
    return null;
  }
}
