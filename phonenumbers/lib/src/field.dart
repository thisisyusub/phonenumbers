import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phonenumbers_core/core.dart';

import 'controller.dart';
import 'country_dialog.dart';

typedef PhoneNumberFieldPrefixBuilder = Widget? Function(
  BuildContext context,
  Country? country,
);

class PhoneNumberField extends StatefulWidget {
  const PhoneNumberField({
    Key? key,
    this.decoration = const InputDecoration(),
    this.style,
    this.countryCodeWidth = 135,
    this.controller,
    this.dialogTitle = 'Area code',
    this.prefixBuilder = _buildPrefix,
  }) : super(key: key);

  /// Input decoration to customize input.
  final InputDecoration decoration;

  /// Editing controller that stores current state of the widget.
  final PhoneNumberEditingController? controller;

  /// Text font style
  final TextStyle? style;

  /// Width of the country code section
  final double countryCodeWidth;

  /// Title of area code selection dialog
  final String dialogTitle;

  /// A widget builder used to customize prefix icon.
  ///
  /// Example:
  ///
  /// ```dart
  /// Widget? buildPhoneNumberPrefix(BuildContext context, Country? country) {
  ///   return country != null
  ///     ? Image.network(
  ///         'https://www.countryflags.io/${country!.code}/flat/24.png',
  ///         width: 24,
  ///         height: 24,
  ///       )
  ///     : null;
  /// }
  /// ```
  final PhoneNumberFieldPrefixBuilder prefixBuilder;

  /// Default value for [PhoneNumberField.prefixIconGenerator]
  static PhoneNumberFieldPrefixBuilder? defaultPrefixBuilder;

  @override
  _PhoneNumberFieldState createState() => _PhoneNumberFieldState();

  static Widget? _buildPrefix(BuildContext context, Country? country) {
    return defaultPrefixBuilder != null
        ? defaultPrefixBuilder!(context, country)
        : null;
  }
}

class _PhoneNumberFieldState extends State<PhoneNumberField> {
  bool _countryCodeFocused = false;
  PhoneNumberEditingController? _controller;
  final TextStyle _hiddenText = TextStyle(
    color: Colors.transparent,
    height: 0,
    fontSize: 0,
  );

  PhoneNumberEditingController? get _effectiveController =>
      widget.controller ?? _controller;

  Future<void> onChangeCountry() async {
    _countryCodeFocused = true;
    try {
      final country = await Navigator.of(context).push(CountryDialog.route(
        title: widget.dialogTitle,
      ));
      if (country != null) {
        _effectiveController!.country = country;
      }
    } finally {
      _countryCodeFocused = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void initState() {
    if (widget.controller == null) {
      _controller = PhoneNumberEditingController();
    }
    super.initState();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        width: 1,
        color: Color(0xFFE4E9F2),
      ),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        width: 1,
        color: Color(0xFF0073E6),
      ),
    );

    return InputDecorator(
      decoration: InputDecoration(
        border: border,
        enabledBorder: border,
        focusedBorder: focusedBorder,
        contentPadding: EdgeInsets.symmetric(horizontal: 18),
        labelText: 'Phone',
        errorText: 'error',
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          GestureDetector(
            onTap: onChangeCountry,
            child: ValueListenableBuilder<Country?>(
              valueListenable: _effectiveController!.countryNotifier,
              builder: (context, value, child) {
                final flag = value?.code.toUpperCase().replaceAllMapped(
                      RegExp(r'[A-Z]'),
                      (match) => String.fromCharCode(
                          match.group(0)!.codeUnitAt(0) + 127397),
                    );

                return Row(
                  children: [
                    if (flag == null)
                      Text(
                        '+${value?.prefix ?? ''}',
                      ),
                    if (flag != null)
                      Text(
                        flag,
                        style: TextStyle(fontSize: 24),
                      ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.expand_more_rounded,
                      size: 20,
                      color: Color(0xFF292D32),
                    )
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<Country?>(
              valueListenable: _effectiveController!.countryNotifier,
              builder: (context, value, child) {
                return TextField(
                  controller: _effectiveController!.nationalNumberController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: value?.length.maxLength ?? 15,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 18,
                    ),
                    counterText: '',
                    isDense: false,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
