// Web stub for dart:io's File, Directory, FileSystemEntity, and Platform APIs
// Ensures code compiles on web when imported conditionally.

import 'dart:typed_data';

class File {
  final String path;
  File(this.path);
  bool existsSync() => false;
  List<int> readAsBytesSync() => <int>[];
  Future<bool> exists() async => false;
  Future<Uint8List> readAsBytes() async => Uint8List(0);
  Future<void> delete() async {}
  DateTime lastModifiedSync() => DateTime.fromMillisecondsSinceEpoch(0);
}

// file entity stub

class FileSystemEntity {
  String get path => '';
  Future<void> delete() async {}
}

class Directory extends FileSystemEntity {
  final String path;
  Directory(this.path);
  List<FileSystemEntity> listSync(
          {bool recursive = false, bool followLinks = true}) =>
      [];
  Stream<FileSystemEntity> list(
      {bool recursive = false, bool followLinks = true}) async* {}
  Future<bool> exists() async => false;
}

class Platform {
  static String get pathSeparator => "/";
  static bool get isAndroid => false;
  static bool get isIOS => false;
}

class WebFileEntity extends FileSystemEntity {}