import 'package:flutter/material.dart';

/// Normalized anchor positions for feedback overlay cues.
abstract final class VisualCueLayout {
  static const buttonAX = 0.12;
  static const buttonBX = 0.88;
  static const buttonY = 0.88;

  static const friendLeftX = 0.18;
  static const friendRightX = 0.82;
  static const friendY = 0.78;

  static const pulseLineY = 0.72;
  static const nameTraceSavedY = 0.72;

  static const alertCenterY = 0.45;
  static const senderRemovedCenterY = 0.55;

  static Offset buttonA(Size size) =>
      Offset(size.width * buttonAX, size.height * buttonY);

  static Offset buttonB(Size size) =>
      Offset(size.width * buttonBX, size.height * buttonY);

  static Offset corner(Size size, {required bool right}) => Offset(
        size.width * (right ? buttonBX : buttonAX),
        size.height * buttonY,
      );
}
