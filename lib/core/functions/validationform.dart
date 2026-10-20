import 'package:easy_localization/easy_localization.dart';

class ValidationForm {
  static String? nameValidator(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return 'common.required'.tr();
    }
    return null;
  }

  static String? emailValidator(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return 'common.required'.tr();
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
      return 'common.invalid_email'.tr();
    }
    return null;
  }

  static String? passwordValidator(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return 'common.required'.tr();
    }
    if (v.length < 4) {
      return 'common.too_short'.tr();
    }
    return null;
  }
}
