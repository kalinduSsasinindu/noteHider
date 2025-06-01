/// 🌍 LOCATION VERIFICATION SERVICE
///
/// Provides military-grade location-based security with:
/// • Safe zone verification
/// • Geofencing and movement detection
/// • Location spoofing detection
/// • Emergency location tracking

import 'package:geolocator/geolocator.dart';
import 'package:notehider/models/security_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:math';

class LocationService {
  // Secure storage for location data
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Location tracking state
  bool _isInitialized = false;
  Position? _lastKnownPosition;
  List<SafeZone> _safeZones = [];
  DateTime? _lastLocationUpdate;
  int _suspiciousLocationCount = 0;

  // Constants
  static const String _safeZonesKey = 'location_safe_zones';
  static const String _lastPositionKey = 'last_known_position';
  static const String _locationHistoryKey = 'location_history';
  static const double _defaultAccuracyThreshold = 50.0; // meters
  static const int _maxSuspiciousLocations = 3;
  static const Duration _locationTimeout = Duration(seconds: 30);

  /// 🚀 INITIALIZE LOCATION SERVICE
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Check location permissions
      final permission = await _checkLocationPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        print('⚠️ Location permission not granted - service will be disabled');
        _isInitialized = true; // Initialize in disabled state
        return;
      }

      // Load saved data
      await _loadSafeZones();
      await _loadLastPosition();

      _isInitialized = true;
      print('🌍 Location service initialized successfully');
    } catch (e) {
      print('⚠️ Location service initialization failed: $e');
      print('📱 Location service will be disabled but app will continue');
      _isInitialized = true; // Initialize in disabled state
      // Don't rethrow - allow app to continue without location features
    }
  }

  /// 🔍 CHECK LOCATION PERMISSION
  Future<LocationPermission> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('📍 Location services are disabled on device');
      throw LocationException('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('🚫 Location permissions are denied by user');
        throw LocationException('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('🚫 Location permissions are permanently denied');
      throw LocationException('Location permissions are permanently denied');
    }

    print('✅ Location permissions granted: $permission');
    return permission;
  }

  /// 📍 GET CURRENT LOCATION
  Future<LocationResult> getCurrentLocation({
    SecurityLevel securityLevel = SecurityLevel.high,
    bool performAntiSpoofing = true,
  }) async {
    await _ensureInitialized();

    try {
      final locationSettings = _getLocationSettings(securityLevel);

      final position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      ).timeout(_locationTimeout);

      // Perform anti-spoofing checks
      if (performAntiSpoofing) {
        final spoofingResult = await _detectLocationSpoofing(position);
        if (!spoofingResult.isValid) {
          return LocationResult(
            success: false,
            position: null,
            errorType: LocationError.spoofingDetected,
            message: spoofingResult.reason,
            securityScore: 0.0,
          );
        }
      }

      // Update tracking data
      _lastKnownPosition = position;
      _lastLocationUpdate = DateTime.now();
      await _saveLastPosition();

      // Calculate security score
      final securityScore = _calculateLocationSecurityScore(position);

      return LocationResult(
        success: true,
        position: position,
        errorType: LocationError.none,
        message: 'Location retrieved successfully',
        securityScore: securityScore,
      );
    } catch (e) {
      return LocationResult(
        success: false,
        position: null,
        errorType: _mapLocationException(e),
        message: e.toString(),
        securityScore: 0.0,
      );
    }
  }

  /// 🛡️ VERIFY LOCATION AGAINST SAFE ZONES
  Future<LocationVerificationResult> verifyLocation({
    Position? position,
    SecurityLevel securityLevel = SecurityLevel.high,
  }) async {
    await _ensureInitialized();

    try {
      // Get current position if not provided
      position ??=
          (await getCurrentLocation(securityLevel: securityLevel)).position;

      if (position == null) {
        return LocationVerificationResult(
          isValid: false,
          inSafeZone: false,
          matchedZone: null,
          distance: null,
          securityScore: 0.0,
          message: 'Unable to get current location',
        );
      }

      // Check against safe zones
      for (final safeZone in _safeZones) {
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          safeZone.latitude,
          safeZone.longitude,
        );

        if (distance <= safeZone.radiusMeters) {
          // Location is within safe zone
          final securityScore = _calculateZoneSecurityScore(safeZone, distance);

          return LocationVerificationResult(
            isValid: true,
            inSafeZone: true,
            matchedZone: safeZone,
            distance: distance,
            securityScore: securityScore,
            message: 'Location verified in safe zone: ${safeZone.name}',
          );
        }
      }

      // Not in any safe zone
      return LocationVerificationResult(
        isValid: false,
        inSafeZone: false,
        matchedZone: null,
        distance: null,
        securityScore: 0.0,
        message: 'Location not in any configured safe zone',
      );
    } catch (e) {
      return LocationVerificationResult(
        isValid: false,
        inSafeZone: false,
        matchedZone: null,
        distance: null,
        securityScore: 0.0,
        message: 'Location verification failed: $e',
      );
    }
  }

  /// ➕ ADD SAFE ZONE
  Future<void> addSafeZone(SafeZone safeZone) async {
    await _ensureInitialized();

    _safeZones.add(safeZone);
    await _saveSafeZones();
    print('🛡️ Safe zone added: ${safeZone.name}');
  }

  /// ❌ REMOVE SAFE ZONE
  Future<void> removeSafeZone(String zoneId) async {
    await _ensureInitialized();

    _safeZones.removeWhere((zone) => zone.id == zoneId);
    await _saveSafeZones();
    print('🗑️ Safe zone removed: $zoneId');
  }

  /// 📋 GET ALL SAFE ZONES
  List<SafeZone> getSafeZones() => List.unmodifiable(_safeZones);

  /// 🔍 DETECT LOCATION SPOOFING
  Future<SpoofingDetectionResult> _detectLocationSpoofing(
      Position position) async {
    try {
      // Check accuracy
      if (position.accuracy > _defaultAccuracyThreshold * 2) {
        return SpoofingDetectionResult(
          isValid: false,
          reason: 'Location accuracy too low: ${position.accuracy}m',
          confidence: 0.8,
        );
      }

      // Check for impossible movement
      if (_lastKnownPosition != null && _lastLocationUpdate != null) {
        final distance = Geolocator.distanceBetween(
          _lastKnownPosition!.latitude,
          _lastKnownPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        final timeDiff = DateTime.now().difference(_lastLocationUpdate!);
        final maxPossibleDistance =
            timeDiff.inSeconds * 100; // 100 m/s max speed

        if (distance > maxPossibleDistance) {
          _suspiciousLocationCount++;
          return SpoofingDetectionResult(
            isValid: false,
            reason:
                'Impossible movement detected: ${distance}m in ${timeDiff.inSeconds}s',
            confidence: 0.9,
          );
        }
      }

      // Check for mock location (Android)
      if (position.isMocked) {
        return SpoofingDetectionResult(
          isValid: false,
          reason: 'Mock location detected',
          confidence: 1.0,
        );
      }

      // Reset suspicious count on valid location
      _suspiciousLocationCount = 0;

      return SpoofingDetectionResult(
        isValid: true,
        reason: 'Location appears genuine',
        confidence: 0.95,
      );
    } catch (e) {
      return SpoofingDetectionResult(
        isValid: false,
        reason: 'Spoofing detection failed: $e',
        confidence: 0.5,
      );
    }
  }

  /// 📊 CALCULATE LOCATION SECURITY SCORE
  double _calculateLocationSecurityScore(Position position) {
    double score = 1.0;

    // Accuracy factor (better accuracy = higher score)
    if (position.accuracy <= 5) {
      score *= 1.0;
    } else if (position.accuracy <= 10) {
      score *= 0.9;
    } else if (position.accuracy <= 20) {
      score *= 0.8;
    } else {
      score *= 0.6;
    }

    // Age factor (newer = higher score)
    final age = DateTime.now().millisecondsSinceEpoch -
        position.timestamp!.millisecondsSinceEpoch;
    if (age <= 5000) {
      // 5 seconds
      score *= 1.0;
    } else if (age <= 30000) {
      // 30 seconds
      score *= 0.9;
    } else {
      score *= 0.7;
    }

    // Suspicious location penalty
    if (_suspiciousLocationCount > 0) {
      score *= max(0.1, 1.0 - (_suspiciousLocationCount * 0.3));
    }

    return score;
  }

  /// 📊 CALCULATE ZONE SECURITY SCORE
  double _calculateZoneSecurityScore(SafeZone zone, double distance) {
    // Base score (default high security for safe zones)
    double score = 0.8;

    // Distance factor (closer to center = higher score)
    final distanceFactor = 1.0 - (distance / zone.radiusMeters);
    score *= distanceFactor;

    // WiFi requirement bonus
    if (zone.requiresWiFiSSID) {
      score *= 1.2; // 20% bonus for WiFi requirement
    }

    return score.clamp(0.0, 1.0);
  }

  /// ⚙️ GET LOCATION SETTINGS
  LocationSettings _getLocationSettings(SecurityLevel securityLevel) {
    switch (securityLevel) {
      case SecurityLevel.extreme:
        return const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 1,
        );
      case SecurityLevel.maximum:
        return const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 5,
        );
      case SecurityLevel.high:
        return const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        );
      default:
        return const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 50,
        );
    }
  }

  /// 🗂️ STORAGE METHODS
  Future<void> _loadSafeZones() async {
    try {
      final zonesJson = await _secureStorage.read(key: _safeZonesKey);
      if (zonesJson != null) {
        final zonesList = jsonDecode(zonesJson) as List;
        _safeZones = zonesList.map((json) => SafeZone.fromJson(json)).toList();
      }
    } catch (e) {
      print('⚠️ Failed to load safe zones: $e');
    }
  }

  Future<void> _saveSafeZones() async {
    try {
      final zonesJson =
          jsonEncode(_safeZones.map((zone) => zone.toJson()).toList());
      await _secureStorage.write(key: _safeZonesKey, value: zonesJson);
    } catch (e) {
      print('🚨 Failed to save safe zones: $e');
    }
  }

  Future<void> _loadLastPosition() async {
    try {
      final positionJson = await _secureStorage.read(key: _lastPositionKey);
      if (positionJson != null) {
        final data = jsonDecode(positionJson);
        _lastKnownPosition = Position(
          latitude: data['latitude'],
          longitude: data['longitude'],
          timestamp: DateTime.parse(data['timestamp']),
          accuracy: data['accuracy'],
          altitude: data['altitude'],
          altitudeAccuracy: data['altitudeAccuracy'],
          heading: data['heading'],
          headingAccuracy: data['headingAccuracy'],
          speed: data['speed'],
          speedAccuracy: data['speedAccuracy'],
          isMocked: data['isMocked'] ?? false,
        );
        _lastLocationUpdate = DateTime.parse(data['lastUpdate']);
      }
    } catch (e) {
      print('⚠️ Failed to load last position: $e');
    }
  }

  Future<void> _saveLastPosition() async {
    if (_lastKnownPosition == null) return;

    try {
      final data = {
        'latitude': _lastKnownPosition!.latitude,
        'longitude': _lastKnownPosition!.longitude,
        'timestamp': _lastKnownPosition!.timestamp!.toIso8601String(),
        'accuracy': _lastKnownPosition!.accuracy,
        'altitude': _lastKnownPosition!.altitude,
        'altitudeAccuracy': _lastKnownPosition!.altitudeAccuracy,
        'heading': _lastKnownPosition!.heading,
        'headingAccuracy': _lastKnownPosition!.headingAccuracy,
        'speed': _lastKnownPosition!.speed,
        'speedAccuracy': _lastKnownPosition!.speedAccuracy,
        'isMocked': _lastKnownPosition!.isMocked,
        'lastUpdate': _lastLocationUpdate!.toIso8601String(),
      };

      await _secureStorage.write(
          key: _lastPositionKey, value: jsonEncode(data));
    } catch (e) {
      print('🚨 Failed to save last position: $e');
    }
  }

  /// 🔧 UTILITY METHODS
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// 📊 CHECK IF LOCATION SERVICE IS AVAILABLE
  Future<bool> isLocationServiceAvailable() async {
    if (!_isInitialized) return false;

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      print('⚠️ Error checking location service availability: $e');
      return false;
    }
  }

  /// 📍 GET SERVICE STATUS
  Future<Map<String, dynamic>> getServiceStatus() async {
    final isAvailable = await isLocationServiceAvailable();
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    final permission = await Geolocator.checkPermission();

    return {
      'initialized': _isInitialized,
      'available': isAvailable,
      'serviceEnabled': serviceEnabled,
      'permission': permission.name,
      'safeZonesCount': _safeZones.length,
      'lastUpdate': _lastLocationUpdate?.toIso8601String(),
    };
  }

  LocationError _mapLocationException(dynamic e) {
    if (e is LocationServiceDisabledException) {
      return LocationError.serviceDisabled;
    } else if (e is PermissionDeniedException) {
      return LocationError.permissionDenied;
    } else if (e.toString().contains('timeout')) {
      return LocationError.timeout;
    } else {
      return LocationError.unknown;
    }
  }
}

/// 🚨 LOCATION ERROR TYPES
enum LocationError {
  none,
  serviceDisabled,
  permissionDenied,
  timeout,
  spoofingDetected,
  unknown,
}

/// 📍 LOCATION RESULT
class LocationResult {
  final bool success;
  final Position? position;
  final LocationError errorType;
  final String message;
  final double securityScore;

  LocationResult({
    required this.success,
    required this.position,
    required this.errorType,
    required this.message,
    required this.securityScore,
  });
}

/// 🛡️ LOCATION VERIFICATION RESULT
class LocationVerificationResult {
  final bool isValid;
  final bool inSafeZone;
  final SafeZone? matchedZone;
  final double? distance;
  final double securityScore;
  final String message;

  LocationVerificationResult({
    required this.isValid,
    required this.inSafeZone,
    required this.matchedZone,
    required this.distance,
    required this.securityScore,
    required this.message,
  });
}

/// 🔍 SPOOFING DETECTION RESULT
class SpoofingDetectionResult {
  final bool isValid;
  final String reason;
  final double confidence;

  SpoofingDetectionResult({
    required this.isValid,
    required this.reason,
    required this.confidence,
  });
}

/// 🚨 LOCATION EXCEPTION
class LocationException implements Exception {
  final String message;
  LocationException(this.message);

  @override
  String toString() => 'LocationException: $message';
}
