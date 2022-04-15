abstract class Mode {
  final String _modeName;
  const Mode._intial(this._modeName);
  String get modeName => _modeName;
}

class SetMode extends Mode {
  const SetMode._intial(String modeName) : super._intial(modeName);

  static const SetMode append = SetMode._intial("append");
  static const SetMode replace = SetMode._intial("replace");
  static const SetMode remove = SetMode._intial("remove");
}

class StreamMode extends Mode {
  const StreamMode._intial(String modeName) : super._intial(modeName);

  static const StreamMode string = StreamMode._intial("string");
  static const StreamMode json = StreamMode._intial("json");
  static const StreamMode bytes = StreamMode._intial("bytes");
}
