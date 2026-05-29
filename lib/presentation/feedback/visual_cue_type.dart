import 'package:tracelet/domain/models/app_mode.dart';

/// Short-lived overlay animations on button press (complements canvas traces).
enum VisualCueType {
  buttonBAction,
  modeChange,
  toggleNotifications,
  toggleAutoPlay,
  toggleAutoContinuous,
  messagePlayStart,
  friendConnected,
  senderRemoved,
  destinationSwitch,
  nameTraceRegistration,
  nameTraceSaved,
  settingsTransition,
  alert,
}

extension VisualCueTypeX on VisualCueType {
  Duration get duration {
    switch (this) {
      case VisualCueType.buttonBAction:
      case VisualCueType.modeChange:
        return const Duration(milliseconds: 900);
      case VisualCueType.messagePlayStart:
        return const Duration(milliseconds: 350);
      case VisualCueType.settingsTransition:
        return const Duration(milliseconds: 450);
      case VisualCueType.alert:
        return const Duration(milliseconds: 500);
      default:
        return const Duration(milliseconds: 700);
    }
  }

  int rippleCount({AppMode? mode}) {
    if (this != VisualCueType.modeChange || mode == null) return 1;
    switch (mode) {
      case AppMode.messageReceive:
        return 1;
      case AppMode.bottleMail:
        return 2;
      case AppMode.specificUserSend:
        return 3;
      case AppMode.nameTraceRegistration:
        return 1;
    }
  }
}
