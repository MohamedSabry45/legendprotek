import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class JobOrderDetailsPhonePrompt extends StatefulWidget {
  const JobOrderDetailsPhonePrompt({super.key});

  @override
  State<JobOrderDetailsPhonePrompt> createState() =>
      _JobOrderDetailsPhonePromptState();
}

class _JobOrderDetailsPhonePromptState
    extends State<JobOrderDetailsPhonePrompt> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isValidLast4(String v) {
    final s = v.trim();
    if (s.length != 4) return false;
    return RegExp(r'^[0-9\u0660-\u0669]{4}$').hasMatch(s);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: context.locale.languageCode == 'ar'
          ? ui.TextDirection.rtl
          : ui.TextDirection.ltr,
      child: AlertDialog(
        title: Text(
          'job_order.phone_prompt_title'.tr(),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'job_order.phone_prompt_message'.tr(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'job_order.phone_prompt_hint'.tr(),
                errorText: _error,
                border: const OutlineInputBorder(),
              ),
              maxLength: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text(
              'common.cancel'.tr(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
          TextButton(
            onPressed: () {
              final v = _controller.text;
              if (!_isValidLast4(v)) {
                setState(() => _error = 'job_order.phone_prompt_invalid'.tr());
                return;
              }
              Navigator.pop(context, v.trim());
            },
            child: Text(
              'common.continue_action'.tr(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
