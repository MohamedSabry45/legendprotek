import '../../../data/models/job_order_details_response_model.dart';
import '../../../data/models/job_order_status_model.dart';

abstract class JobOrderDetailsState {}

class JobOrderDetailsInitial extends JobOrderDetailsState {}

class JobOrderDetailsLoading extends JobOrderDetailsState {}

class JobOrderDetailsSuccess extends JobOrderDetailsState {
  final JobOrderDetailsResponseModel details;
  final List<JobOrderStatusModel> statuses;

  JobOrderDetailsSuccess({required this.details, required this.statuses});
}

class JobOrderDetailsError extends JobOrderDetailsState {
  final String message;

  JobOrderDetailsError(this.message);
}
