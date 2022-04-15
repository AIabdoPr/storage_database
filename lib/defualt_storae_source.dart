import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'src/storage_database_source.dart';

class DefualtStorageSource extends StorageDatabaseSource {
  final SharedPreferences storage;

  DefualtStorageSource(this.storage);

  static Future<DefualtStorageSource> getInstance() async =>
      DefualtStorageSource(await SharedPreferences.getInstance());

  @override
  Future<bool> setData(String id, dynamic data) async {
    data = jsonEncode(data);
    return storage.setString(id, data);
  }

  @override
  dynamic getData(String id) {
    String? data = storage.getString(id);
    if (data != null) {
      return jsonDecode(data);
    } else {
      return null;
    }
  }

  @override
  bool containsKey(String key) => storage.containsKey(key);

  @override
  Future<bool> remove(String id) async => await storage.remove(id);

  @override
  Future<bool> clear() async => await storage.clear();
}
