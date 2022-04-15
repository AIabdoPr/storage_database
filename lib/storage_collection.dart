import 'dart:async';

import './storage_database.dart';
import 'src/storage_database_excption.dart';
import './storage_document.dart';
import 'src/storage_listeners.dart';

class StorageCollection {
  final StorageDatabase storageDatabase;
  final String collectionId;
  late String collectionContentType;
  late StorageListeners storageListeners;

  StorageCollection(this.storageDatabase, this.collectionId) {
    storageListeners = StorageListeners(storageDatabase);
  }

  dynamic checkType(Type dataType) {
    if (!storageDatabase.checkCollectionIdExists(collectionId)) {
      storageDatabase.source.setData(
        collectionId,
        dataType.toString().contains("Map")
            ? {}
            : dataType.toString().contains("List")
                ? []
                : null,
      );
      return dataType.toString().contains("Map")
          ? {}
          : dataType.toString().contains("List")
              ? []
              : null;
    } else {
      dynamic collectionData = storageDatabase.source.getData(collectionId);
      bool currectType = false;
      try {
        if (dataType.toString().contains("Map")) {
          Map.from(collectionData);
          currectType = true;
        } else if (dataType.toString().contains("List")) {
          List.from(collectionData);
          currectType = true;
        } else {
          currectType = collectionData.runtimeType == dataType;
        }
      } catch (e) {
        print("collection check type: $e");
      }
      if (!currectType) {
        throw StorageDatabaseException(
          "The data type must be ${collectionData.runtimeType}, but current type is ($dataType)",
        );
      }
      return collectionData;
    }
  }

  set(var data, {bool log = true, bool keepData = true}) {
    dynamic collectionData = checkType(data.runtimeType);
    if (keepData && data.runtimeType.toString().contains("Map")) {
      for (var key in data.keys) {
        collectionData[key] = data[key];
      }
    } else if (keepData && data.runtimeType.toString().contains("List")) {
      for (var item in data) {
        if (!collectionData.contains(item)) {
          collectionData.add(item);
        }
      }
    } else {
      collectionData = data;
    }
    if (log && storageListeners.hasStreamId(getPath())) {
      storageListeners.setDate(getPath());
    }
    storageDatabase.source.setData(
      collectionId,
      collectionData,
    );
  }

  dynamic get({bool log = true}) {
    if (!storageDatabase.checkCollectionIdExists(collectionId)) {
      throw StorageDatabaseException(
        "This collection ($collectionId) has not yet been created",
      );
    }
    dynamic collectionData = storageDatabase.source.getData(collectionId);
    if (log && storageListeners.hasStreamId(getPath())) {
      storageListeners.getDate(getPath());
    }
    return collectionData;
  }

  String getPath() => collectionId;

  bool hasDocumentId(dynamic documentId) {
    try {
      return Map.from(get()).containsKey(documentId);
    } catch (e) {
      print("has id: $e");
      throw StorageDatabaseException(
        "This Collection ($collectionId) does not support documents",
      );
    }
  }

  Stream stream({delayCheck = const Duration(milliseconds: 50)}) async* {
    storageListeners.initStream(getPath());
    while (true) {
      await Future.delayed(delayCheck);
      Map dates = storageListeners.getDates(getPath());
      if (dates["set_date"] >= dates["get_date"]) {
        yield get();
      }
    }
  }

  Future<bool> delete() async =>
      await storageDatabase.source.remove(collectionId);

  deleteItem(itemId) {
    var collectionData = get();
    collectionData.remove(itemId);
    set(collectionData, keepData: false);
  }

  StorageDocument document(dynamic docId) {
    if (!storageDatabase.checkCollectionIdExists(collectionId)) {
      storageDatabase.source.setData(collectionId, {});
    }
    try {
      Map.from(get());
    } catch (e) {
      print("document error: $e");
      throw StorageDatabaseException(
        "This collection($collectionId) doesn't support documents",
      );
    }
    List docIds = docId.runtimeType == String ? docId.split("/") : [docId];

    StorageDocument document = StorageDocument(
      storageDatabase,
      this,
      true,
      collectionId,
      docIds[0],
      storageListeners,
    );
    for (int i = 1; i < docIds.length; i++) {
      document.set({docIds[i - 1]: {}});
      document = document.document(docIds[i]);
    }
    return document;
  }

  Map<String, StorageDocument> getDocs() {
    var data = get();
    List docsIds;
    if (data.runtimeType.toString().contains("Map")) {
      docsIds = data.keys.toList();
    } else {
      throw StorageDatabaseException(
        "This collection ($collectionId) does not support documents",
      );
    }
    Map<String, StorageDocument> docs = {};
    for (String docId in docsIds) {
      docs[docId] = StorageDocument(
        storageDatabase,
        this,
        true,
        collectionId,
        docId,
        storageListeners,
      );
    }
    return docs;
  }
}
