import 'dart:io';

import 'storage_explorer_directory_item.dart';

import '../storage_collection.dart';
import '../storage_document.dart';
import '../storage_explorer/storage_explorer_file.dart';

class StorageExplorerDirectory {
  final Directory ioDirectory;
  final String directoryName, shortPath;
  final StorageCollection explorerCollection;
  final StorageDocument directoryDocument;

  StorageExplorerDirectory(
    this.ioDirectory,
    this.directoryName,
    this.shortPath,
    this.explorerCollection,
    this.directoryDocument,
  );

  List<StorageExplorerDirectoryItem> get({bool log = true}) {
    List<FileSystemEntity> ioFiles = ioDirectory.listSync();
    List<StorageExplorerDirectoryItem> items = [];
    for (FileSystemEntity item in ioFiles) {
      String itemName = item.path.split("\\").last;
      bool isDirectory = item.runtimeType.toString().contains("Directory");
      if (isDirectory) {
        items.add(
          StorageExplorerDirectoryItem(itemName, directory(itemName), this),
        );
      } else {
        items.add(
          StorageExplorerDirectoryItem(itemName, file(itemName), this),
        );
      }
    }
    if (log && explorerCollection.storageListeners.hasStreamId(shortPath)) {
      explorerCollection.storageListeners.setDate(shortPath);
    }
    return items;
  }

  StorageExplorerFile file(String filename) {
    Map? dirFiles = directoryDocument.get();
    if (dirFiles == null || !dirFiles.containsKey(filename)) {
      directoryDocument.document("items").set({
        filename: {"type": "file"}
      });
    }
    return StorageExplorerFile(
      File("${ioDirectory.path}\\$filename"),
      shortPath,
      filename,
      explorerCollection,
      directoryDocument,
    );
  }

  StorageExplorerDirectory directory(String dirName, {bool log = true}) {
    List<String> dirNames =
        dirName.contains("/") ? dirName.split("/") : [dirName];

    Directory nioDirectory = Directory("${ioDirectory.path}\\${dirNames[0]}");
    if (!nioDirectory.existsSync()) nioDirectory.createSync();

    directoryDocument.document("items").set({
      dirNames[0]: {"type": "dir", "items": {}}
    });

    if (log && explorerCollection.storageListeners.hasStreamId(shortPath)) {
      explorerCollection.storageListeners.setDate(shortPath);
    }

    StorageExplorerDirectory storageExolorerDirectory =
        StorageExplorerDirectory(
      nioDirectory,
      dirNames[0],
      "$shortPath/${dirNames[0]}",
      explorerCollection,
      directoryDocument.document("items").document(dirNames[0]),
    );

    for (int i = 1; i < dirNames.length; i++) {
      storageExolorerDirectory = storageExolorerDirectory.directory(
        dirNames[i],
      );
    }

    return storageExolorerDirectory;
  }

  Future delete({bool log = true}) async {
    await ioDirectory.delete(recursive: true);
    directoryDocument.delete();
    if (log && explorerCollection.storageListeners.hasStreamId(shortPath)) {
      explorerCollection.storageListeners.setDate(shortPath);
    }
  }

  Stream<List<StorageExplorerDirectoryItem>> stream(
      {delayCheck = const Duration(milliseconds: 50)}) async* {
    explorerCollection.storageListeners.initStream(shortPath);
    while (true) {
      await Future.delayed(delayCheck);
      Map dates = explorerCollection.storageListeners.getDates(shortPath);
      if (dates["set_date"] >= dates["get_date"]) {
        yield get();
      }
    }
  }

  Future clear() async {
    List<StorageExplorerDirectoryItem> dirItems = get();
    for (var item in dirItems) {
      if (item.runtimeType == StorageExplorerDirectory) {
        StorageExplorerDirectory dir = item.item;
        await dir.delete();
      } else {
        await item.item.delete();
      }
    }
  }
}
