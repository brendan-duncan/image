import 'ifd_directory.dart';

class IfdContainer {
  Map<String, IfdDirectory> directories;

  IfdContainer()
      : directories = {};

  IfdContainer.from(IfdContainer? other)
      : directories = other == null
          ? {} : Map<String, IfdDirectory>.from(other.directories);

  Iterable<String> get keys => directories.keys;
  Iterable<IfdDirectory> get values => directories.values;

  bool get isEmpty {
    if (directories.isEmpty) {
      return true;
    }
    for (var ifd in directories.values) {
      if (!ifd.isEmpty) {
        return false;
      }
    }
    return true;
  }

  bool containsKey(String key) => directories.containsKey(key);

  void clear() {
    directories.clear();
  }

  IfdDirectory operator[](String ifdName) {
    if (!directories.containsKey(ifdName)) {
      directories[ifdName] = IfdDirectory();
    }
    return directories[ifdName]!;
  }

  void operator[]=(String ifdName, IfdDirectory value) {
    directories[ifdName] = value;
  }
}
