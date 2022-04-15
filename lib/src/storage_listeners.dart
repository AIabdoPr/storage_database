import 'dart:convert';

import '../storage_database.dart';

class StorageListeners {
  StorageDatabase storageDatabase;

  StorageListeners(this.storageDatabase) {
    if (!storageDatabase.source.containsKey('listeners')) {
      storageDatabase.source.setData("listeners", "{}");
    }
  }

  Map getListenersData() => jsonDecode(
        storageDatabase.source.getData("listeners") ?? "{}",
      );

  Future<bool> setListenersData(Map data) => storageDatabase.source.setData(
        "listeners",
        jsonEncode(data),
      );

  bool hasStreamId(String streamId) {
    try {
      Map listenersData = getListenersData();
      return listenersData.containsKey(streamId);
    } catch (e) {
      print("has stream id: $e");
      return false;
    }
  }

  initStream(String streamId) {
    Map listenersData = getListenersData();
    listenersData[streamId] = {"set_date": 1, "get_date": 0};
    setListenersData(listenersData);
  }

  int setDate(String streamId, {int? microseconds}) {
    Map listenersData = getListenersData();
    int microsecondsSinceEpoch =
        microseconds ?? DateTime.now().microsecondsSinceEpoch;
    listenersData[streamId]["set_date"] = microsecondsSinceEpoch;
    setListenersData(listenersData);
    return microsecondsSinceEpoch;
  }

  int getDate(String streamId, {int? microseconds}) {
    Map listenersData = getListenersData();
    int microsecondsSinceEpoch =
        microseconds ?? DateTime.now().microsecondsSinceEpoch;
    listenersData[streamId]["get_date"] = microsecondsSinceEpoch;
    setListenersData(listenersData);
    return microsecondsSinceEpoch;
  }

  Map getDates(String streamId) => getListenersData()[streamId];
}
