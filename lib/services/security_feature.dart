/// 🔒 SECURITY FEATURE FRAMEWORK
///
/// Abstract base class for all security features that provides
/// a common interface for enabling, disabling, and checking
/// security features.

import 'package:notehider/models/security_config.dart';

/// 🛡️ ABSTRACT SECURITY FEATURE
///
/// Base class that all security features must implement
abstract class SecurityFeature {
  final SecurityFeatureType type;
  final String name;
  final String description;

  SecurityFeature({
    required this.type,
    required this.name,
    required this.description,
  });

  /// Check if this feature is available on the current device
  Future<bool> canEnable();

  /// Enable this security feature
  Future<SecurityResult> enable(SecurityFeatureConfig config);

  /// Disable this security feature
  Future<SecurityResult> disable();

  /// Check the current status of this feature
  Future<SecurityResult> check();

  /// Get the current configuration of this feature
  SecurityFeatureConfig? get currentConfig;

  /// Check if this feature is currently enabled
  bool get isEnabled => currentConfig?.enabled ?? false;

  /// Check if this feature is user configurable
  bool get isUserConfigurable => currentConfig?.userConfigurable ?? true;

  /// Get feature-specific validation rules
  Future<SecurityResult> validateConfig(SecurityFeatureConfig config);

  /// Handle feature-specific parameter updates
  Future<SecurityResult> updateParameters(Map<String, dynamic> parameters);

  /// Get feature dependencies
  List<SecurityFeatureType> get dependencies => [];

  /// Get feature performance impact estimate (0.0 - 10.0)
  double get performanceImpact => 1.0;

  /// Get feature security benefit estimate (0.0 - 10.0)
  double get securityBenefit => 5.0;

  /// Get feature usability impact estimate (0.0 - 10.0, higher = more impact)
  double get usabilityImpact => 2.0;
}

/// 🔐 BIOMETRIC AUTHENTICATION FEATURE
class BiometricAuthFeature extends SecurityFeature {
  SecurityFeatureConfig? _config;

  BiometricAuthFeature()
      : super(
          type: SecurityFeatureType.biometricAuth,
          name: 'Biometric Authentication',
          description: 'Use fingerprint or face recognition for secure access',
        );

  @override
  SecurityFeatureConfig? get currentConfig => _config;

  @override
  double get performanceImpact => 0.5;

  @override
  double get securityBenefit => 8.0;

  @override
  double get usabilityImpact => 1.0;

  @override
  Future<bool> canEnable() async {
    try {
      // This would check if biometric hardware is available
      // For now, assume available on mobile platforms
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<SecurityResult> enable(SecurityFeatureConfig config) async {
    try {
      // Validate configuration
      final validation = await validateConfig(config);
      if (!validation.success) {
        return validation;
      }

      // Check device capability
      final canUse = await canEnable();
      if (!canUse) {
        return SecurityResult(
          success: false,
          message: 'Biometric hardware not available',
          threatLevel: SecurityLevel.none,
        );
      }

      _config = config;

      return SecurityResult(
        success: true,
        message: 'Biometric authentication enabled',
        threatLevel: SecurityLevel.none,
      );
    } catch (e) {
      return SecurityResult(
        success: false,
        message: 'Failed to enable biometric authentication: $e',
        threatLevel: SecurityLevel.medium,
      );
    }
  }

  @override
  Future<SecurityResult> disable() async {
    try {
      _config = _config?.copyWith(enabled: false);

      return SecurityResult(
        success: true,
        message: 'Biometric authentication disabled',
        threatLevel: SecurityLevel.none,
      );
    } catch (e) {
      return SecurityResult(
        success: false,
        message: 'Failed to disable biometric authentication: $e',
        threatLevel: SecurityLevel.basic,
      );
    }
  }

  @override
  Future<SecurityResult> check() async {
    try {
      if (!isEnabled) {
        return SecurityResult(
          success: true,
          message: 'Biometric authentication is disabled',
          threatLevel: SecurityLevel.none,
        );
      }

      final available = await canEnable();
      if (!available) {
        return SecurityResult(
          success: false,
          message: 'Biometric hardware no longer available',
          threatLevel: SecurityLevel.medium,
        );
      }

      return SecurityResult(
        success: true,
        message: 'Biometric authentication is operational',
        threatLevel: SecurityLevel.none,
      );
    } catch (e) {
      return SecurityResult(
        success: false,
        message: 'Biometric authentication check failed: $e',
        threatLevel: SecurityLevel.medium,
      );
    }
  }

  @override
  Future<SecurityResult> validateConfig(SecurityFeatureConfig config) async {
    if (config.type != SecurityFeatureType.biometricAuth) {
      return SecurityResult(
        success: false,
        message: 'Invalid configuration type for biometric authentication',
        threatLevel: SecurityLevel.none,
      );
    }

    // Validate mode parameter
    final mode = config.parameters['mode'] as String?;
    if (mode != null &&
        !['optional', 'required', 'requiredWithPassword'].contains(mode)) {
      return SecurityResult(
        success: false,
        message: 'Invalid biometric mode: $mode',
        threatLevel: SecurityLevel.none,
      );
    }

    return SecurityResult(
      success: true,
      message: 'Biometric configuration is valid',
      threatLevel: SecurityLevel.none,
    );
  }

  @override
  Future<SecurityResult> updateParameters(
      Map<String, dynamic> parameters) async {
    try {
      if (_config == null) {
        return SecurityResult(
          success: false,
          message: 'Biometric authentication not configured',
          threatLevel: SecurityLevel.none,
        );
      }

      final updatedConfig = _config!.copyWith(parameters: {
        ..._config!.parameters,
        ...parameters,
      });

      final validation = await validateConfig(updatedConfig);
      if (!validation.success) {
        return validation;
      }

      _config = updatedConfig;

      return SecurityResult(
        success: true,
        message: 'Biometric parameters updated',
        threatLevel: SecurityLevel.none,
      );
    } catch (e) {
      return SecurityResult(
        success: false,
        message: 'Failed to update biometric parameters: $e',
        threatLevel: SecurityLevel.basic,
      );
    }
  }
}

/// 📍 LOCATION VERIFICATION FEATURE
class LocationVerificationFeature extends SecurityFeature {
  SecurityFeatureConfig? _config;
  final List<SafeZone> _safeZones = [];

  LocationVerificationFeature()
      : super(
          type: SecurityFeatureType.locationVerification,
          name: 'Location Verification',
          description: 'Restrict access to specific geographic locations',
        );

  @override
  SecurityFeatureConfig? get currentConfig => _config;

  @override
  double get performanceImpact => 2.0;

  @override
  double get securityBenefit => 7.0;

  @override
  double get usabilityImpact => 3.0;

  @override
  Future<bool> canEnable() async {
    try {
      // This would check if location services are available
      // For now, assume available
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<SecurityResult> enable(SecurityFeatureConfig config) async {
    try {
      final validation = await validateConfig(config);
      if (!validation.success) {
        return validation;
      }

      final canUse = await canEnable();
      if (!canUse) {
        return SecurityResult(
          success: false,
          message: 'Location services not available',
          threatLevel: SecurityLevel.none,
        );
      }

      _config = config;

      return SecurityResult(
        success: true,
        message: 'Location verification enabled',
        threatLevel: SecurityLevel.none,
      );
    } catch (e) {
      return SecurityResult(
        success: false,
        message: 'Failed to enable location verification: $e',
        threatLevel: SecurityLevel.medium,
      );
    }
  }

  @override
  Future<SecurityResult> disable() async {
    try {
      _config = _config?.copyWith(enabled: false);

      return SecurityResult(
        success: true,
        message: 'Location verification disabled',
        threatLevel: SecurityLevel.none,
      );
    } catch (e) {
      return SecurityResult(
        success: false,
        message: 'Failed to disable location verification: $e',
        threatLevel: SecurityLevel.basic,
      );
    }
  }

  @override
  Future<SecurityResult> check() async {
    try {
      if (!isEnabled) {
        return SecurityResult(
          success: true,
          message: 'Location verification is disabled',
          threatLevel: SecurityLevel.none,
        );
      }

      final available = await canEnable();
      if (!available) {
        return SecurityResult(
          success: false,
          message: 'Location services no longer available',
          threatLevel: SecurityLevel.medium,
        );
      }

      // Check if current location is within safe zones
      // This would integrate with actual location services

      return SecurityResult(
        success: true,
        message: 'Location verification is operational',
        threatLevel: SecurityLevel.none,
      );
    } catch (e) {
      return SecurityResult(
        success: false,
        message: 'Location verification check failed: $e',
        threatLevel: SecurityLevel.medium,
      );
    }
  }

  @override
  Future<SecurityResult> validateConfig(SecurityFeatureConfig config) async {
    if (config.type != SecurityFeatureType.locationVerification) {
      return SecurityResult(
        success: false,
        message: 'Invalid configuration type for location verification',
        threatLevel: SecurityLevel.none,
      );
    }

    // Validate mode parameter
    final mode = config.parameters['mode'] as String?;
    if (mode != null &&
        !['disabled', 'advisory', 'required', 'strict'].contains(mode)) {
      return SecurityResult(
        success: false,
        message: 'Invalid location mode: $mode',
        threatLevel: SecurityLevel.none,
      );
    }

    return SecurityResult(
      success: true,
      message: 'Location verification configuration is valid',
      threatLevel: SecurityLevel.none,
    );
  }

  @override
  Future<SecurityResult> updateParameters(
      Map<String, dynamic> parameters) async {
    try {
      if (_config == null) {
        return SecurityResult(
          success: false,
          message: 'Location verification not configured',
          threatLevel: SecurityLevel.none,
        );
      }

      final updatedConfig = _config!.copyWith(parameters: {
        ..._config!.parameters,
        ...parameters,
      });

      final validation = await validateConfig(updatedConfig);
      if (!validation.success) {
        return validation;
      }

      _config = updatedConfig;

      return SecurityResult(
        success: true,
        message: 'Location verification parameters updated',
        threatLevel: SecurityLevel.none,
      );
    } catch (e) {
      return SecurityResult(
        success: false,
        message: 'Failed to update location parameters: $e',
        threatLevel: SecurityLevel.basic,
      );
    }
  }

  /// Add a safe zone
  Future<SecurityResult> addSafeZone(SafeZone zone) async {
    try {
      _safeZones.add(zone);
      return SecurityResult(
        success: true,
        message: 'Safe zone "${zone.name}" added',
        threatLevel: SecurityLevel.none,
      );
    } catch (e) {
      return SecurityResult(
        success: false,
        message: 'Failed to add safe zone: $e',
        threatLevel: SecurityLevel.basic,
      );
    }
  }

  /// Remove a safe zone
  Future<SecurityResult> removeSafeZone(String zoneId) async {
    try {
      _safeZones.removeWhere((zone) => zone.id == zoneId);
      return SecurityResult(
        success: true,
        message: 'Safe zone removed',
        threatLevel: SecurityLevel.none,
      );
    } catch (e) {
      return SecurityResult(
        success: false,
        message: 'Failed to remove safe zone: $e',
        threatLevel: SecurityLevel.basic,
      );
    }
  }

  /// Get all safe zones
  List<SafeZone> get safeZones => List.unmodifiable(_safeZones);
}

/// 🛡️ SECURITY FEATURE FACTORY
class SecurityFeatureFactory {
  static final Map<SecurityFeatureType, SecurityFeature> _features = {};

  /// Get or create a security feature instance
  static SecurityFeature getFeature(SecurityFeatureType type) {
    if (_features.containsKey(type)) {
      return _features[type]!;
    }

    late SecurityFeature feature;
    switch (type) {
      case SecurityFeatureType.biometricAuth:
        feature = BiometricAuthFeature();
        break;
      case SecurityFeatureType.locationVerification:
        feature = LocationVerificationFeature();
        break;
      default:
        throw UnsupportedError('Security feature $type not implemented');
    }

    _features[type] = feature;
    return feature;
  }

  /// Get all available features
  static List<SecurityFeature> getAllFeatures() {
    return SecurityFeatureType.values
        .where((type) => _isFeatureImplemented(type))
        .map((type) => getFeature(type))
        .toList();
  }

  /// Check if a feature is implemented
  static bool _isFeatureImplemented(SecurityFeatureType type) {
    switch (type) {
      case SecurityFeatureType.biometricAuth:
      case SecurityFeatureType.locationVerification:
        return true;
      default:
        return false; // Not implemented yet
    }
  }

  /// Clear all feature instances (for testing)
  static void clearFeatures() {
    _features.clear();
  }
}
