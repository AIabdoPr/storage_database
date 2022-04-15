library storage_database;

import './defualt_storae_source.dart';
import './storage_collection.dart';
import 'src/storage_database_excption.dart';
import 'src/storage_database_source.dart';
import './storage_document.dart';
import 'storage_explorer/storage_explorer.dart';

class StorageDatabase {
  final StorageDatabaseSource source;
  StorageExplorer? explorer;
  List<Function> onClear = [];

  StorageDatabase(this.source);

  static Future<StorageDatabase> getInstance({
    StorageDatabaseSource? source,
  }) async =>
      StorageDatabase(
        source ?? await DefualtStorageSource.getInstance(),
      );

  Future initExplorer() async =>
      explorer = await StorageExplorer.getInstance(this);

  StorageCollection collection(String collectionId) =>
      StorageCollection(this, collectionId);

  StorageDocument document(String documentPath) {
    if (!documentPath.contains("/")) {
      throw const StorageDatabaseException(
        "Incorrect document path, ex: 'collection/doc/docChild'",
      );
    }
    List<String> docIds = documentPath.split("/");
    StorageDocument document = StorageCollection(this, docIds[0]).document(
      docIds[1],
    );
    for (int i = 2; i < docIds.length; i++) {
      document.set({docIds[i - 1]: {}});
      document = document.document(docIds[i]);
    }
    return document;
  }

  bool checkCollectionIdExists(String collectionId) {
    return source.containsKey(collectionId);
  }

  Future clear() async {
    if (explorer != null) {
      await explorer!.clear();
    }
    await source.clear();

    for (Function onClearFunc in onClear) {
      onClearFunc();
    }
  }
}
