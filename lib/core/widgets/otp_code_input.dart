import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Converts Arabic-Indic digits (٠-٩, U+0660-0669) and Extended
/// Arabic-Indic digits (۰-۹, U+06F0-06F9) to ASCII digits so OTP
/// input works the same in Arabic and English keyboards.
String normalizeDigits(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    if (rune >= 0x0660 && rune <= 0x0669) {
      buffer.writeCharCode(0x30 + (rune - 0x0660));
    } else if (rune >= 0x06F0 && rune <= 0x06F9) {
      buffer.writeCharCode(0x30 + (rune - 0x06F0));
    } else {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}

class _DigitNormalizer extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final normalized = normalizeDigits(newValue.text);
    if (normalized == newValue.text) return newValue;
    return newValue.copyWith(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
      composing: TextRange.empty,
    );
  }
}

/// A single-row OTP/PIN input that stays LTR in every locale, supports
/// pasting the whole code, SMS autofill and Arabic-Indic digits.
///
/// Implementation: one invisible master [TextFormField] receives all input
/// (typing, paste, autofill), while the visible digits are rendered as
/// boxes always laid out left-to-right.
class OtpCodeInput extends StatefulWidget {
  const OtpCodeInput({
    super.key,
    required this.controller,
    this.length = 5,
    this.validator,
    this.onChanged,
    this.onCompleted,
    this.boxSize = 56,
    this.fillColor = const Color(0xFF050505),
    this.borderColor = const Color(0xFF0A0A0A),
    this.focusedBorderColor = Colors.white,
    this.errorBorderColor = const Color(0xFFD4AF37),
    this.textStyle = const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  });

  /// Holds the full code. Read [controller].text for the value.
  final TextEditingController controller;
  final int length;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final double boxSize;
  final Color fillColor;
  final Color borderColor;
  final Color focusedBorderColor;
  final Color errorBorderColor;
  final TextStyle textStyle;

  @override
  State<OtpCodeInput> createState() => _OtpCodeInputState();
}

class _OtpCodeInputState extends State<OtpCodeInput> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _focusMaster() {
    _focusNode.requestFocus();
    widget.controller.selection = TextSelection.collapsed(
      offset: widget.controller.text.length,
    );
  }

  Widget _box(int index, bool hasError) {
    final text = widget.controller.text;
    final filled = index < text.length;
    final isNext = index == text.length && _focusNode.hasFocus;

    final borderColor = hasError
        ? widget.errorBorderColor
        : (isNext ? widget.focusedBorderColor : widget.borderColor);

    return Container(
      width: widget.boxSize,
      height: widget.boxSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: widget.fillColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: isNext ? 2 : 1.5),
      ),
      child: Text(filled ? text[index] : '', style: widget.textStyle),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (_) => widget.validator?.call(widget.controller.text),
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Boxes are always laid out left-to-right so the code is never
            // mirrored in RTL locales.
            Directionality(
              textDirection: TextDirection.ltr,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0,
                      child: TextFormField(
                        controller: widget.controller,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.number,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.center,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        maxLength: widget.length,
                        inputFormatters: [
                          _DigitNormalizer(),
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        showCursor: false,
                        enableInteractiveSelection: true,
                        onChanged: (value) {
                          state.didChange(value);
                          setState(() {});
                          widget.onChanged?.call(value);
                          if (value.length == widget.length) {
                            widget.onCompleted?.call(value);
                          }
                        },
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _focusMaster,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        widget.length,
                        (index) => _box(index, state.hasError),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  state.errorText ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD4AF37),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
