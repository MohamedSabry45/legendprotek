class ApiEndpoints {
  static const String checkPhone = '/contact/check/phone';
  static const String checkPhoneJobOrder = '/contact/check/phone/joborder';
  static const String contactStatus = '/contact/status';
  static const String saveProduct = '/contact/saveProduct';
  static const String uploadImage = '/contact/upload-image';
  static const String register = '/register';
  static const String login = '/contact/login';
  static const String signupEmail = '/contact/signup-email';
  static const String loginEmail = '/contact/login-email';

  static String updateContactBasicInfo({required int id}) {
    return '/connector/api/contactapi/$id/basic-info';
  }

  static const String socialCustomerLogin = '/connector/api/auth/social-customer-login';
  static const String updateSocialMobile = '/connector/api/auth/update-social-mobile';

  static const String sendPhoneVerificationOtp = '/connector/api/auth/send-phone-verification-otp';
  static const String verifyPhoneAndSetMobile = '/connector/api/auth/verify-phone-and-set-mobile';

  static const String sendOwnershipOtp = '/connector/api/auth/send-ownership-otp';
  static const String verifyAndMergeAccounts = '/connector/api/auth/verify-and-merge-accounts';

  static const String forgotPassword = '/contact/forgot-password';
  static const String resetPassword = '/contact/reset-password';

  static const String softDeleteAccount = '/connector/api/contact/soft-delete';

  static const String restoreDeletedAccount = '/connector/api/auth/restore-deleted-account';

  static const String customerInfo = '/connector/api/Info/customer';
  static const String branches = '/connector/api/Branshes';

  static const String aboutUs = '/connector/api/about-us';

  static const String brands = '/connector/api/brands';

  static const String carMarketVehicles = '/connector/api/carmarket/vehicles';

  static const String carMarketSellerVehicles = '/connector/api/carmarket/seller/vehicles';

  static String carMarketVehicleDetails({required int id}) {
    return '/connector/api/carmarket/vehicles/$id';
  }

  static String vehicleInquiry({required int vehicleId}) {
    return '/connector/api/carmarket/vehicles/$vehicleId/inquiry';
  }

  static String carMarketFilters({
    required String type,
    String? search,
    int? brandCategoryId,
    int perPage = 15,
    int page = 1,
  }) {
    final params = <String, String>{
      'type': type,
      'per_page': perPage.toString(),
      'page': page.toString(),
    };
    
    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }
    
    if (brandCategoryId != null) {
      params['brand_category_id'] = brandCategoryId.toString();
    }
    
    final queryString = params.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    
    return '/connector/api/carmarket/filters?$queryString';
  }

  static String models({required int brandId}) {
    return '/connector/api/models/$brandId';
  }

  static String services({required int locationId}) {
    return '/connector/api/services?location_id=$locationId';
  }

  static const String customerJobOrders = '/connector/api/customer/joborder';
  static const String customerBookings = '/connector/api/customer/booking';

  static const String addBooking = '/connector/api/add/booking';

  static const String addCar = '/connector/api/add/car';

  // Job estimators list for a customer
  static String jobEstimators({required int customerId}) {
    return '/connector/api/job-estimators?customerId=$customerId';
  }

  static const String createJobEstimator = '/connector/api/job-estimators/store';

  // Job estimator details by id and last 4 digits of phone
  static String jobEstimatorDetails({required int id, required String phoneLast4}) {
    return '/connector/api/job-estimator-details?id=$id&phone=$phoneLast4';
  }

  static const String jobEstimatorSaveProducts = '/connector/api/saveProduct';

  static const String maintenanceNotifications = '/connector/api/maintenance-notifications';
  static const String maintenanceNotificationsMarkRead = '/connector/api/maintenance-notifications/mark-read';
  static const String maintenanceNotificationsMarkAllRead = '/connector/api/maintenance-notifications/mark-all-read';

  static const String blog = '/connector/api/blog';

  static String blogDetails({required int id}) {
    return '/connector/api/blog/$id';
  }

  static const String businessLocations = '/connector/api/booking-app-locations';

  static String businessLocationDetails({required int id}) {
    return '/connector/api/booking-app-locations/$id';
  }

  static const String customerPickupRequest = '/connector/api/add/booking-pickup';

  static String taxonomy({required String type, int? page}) {
    final base = '/connector/api/taxonomy?type=$type';
    if (page == null) return base;
    return '$base&page=$page';
  }

  static const String sparePartsEcomProducts = '/connector/api/public/ecom-products';

  static const String loyaltyPoints = '/connector/api/loyalty-points';
  static const String loyaltyPointsRedeem = '/connector/api/loyalty-points/redeem';

  static String sellInvoices({required int contactId, int? page}) {
    final base = '/connector/api/sell?contact_id=$contactId';
    if (page == null) return base;
    return '$base&page=$page';
  }

  static const String sellProforma = '/connector/api/sell/proforma';

  static const String businessLocation = '/connector/api/business-location';

  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String completeProfile = '/auth/complete-profile';
}
