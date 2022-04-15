import 'dart:convert';
import 'dart:io';

import 'dart:typed_data';

import '../src/storage_database_excption.dart';
import '../src/storage_database_values.dart';
import '../storage_collection.dart';
import '../storage_document.dart';

class StorageExplorerFile {
  File ioFile;
  final String dirPath, filename;
  final StorageCollection explorerCollection;
  final StorageDocument parrentDIrectoryDocument;
  final FileMode mode;
  final Encoding encoding;
  final bool flush;

  StorageExplorerFile(
    this.ioFile,
    this.dirPath,
    this.filename,
    this.explorerCollection,
    this.parrentDIrectoryDocument, {
    this.mode = FileMode.write,
    this.encoding = utf8,
    this.flush = false,
  });

  Future<String> get({bool log = true}) async {
    String data = await ioFile.readAsString();
    if (log &&
        explorerCollection.storageListeners.hasStreamId(_fileShortPath)) {
      explorerCollection.storageListeners.getDate(_fileShortPath);
    }
    return data;
  }

  Future<Uint8List> getBytes({bool log = true}) async {
    if (log &&
        explorerCollection.storageListeners.hasStreamId(_fileShortPath)) {
      explorerCollection.storageListeners.getDate(_fileShortPath);
    }
    return await ioFile.readAsBytes();
  }

  Future<dynamic> getJson({bool log = true}) async {
    try {
      String strData = await get(log: log);
      if (strData.isNotEmpty) {
        return jsonDecode(strData);
      } else {
        return null;
      }
    } catch (e) {
      print("DecodeError: $e");
      throw StorageDatabaseException("Can't decode file ($filename) content.");
    }
  }

  Future set(
    var data, {
    bool log = true,
    bool append = false,
    String appendSplit = "\n",
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) async {
    if (data.runtimeType != String) {
      data = data.toString();
    }
    if (log &&
        explorerCollection.storageListeners.hasStreamId(_fileShortPath)) {
      explorerCollection.storageListeners.setDate(_fileShortPath);
    }
    if (log && explorerCollection.storageListeners.hasStreamId(dirPath)) {
      explorerCollection.storageListeners.setDate(dirPath);
    }
    if (append) {
      String currentData = await get();
      data = "$currentData$appendSplit$data";
    }

    ioFile = await ioFile.writeAsString(data);
  }

  Future setJson(
    dynamic data, {
    bool log = true,
    SetMode setMode = SetMode.append,
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) async {
    dynamic currentData = await getJson();
    if (setMode != SetMode.replace &&
        currentData != null &&
        currentData.runtimeType.toString().contains("Map") &&
        data.runtimeType.toString().contains("Map")) {
      for (var key in data.keys) {
        if (setMode == SetMode.append) {
          currentData[key] = data[key];
        } else if (setMode == SetMode.remove && currentData.containsKey(key)) {
          currentData.remove(key);
        }
      }
    } else if (setMode != SetMode.replace &&
        currentData != null &&
        currentData.runtimeType.toString().contains("List") &&
        data.runtimeType.toString().contains("List")) {
      for (var item in data) {
        if (!currentData.contains(item) && setMode == SetMode.append) {
          currentData.add(item);
        } else if (currentData.contains(item) && setMode == SetMode.remove) {
          currentData.remove(item);
        }
      }
    } else if (setMode != SetMode.replace &&
        currentData != null &&
        currentData.runtimeType != data.runtimeType) {
      throw const StorageDatabaseException("Can't append difrent data");
    } else {
      currentData = data;
    }
    await set(
      jsonEncode(currentData),
      log: log,
      mode: mode,
      encoding: encoding,
      flush: flush,
    );
  }

  Future setBytes(
    Uint8List bytes, {
    bool log = true,
    FileMode mode = FileMode.write,
    bool flush = false,
  }) async {
    ioFile = await ioFile.writeAsBytes(bytes);
    if (log &&
        explorerCollection.storageListeners.hasStreamId(_fileShortPath)) {
      explorerCollection.storageListeners.setDate(_fileShortPath);
    }
    if (log && explorerCollection.storageListeners.hasStreamId(dirPath)) {
      explorerCollection.storageListeners.setDate(dirPath);
    }
  }

  Future delete({bool log = true}) async {
    await ioFile.delete(recursive: true);
    parrentDIrectoryDocument.document("items").deleteItem(filename);
    if (log &&
        explorerCollection.storageListeners.hasStreamId(_fileShortPath)) {
      explorerCollection.storageListeners.setDate(_fileShortPath);
    }
  }

  String get _fileShortPath => "$dirPath/$filename";

  Stream stream({Duration delayCheck = const Duration(milliseconds: 50)}) =>
      _stream(delayCheck, StreamMode.string);

  Stream jsonStream({Duration delayCheck = const Duration(milliseconds: 50)}) =>
      _stream(delayCheck, StreamMode.json);

  Stream bytesStream(
          {Duration delayCheck = const Duration(milliseconds: 50)}) =>
      _stream(delayCheck, StreamMode.bytes);

  Stream _stream(Duration delayCheck, StreamMode streamMode) async* {
    explorerCollection.storageListeners.initStream(_fileShortPath);
    while (true) {
      await Future.delayed(delayCheck);
      Map dates = explorerCollection.storageListeners.getDates(_fileShortPath);
      int lastModified = (await ioFile.lastModified()).microsecondsSinceEpoch;
      if (dates["set_date"] >= dates["get_date"] ||
          lastModified >= dates["get_date"]) {
        explorerCollection.storageListeners.setDate(
          _fileShortPath,
          microseconds: lastModified,
        );
        if (streamMode == StreamMode.json) {
          yield await getJson();
        }
        if (streamMode == StreamMode.bytes) {
          yield await getBytes();
        } else {
          yield await get();
        }
      }
    }
  }
}
