/// Primary operating modes for the virtual hardware device.
enum AppMode {
  messageReceive,
  bottleMail,
  specificUserSend,
  nameTraceRegistration,
}

extension AppModeX on AppMode {
  /// Button A tap cycles through the three primary modes.
  AppMode nextPrimaryMode() {
    switch (this) {
      case AppMode.messageReceive:
        return AppMode.bottleMail;
      case AppMode.bottleMail:
        return AppMode.specificUserSend;
      case AppMode.specificUserSend:
      case AppMode.nameTraceRegistration:
        return AppMode.messageReceive;
    }
  }

  bool get isPrimaryMode =>
      this != AppMode.nameTraceRegistration;

  String get label {
    switch (this) {
      case AppMode.messageReceive:
        return 'Message Receive';
      case AppMode.bottleMail:
        return 'Bottle Mail';
      case AppMode.specificUserSend:
        return 'Specific User Send';
      case AppMode.nameTraceRegistration:
        return 'Name Trace Registration';
    }
  }
}
