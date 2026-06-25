import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui' as ui;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:reservation_workshop/config/routes/routes_name.dart';
import 'package:reservation_workshop/config/style/app_colors.dart';
import 'package:reservation_workshop/config/style/app_theme.dart';
import 'package:reservation_workshop/core/components/toasters.dart';
import 'package:reservation_workshop/core/notifications/notification_service.dart';
import 'package:reservation_workshop/core/network/local/cache_helper.dart';
import 'package:reservation_workshop/core/utils/strings/prefkeys.dart';
import 'package:reservation_workshop/modules/auth/presentation/cubits/auth_cubit/auth_cubit.dart';
import 'package:reservation_workshop/modules/auth/presentation/cubits/auth_otp_cubit/auth_otp_cubit.dart';
import 'package:reservation_workshop/modules/auth/presentation/cubits/login_cubit/login_cubit.dart';
import 'package:reservation_workshop/modules/auth/presentation/cubits/register_cubit/register_cubit.dart';
import 'package:reservation_workshop/modules/auth/presentation/cubits/forgot_password_cubit/forgot_password_cubit.dart';
import 'package:reservation_workshop/modules/auth/presentation/cubits/reset_password_cubit/reset_password_cubit.dart';
import 'package:reservation_workshop/modules/auth/presentation/cubits/shift_cubit/shift_cubit.dart';
import 'package:reservation_workshop/modules/auth/presentation/screens/complete_profile_screen.dart';
import 'package:reservation_workshop/modules/auth/presentation/screens/enter_mobile_screen.dart';
import 'package:reservation_workshop/modules/auth/presentation/screens/login_screen.dart';
import 'package:reservation_workshop/modules/auth/presentation/screens/otp_verification_screen.dart';
import 'package:reservation_workshop/modules/auth/presentation/screens/register_screen.dart';
// import 'package:reservation_workshop/modules/auth/presentation/screens/social_otp_verification_screen.dart'; // No longer needed - OTP flow removed
import 'package:reservation_workshop/modules/auth/presentation/screens/social_update_mobile_screen.dart';
import 'package:reservation_workshop/modules/auth/presentation/screens/social_phone_otp_screen.dart';
import 'package:reservation_workshop/modules/auth/presentation/screens/forgot_password_screen.dart';
import 'package:reservation_workshop/modules/auth/presentation/screens/reset_password_screen.dart';
import 'package:reservation_workshop/modules/auth/presentation/cubits/social_auth_cubit/social_auth_cubit.dart';
import 'package:reservation_workshop/modules/branch/presentation/cubits/branch_cubit/branch_cubit.dart';
import 'package:reservation_workshop/modules/customer/presentation/cubits/customer_info_cubit/customer_info_cubit.dart';
import 'package:reservation_workshop/modules/main/presentation/cubits/app_cubit/app_cubit.dart';
import 'package:reservation_workshop/modules/main/presentation/screens/job_orders_screen.dart';
import 'package:reservation_workshop/modules/main/presentation/screens/booking_details_screen.dart';
import 'package:reservation_workshop/modules/main/presentation/screens/information%20booking%20_screen.dart';
import 'package:reservation_workshop/modules/main/presentation/screens/requests_tabs_screen.dart';
import 'package:reservation_workshop/modules/menu/presentation/screens/menu_rescue_screen.dart';
import 'package:reservation_workshop/modules/menu/presentation/cubits/delete_account_cubit/delete_account_cubit.dart';
import 'package:reservation_workshop/modules/locations/presentation/cubit/business_locations_cubit.dart';
import 'package:reservation_workshop/modules/locations/presentation/screens/business_locations_screen.dart';
import 'package:reservation_workshop/modules/startup/presentation/guest_splash_screen.dart';
import 'package:reservation_workshop/modules/startup/presentation/startup_decider_screen.dart';
import 'package:reservation_workshop/modules/startup/presentation/fullscreen_splash_screen.dart';
import 'package:reservation_workshop/modules/customer/presentation/screens/choose_car_screen.dart';
import 'package:reservation_workshop/modules/customer/presentation/screens/add_car_screen.dart';
import 'package:reservation_workshop/modules/service/presentation/cubits/service_cubit/service_cubit.dart';
import 'package:reservation_workshop/modules/job_orders/presentation/cubits/job_orders_cubit/job_orders_cubit.dart';
import 'package:reservation_workshop/modules/job_order_details/presentation/cubits/job_order_details_cubit/job_order_details_cubit.dart';
import 'package:reservation_workshop/modules/job_order_details/presentation/screens/job_order_details_screen.dart';
import 'package:reservation_workshop/modules/job_estimators/presentation/screens/job_estimator_details_screen.dart';
import 'package:reservation_workshop/modules/bookings/presentation/cubits/add_booking_cubit/add_booking_cubit.dart';
import 'package:reservation_workshop/modules/bookings/presentation/cubits/bookings_cubit/bookings_cubit.dart';
import 'package:reservation_workshop/modules/job_estimators/presentation/cubits/job_estimators_cubit.dart';
import 'package:reservation_workshop/modules/job_estimators/presentation/screens/job_estimators_screen.dart';
import 'package:reservation_workshop/modules/home/presentation/screens/home_screen.dart';
import 'package:reservation_workshop/modules/home/presentation/screens/spare_parts_screen.dart';
import 'package:reservation_workshop/modules/home/presentation/screens/contact_cars_screen.dart';
import 'package:reservation_workshop/modules/home/presentation/screens/buy_car_screen.dart';
import 'package:reservation_workshop/modules/home/presentation/cubit/blog_cubit.dart';
import 'package:reservation_workshop/modules/home/presentation/cubit/vehicles_cubit.dart';
import 'package:reservation_workshop/modules/spare_parts/presentation/cubits/taxonomy_cubit/taxonomy_cubit.dart';
import 'package:reservation_workshop/modules/spare_parts/presentation/cubits/cart_cubit/cart_cubit.dart';
import 'package:reservation_workshop/modules/menu/presentation/screens/menu_about_center_screen.dart';
import 'package:reservation_workshop/modules/menu/presentation/screens/menu_about_skoda_screen.dart';
import 'package:reservation_workshop/modules/menu/presentation/screens/menu_account_screen.dart';
import 'package:reservation_workshop/modules/menu/presentation/screens/menu_change_language_screen.dart';
import 'package:reservation_workshop/modules/menu/presentation/screens/menu_contact_screen.dart';
import 'package:reservation_workshop/modules/menu/presentation/screens/menu_logout_screen.dart';
import 'package:reservation_workshop/modules/notifications/presentation/cubit/maintenance_notifications_cubit.dart';
import 'package:reservation_workshop/modules/notifications/presentation/screens/maintenance_notifications_screen.dart';
import 'package:reservation_workshop/modules/loyalty_points/presentation/cubit/loyalty_points_cubit.dart';
import 'package:reservation_workshop/modules/loyalty_points/presentation/screens/loyalty_points_screen.dart';
import 'package:reservation_workshop/modules/startup/presentation/first_language_screen.dart';
import 'package:reservation_workshop/modules/invoices/presentation/screens/invoice_details_screen.dart';


@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } on FirebaseException catch (e) {
    final code = e.code ?? '';
    final msg = (e.message ?? '').toLowerCase();
    if (!(code.contains('duplicate') || msg.contains('already exists'))) rethrow;
  }
  debugPrint(
    '📩 FCM (background) messageId=${message.messageId} '
    'title=${message.notification?.title} '
    'body=${message.notification?.body} '
    'data=${message.data}',
  );
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } on FirebaseException catch (e) {
    final code = e.code ?? '';
    final msg = (e.message ?? '').toLowerCase();
    if (!(code.contains('duplicate') || msg.contains('already exists'))) rethrow;
  }

  // Initialize Firebase Messaging (skip on web if it fails)
  try {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await NotificationService.ensureInitialized();

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('🔔 Notification permission status => ${settings.authorizationStatus}');

    final fcmToken = await FirebaseMessaging.instance.getToken();
    debugPrint('✅ CURRENT FCM TOKEN => $fcmToken');

    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      debugPrint('🔄 FCM TOKEN REFRESHED => $token');
    });

    try {
      await FirebaseMessaging.instance.subscribeToTopic('gmotors_test');
      debugPrint('✅ Subscribed to topic => gmotors_test');
    } catch (e) {
      debugPrint('❌ Failed to subscribe to topic gmotors_test => $e');
    }

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
        '📬 FCM (initialMessage) messageId=${initialMessage.messageId} '
        'title=${initialMessage.notification?.title} '
        'body=${initialMessage.notification?.body} '
        'data=${initialMessage.data}',
      );
    }

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint(
        '📬 FCM (onMessageOpenedApp) messageId=${message.messageId} '
        'title=${message.notification?.title} '
        'body=${message.notification?.body} '
        'data=${message.data}',
      );
    });

    FirebaseMessaging.onMessage.listen((message) async {
      debugPrint(
        '📩 FCM (foreground) messageId=${message.messageId} '
        'title=${message.notification?.title} '
        'body=${message.notification?.body} '
        'data=${message.data}',
      );
      if (message.notification != null) {
        await NotificationService.showRemoteMessage(message);
      }
    });
  } catch (e) {
    debugPrint('⚠️ Firebase Messaging initialization failed (may not be available on web): $e');
  }

  await EasyLocalization.ensureInitialized();
  await CacheHelper.init();

  final savedCode = await CacheHelper.getDataAsync<String>(key: PrefKeys.kLocaleCode);
  final normalized = (savedCode ?? '').trim().toLowerCase();
  final initialLocale = normalized == 'ar' ? const Locale('ar') : const Locale('en');

  // Check if user is logged in
  final String? token = await CacheHelper.getDataAsync<String>(key: PrefKeys.kAccessToken);
  final bool isLoggedIn = token != null && token.trim().isNotEmpty;

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: initialLocale,
      child: MyApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (_) => AuthCubit()),
        BlocProvider<AuthOtpCubit>(create: (_) => AuthOtpCubit()),
        BlocProvider<SocialAuthCubit>(create: (_) => SocialAuthCubit()),
        BlocProvider<AppCubit>(create: (_) => AppCubit()),
        BlocProvider<ShiftCubit>(create: (_) => ShiftCubit()),
        BlocProvider<BlogCubit>(create: (_) => BlogCubit()),
        BlocProvider<BusinessLocationsCubit>(create: (_) => BusinessLocationsCubit()),
        BlocProvider<CustomerInfoCubit>(create: (_) => CustomerInfoCubit()),
        BlocProvider<DeleteAccountCubit>(create: (_) => DeleteAccountCubit()),
      ],
      child: MaterialApp(
        scaffoldMessengerKey: Toasters.messengerKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(locale: context.locale),
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        builder: (context, child) {
          final isAr = context.locale.languageCode == 'ar';
          return Container(
            decoration: const BoxDecoration(
              gradient: AppColors.appBackgroundGradient,
            ),
            child: Directionality(
              textDirection: isAr ? ui.TextDirection.rtl : ui.TextDirection.ltr,
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
        home: isLoggedIn ? const FullscreenSplashScreen() : const GuestSplashScreen(),
        routes: {
          '/fullscreen_splash': (_) => const FullscreenSplashScreen(),
          '/startup': (_) => const StartupDeciderScreen(),
          RoutesName.guestSplashScreen: (_) => const GuestSplashScreen(),
          RoutesName.firstLanguageScreen: (_) => const FirstLanguageScreen(),
          RoutesName.enterMobileScreen: (_) => const EnterMobileScreen(),
          RoutesName.socialUpdateMobileScreen: (_) => const SocialUpdateMobileScreen(),
          RoutesName.socialPhoneOtpScreen: (_) => const SocialPhoneOtpScreen(),
          RoutesName.forgotPasswordScreen: (_) => BlocProvider<ForgotPasswordCubit>(
                create: (_) => ForgotPasswordCubit(),
                child: const ForgotPasswordScreen(),
              ),
          RoutesName.resetPasswordScreen: (_) => BlocProvider<ResetPasswordCubit>(
                create: (_) => ResetPasswordCubit(),
                child: const ResetPasswordScreen(),
              ),
          RoutesName.otpVerificationScreen: (_) => const OtpVerificationScreen(),
          // RoutesName.socialOtpVerificationScreen: (_) => const SocialOtpVerificationScreen(), // No longer needed - OTP flow removed
          RoutesName.completeProfileScreen: (_) => const CompleteProfileScreen(),
          RoutesName.loginScreen: (_) => BlocProvider<LoginCubit>(
                create: (_) => LoginCubit(),
                child: const LoginScreen(),
              ),
          RoutesName.registerScreen: (_) => BlocProvider<RegisterCubit>(
                create: (_) => RegisterCubit(),
                child: const RegisterScreen(),
              ),
          RoutesName.chooseCarScreen: (_) => BlocProvider<CustomerInfoCubit>(
                create: (_) => CustomerInfoCubit(),
                child: const ChooseCarScreen(),
              ),
          RoutesName.addCarScreen: (_) => const AddCarScreen(),
          RoutesName.homeScreen: (_) => MultiBlocProvider(
                providers: [
                  BlocProvider<CustomerInfoCubit>(create: (_) => CustomerInfoCubit()),
                  BlocProvider<BookingsCubit>(create: (_) => BookingsCubit()),
                  BlocProvider<BlogCubit>(create: (_) => BlogCubit()..loadFirst(localeCode: context.locale.languageCode)),
                ],
                child: const HomeScreen(),
              ),
          RoutesName.sparePartsScreen: (_) => MultiBlocProvider(
                providers: [
                  BlocProvider<TaxonomyCubit>(create: (_) => TaxonomyCubit()),
                  BlocProvider<CustomerInfoCubit>(create: (_) => CustomerInfoCubit()),
                  BlocProvider<CartCubit>(create: (_) => CartCubit()),
                ],
                child: const SparePartsScreen(),
              ),
          RoutesName.contactCarsScreen: (_) => const ContactCarsScreen(),
          RoutesName.buyCarScreen: (_) => BlocProvider<VehiclesCubit>(
                create: (_) => VehiclesCubit(),
                child: const BuyCarScreen(),
              ),
          RoutesName.invoiceDetailsScreen: (_) => const InvoiceDetailsScreen(),
          RoutesName.mainScreen: (_) => MultiBlocProvider(
                providers: [
                  BlocProvider<CustomerInfoCubit>(create: (_) => CustomerInfoCubit()),
                  BlocProvider<BranchCubit>(create: (_) => BranchCubit()),
                  BlocProvider<ServiceCubit>(create: (_) => ServiceCubit()),
                  BlocProvider<JobOrdersCubit>(create: (_) => JobOrdersCubit()),
                  BlocProvider<JobEstimatorsCubit>(create: (_) => JobEstimatorsCubit()),
                  BlocProvider<MaintenanceNotificationsCubit>(create: (_) => MaintenanceNotificationsCubit()),
                ],
                child: const RequestsTabsScreen(),
              ),
          RoutesName.jobOrdersScreen: (_) => BlocProvider<JobOrdersCubit>(
                create: (_) => JobOrdersCubit(),
                child: const JobOrdersScreen(),
              ),
          RoutesName.jobOrderDetailsScreen: (_) => BlocProvider<JobOrderDetailsCubit>(
                create: (_) => JobOrderDetailsCubit(),
                child: const JobOrderDetailsScreen(),
              ),
          RoutesName.informationBookingsScreen: (_) => MultiBlocProvider(
                providers: [
                  BlocProvider<BookingsCubit>(create: (_) => BookingsCubit()),
                  BlocProvider<CustomerInfoCubit>(create: (_) => CustomerInfoCubit()),
                ],
                child: const InformationBookingsScreen(),
              ),
          RoutesName.notificationsScreen: (context) {
                MaintenanceNotificationsCubit? existing;
                try {
                  existing = BlocProvider.of<MaintenanceNotificationsCubit>(context);
                } catch (_) {
                  existing = null;
                }

                if (existing != null) {
                  return BlocProvider.value(
                    value: existing,
                    child: const MaintenanceNotificationsScreen(),
                  );
                }

                return BlocProvider<MaintenanceNotificationsCubit>(
                  create: (_) => MaintenanceNotificationsCubit(),
                  child: const MaintenanceNotificationsScreen(),
                );
              },
          RoutesName.bookingDetailsScreen: (_) => BlocProvider<AddBookingCubit>(
                create: (_) => AddBookingCubit(),
                child: const BookingDetailsScreen(),
              ),
          RoutesName.jobEstimatorsScreen: (_) => MultiBlocProvider(
                providers: [
                  BlocProvider<CustomerInfoCubit>(create: (_) => CustomerInfoCubit()),
                  BlocProvider<JobEstimatorsCubit>(create: (_) => JobEstimatorsCubit()),
                ],
                child: const JobEstimatorsScreen(),
              ),
          RoutesName.jobEstimatorDetailsScreen: (_) => const JobEstimatorDetailsScreen(),

          RoutesName.menuAccountScreen: (context) => BlocProvider.value(
                value: BlocProvider.of<CustomerInfoCubit>(context),
                child: BlocProvider.value(
                  value: BlocProvider.of<DeleteAccountCubit>(context),
                  child: const MenuAccountScreen(),
                ),
              ),
          RoutesName.menuAboutSkodaScreen: (_) => const MenuAboutSkodaScreen(),
          RoutesName.menuRescueScreen: (_) => MenuRescueScreen(),
          RoutesName.menuContactScreen: (_) => const MenuContactScreen(),
          RoutesName.menuAboutCenterScreen: (_) => const MenuAboutCenterScreen(),
          RoutesName.menuLoyaltyPointsScreen: (_) => MultiBlocProvider(
                providers: [
                  BlocProvider<CustomerInfoCubit>(create: (_) => CustomerInfoCubit()),
                  BlocProvider<LoyaltyPointsCubit>(create: (_) => LoyaltyPointsCubit()),
                ],
                child: const LoyaltyPointsScreen(),
              ),
          RoutesName.menuChangeLanguageScreen: (_) => const MenuChangeLanguageScreen(),
          RoutesName.menuLogoutScreen: (_) => const MenuLogoutScreen(),
          RoutesName.businessLocationsScreen: (_) => BlocProvider<BusinessLocationsCubit>(
                create: (_) => BusinessLocationsCubit(),
                child: const BusinessLocationsScreen(),
              ),
        },
      ),
    );
  }
}
