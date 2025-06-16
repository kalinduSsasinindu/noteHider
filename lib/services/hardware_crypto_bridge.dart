import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'dart:developer';
import 'package:local_auth/local_auth.dart';

/// Thin wrapper around platform-specific hardware-backed key wrapping.
/// On Android it talks to HardwareCrypto.kt via MethodChannel.
class HardwareCryptoBridge {
  HardwareCryptoBridge._();
  static const _channel = MethodChannel('notehider/integrity');
  static final HardwareCryptoBridge instance = HardwareCryptoBridge._();

  Future<String> wrapBytes(String alias, Uint8List plain) async {
    if (!Platform.isAndroid) {
      // TODO: iOS implementation via Secure Enclave
      return base64Encode(plain);
    }

    Future<String?> _tryWrap() => _channel.invokeMethod<String>('wrapBytes', {
          'alias': alias,
          'data': base64Encode(plain),
        });

    String? wrapped;
    try {
      wrapped = await _tryWrap();
    } on PlatformException catch (e) {
      if (e.message?.contains('User not authenticated') == true) {
        final localAuth = LocalAuthentication();
        final didAuth = await localAuth.authenticate(
            localizedReason: 'Authenticate to access secure storage',
            options: const AuthenticationOptions(
                biometricOnly: false, stickyAuth: true));
        if (didAuth) {
          wrapped = await _tryWrap();
        } else {
          throw e;
        }
      } else {
        throw e;
      }
    }
    assert(() {
      log('HardwareCryptoBridge.wrapBytes alias=$alias len=${plain.length} -> ${wrapped?.length ?? 0} b64');
      return true;
    }());
    if (wrapped == null) {
      throw PlatformException(code: 'WRAP_FAILED', message: 'Null response');
    }
    return wrapped;
  }

  Future<Uint8List> unwrapBytes(String alias, String wrappedB64) async {
    if (!Platform.isAndroid) {
      return Uint8List.fromList(base64Decode(wrappedB64));
    }

    Future<String?> _tryUnwrap() =>
        _channel.invokeMethod<String>('unwrapBytes', {
          'alias': alias,
          'data': wrappedB64,
        });

    String? plainB64;
    try {
      plainB64 = await _tryUnwrap();
    } on PlatformException catch (e) {
      if (e.message?.contains('User not authenticated') == true) {
        final localAuth = LocalAuthentication();
        final didAuth = await localAuth.authenticate(
            localizedReason: 'Authenticate to unlock secure key',
            options: const AuthenticationOptions(
                biometricOnly: false, stickyAuth: true));
        if (didAuth) {
          plainB64 = await _tryUnwrap();
        } else {
          throw e;
        }
      } else {
        throw e;
      }
    }
    assert(() {
      log('HardwareCryptoBridge.unwrapBytes alias=$alias inLen=${wrappedB64.length} -> out ${plainB64?.length ?? 0}');
      return true;
    }());
    if (plainB64 == null) {
      throw PlatformException(code: 'UNWRAP_FAILED', message: 'Null response');
    }
    return Uint8List.fromList(base64Decode(plainB64));
  }

  Future<String> computePepperTag(String password) async {
    final tag = await _channel.invokeMethod<String>('computePepperTag', {
      'password': password,
    });
    assert(() {
      log('HardwareCryptoBridge.computePepperTag lenPwd=${password.length} tagLen=${tag?.length ?? 0}');
      return true;
    }());
    if (tag == null) {
      throw PlatformException(code: 'PEPPER_FAILED', message: 'Null tag');
    }
    return tag;
  }
}
