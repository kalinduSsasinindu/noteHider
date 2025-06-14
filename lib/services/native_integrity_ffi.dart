import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

/// Loads the native_crypto_library and exposes the quick integrity probe.
class NativeIntegrity {
  NativeIntegrity._();
  static final NativeIntegrity instance = NativeIntegrity._();

  late final DynamicLibrary _lib = _loadLib();
  late final int Function() _probe = _lib
      .lookup<NativeFunction<Uint32 Function()>>("quick_probe_native")
      .asFunction();

  DynamicLibrary _loadLib() {
    const libName = "native_crypto_library";
    if (Platform.isAndroid || Platform.isLinux) {
      return DynamicLibrary.open("lib$libName.so");
    } else if (Platform.isWindows) {
      return DynamicLibrary.open("$libName.dll");
    } else if (Platform.isMacOS) {
      return DynamicLibrary.open("lib$libName.dylib");
    } else if (Platform.isIOS) {
      return DynamicLibrary.process();
    }
    throw UnsupportedError("Unsupported platform for native integrity");
  }

  /// Returns bitmask of integrity flags. 0 means clean.
  int probe() => _probe();
}
