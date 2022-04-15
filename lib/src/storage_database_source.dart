abstract class StorageDatabaseSource {
  setData(String id, dynamic data);
  getData(String id);
  containsKey(String id);
  clear();
  remove(String id);
}
