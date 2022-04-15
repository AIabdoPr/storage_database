import 'dart:io';

import 'package:path_provider/path_provider.dart';
import '../storage_collection.dart';
import '../storage_database.dart';
import '../storage_explorer/storage_explorer_directory.dart';
import '../storage_explorer/storage_explorer_file.dart';

class StorageExplorer {
  final StorageDatabase storageDatabase;
  final Directory localIODirectory;
  late StorageCollection explorerCollection;
  late StorageExplorerDirectory localDirectory;

  StorageExplorer(
    this.storageDatabase,
    this.localIODirectory,
  ) {
    storageDatabase.onClear.add(initLocalDirectory);
    initLocalDirectory();
  }

  initLocalDirectory() {
    String localDirName = localIODirectory.path.split("\\").last;
    explorerCollection = StorageCollection(storageDatabase, "explorer");
    explorerCollection.document(localDirName).set({"type": "dir", "items": {}});
    localDirectory = StorageExplorerDirectory(
      localIODirectory,
      localDirName,
      localDirName,
      explorerCollection,
      explorerCollection.document(localDirName),
    );
  }

  static Future<StorageExplorer> getInstance(
    StorageDatabase storageDatabase, {
    String? customPath,
  }) async {
    Directory _localIODirectory = Directory(
      "${(await getApplicationDocumentsDirectory()).path}\\storage_database_explorer${customPath != null ? '\\$customPath' : ''}",
    );
    if (!await _localIODirectory.exists()) {
      _localIODirectory = await _localIODirectory.create();
    }

    return StorageExplorer(
      storageDatabase,
      _localIODirectory,
    );
  }

  StorageExplorerDirectory directory(String dirName, {bool log = true}) {
    List<String> dirNames =
        dirName.contains("/") ? dirName.split("/") : [dirName];

    Directory nIODirectory = Directory(
      "${localIODirectory.path}\\${dirNames[0]}",
    );
    if (!nIODirectory.existsSync()) nIODirectory.createSync();
    localDirectory.directoryDocument.document("items").set({
      dirNames[0]: {"type": "dir", "items": {}}
    });

    if (log && explorerCollection.storageListeners.hasStreamId("explorer")) {
      explorerCollection.storageListeners.setDate("explorer");
    }

    StorageExplorerDirectory storageExplorerDirectory =
        StorageExplorerDirectory(
      nIODirectory,
      dirNames[0],
      dirNames[0],
      explorerCollection,
      localDirectory.directoryDocument.document("items").document(dirNames[0]),
    );
    for (int i = 1; i < dirNames.length; i++) {
      storageExplorerDirectory = storageExplorerDirectory.directory(
        dirNames[i],
      );
    }
    return storageExplorerDirectory;
  }

  StorageExplorerFile file(String filename) {
    Map? dirFiles = localDirectory.directoryDocument.document("items").get();
    if (dirFiles == null || !dirFiles.containsKey(filename)) {
      localDirectory.directoryDocument.document("items").set({
        filename: {
          "type": "file",
        }
      });
    }
    File ioFile = File("${localIODirectory.path}\\$filename");
    if (!ioFile.existsSync()) {
      ioFile.createSync();
    }
    return StorageExplorerFile(
      ioFile,
      "",
      filename,
      explorerCollection,
      localDirectory.directoryDocument,
    );
  }

  Future clear() async => await localDirectory.clear();
}
