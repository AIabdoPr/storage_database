import 'storage_explorer_directory.dart';

class StorageExplorerDirectoryItem {
  final String itemName;
  late Type itemType;
  final dynamic item;
  final StorageExplorerDirectory directoryParrent;

  StorageExplorerDirectoryItem(
    this.itemName,
    this.item,
    this.directoryParrent,
  ) {
    itemType = item.runtimeType;
  }
}
