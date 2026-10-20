abstract class JobEstimatorDetailsState {}

class JobEstimatorDetailsInitial extends JobEstimatorDetailsState {}

class JobEstimatorDetailsLoading extends JobEstimatorDetailsState {}

class JobEstimatorDetailsSuccess extends JobEstimatorDetailsState {
  final Map<String, dynamic> data;
  JobEstimatorDetailsSuccess(this.data);
}

class JobEstimatorDetailsError extends JobEstimatorDetailsState {
  final String message;
  JobEstimatorDetailsError(this.message);
}
