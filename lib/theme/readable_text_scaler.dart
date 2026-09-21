import 'package:flutter/widgets.dart';

/*
 * Makes small text bigger without touching large text.
 *
 * The design copies the website: many labels are 8 to 10 pixels,
 * which is fine on a laptop but hard to read on a phone.
 * Instead of editing dozens of widgets, every font size passes
 * through here before it is drawn:
 *
 *    8 px ->  11 px
 *    9 px ->  11.4 px
 *   10 px ->  11.8 px
 *   11 px ->  12.2 px
 *   12 px ->  12.6 px
 *   13 px and above -> unchanged (titles keep their size)
 *
 * It also keeps the phone's own accessibility setting,
 * so a user who chose "large text" still gets larger text.
 */
class ReadableTextScaler extends TextScaler {
  final TextScaler systemScaler;

  const ReadableTextScaler(this.systemScaler);

  static const double _untouchedFrom = 13;
  static const double _boostPerPixel = 0.6;
  static const double _maxBoost = 3;

  @override
  double scale(double fontSize) {
    final double boost =
    ((_untouchedFrom - fontSize) * _boostPerPixel).clamp(0, _maxBoost);

    return systemScaler.scale(fontSize + boost);
  }

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => systemScaler.textScaleFactor;

  @override
  bool operator ==(Object other) {
    return other is ReadableTextScaler && other.systemScaler == systemScaler;
  }

  @override
  int get hashCode => systemScaler.hashCode;
}
