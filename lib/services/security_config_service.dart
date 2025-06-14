/// 🛡️ SECURITY CONFIGURATION SERVICE
///
/// Manages all security configurations, profiles, and provides
/// interfaces for changing security settings while integrating
/// with existing storage architecture.

import 'dart:convert';
import 'package:notehider/models/security_config.dart';
import 'package:notehider/models/security_profiles.dart';
import 'package:notehider/services/storage_service.dart';
import 'package:notehider/services/crypto_service.dart';

class SecurityConfigService {
  final StorageService _storageService;
  final CryptoService _cryptoService;

  SecurityConfig? _currentConfig;
  final List<SecurityConfigListener> _listeners = [];

  static const String _configKey = 'security_config_v1';
  static const String _profileKey = 'security_profile_v1';

  SecurityConfigService({
    required StorageService storageService,
    required CryptoService cryptoService,
  })  : _storageService = storageService,
        _cryptoService = cryptoService;

  /// 🚀 INITIALIZE SECURITY CONFIGURATION
  Future<void> initialize() async {
    try {
      await _storageService.initialize();
      await _loadConfiguration();

      // If no configuration exists, create default
      if (_currentConfig == null) {
        await _createDefaultConfiguration();
      }

      print('🛡️ Security configuration service initialized');
    } catch (e) {
      print('🚨 Security config initialization failed: $e');
      // Fallback to basic configuration
      await _createDefaultConfiguration();
    }
  }

  /// 📋 GET CURRENT CONFIGURATION
  SecurityConfig get currentConfig {
    return _currentConfig ?? _createBasicConfig();
  }

  /// 🎖️ GET CURRENT PROFILE
  SecurityProfile get currentProfile {
    return currentConfig.currentProfile;
  }

  /// 🔄 CHANGE SECURITY PROFILE
  Future<bool> changeProfile(SecurityProfileType profileType) async {
    try {
      print('🔄 Changing security profile to: ${profileType.name}');

      final newProfile = SecurityProfiles.getProfile(profileType);
      if (newProfile == null) {
        print('🚨 Unknown profile type: $profileType');
        return false;
      }

      // Validate profile can be applied
      final validationResult = await _validateProfile(newProfile);
      if (!validationResult.success) {
        print('🚨 Profile validation failed: ${validationResult.message}');
        return false;
      }

      // Create new configuration with new profile
      final newConfig = currentConfig.copyWith(
        currentProfile: newProfile,
        lastUpdated: DateTime.now(),
      );

      // Save configuration
      await _saveConfiguration(newConfig);
      _currentConfig = newConfig;

      // Notify listeners
      _notifyListeners(SecurityConfigEvent(
        type: SecurityConfigEventType.profileChanged,
        oldProfile: currentConfig.currentProfile,
        newProfile: newProfile,
      ));

      print('✅ Security profile changed successfully');
      return true;
    } catch (e) {
      print('🚨 Failed to change security profile: $e');
      return false;
    }
  }

  /// ⚙️ UPDATE FEATURE CONFIGURATION
  Future<bool> updateFeatureConfig(
    SecurityFeatureType featureType,
    SecurityFeatureConfig newConfig,
  ) async {
    try {
      print('⚙️ Updating feature: ${featureType.name}');

      // Validate feature configuration
      final validationResult =
          await _validateFeatureConfig(featureType, newConfig);
      if (!validationResult.success) {
        print('🚨 Feature validation failed: ${validationResult.message}');
        return false;
      }

      // Check dependencies
      if (newConfig.enabled) {
        final dependencyCheck = await _checkFeatureDependencies(newConfig);
        if (!dependencyCheck.success) {
          print('🚨 Dependency check failed: ${dependencyCheck.message}');
          return false;
        }
      }

      // Update current profile
      final updatedFeatures =
          Map<SecurityFeatureType, SecurityFeatureConfig>.from(
        currentProfile.features,
      );
      updatedFeatures[featureType] = newConfig;

      final updatedProfile = currentProfile.copyWith(features: updatedFeatures);

      // Recalculate profile scores
      final recalculatedProfile = updatedProfile.copyWith(
        securityScore: SecurityProfiles.calculateSecurityScore(updatedProfile),
        usabilityScore:
            SecurityProfiles.calculateUsabilityScore(updatedProfile),
        performanceImpact:
            SecurityProfiles.calculatePerformanceImpact(updatedProfile),
      );

      // Update configuration
      final newConfiguration = currentConfig.copyWith(
        currentProfile: recalculatedProfile,
        lastUpdated: DateTime.now(),
      );

      await _saveConfiguration(newConfiguration);
      _currentConfig = newConfiguration;

      // Notify listeners
      _notifyListeners(SecurityConfigEvent(
        type: SecurityConfigEventType.featureChanged,
        featureType: featureType,
        oldConfig: currentProfile.getFeature(featureType),
        newConfig: newConfig,
      ));

      print('✅ Feature configuration updated successfully');
      return true;
    } catch (e) {
      print('🚨 Failed to update feature config: $e');
      return false;
    }
  }

  /// 🔍 CHECK FEATURE AVAILABILITY
  Future<SecurityResult> checkFeatureAvailability(
      SecurityFeatureType featureType) async {
    switch (featureType) {
      case SecurityFeatureType.biometricAuth:
        return await _checkBiometricAvailability();
      case SecurityFeatureType.locationVerification:
        return await _checkLocationAvailability();
      case SecurityFeatureType.totpRequired:
        return SecurityResult(success: true, message: 'TOTP available');
      case SecurityFeatureType.deviceBinding:
        return SecurityResult(
            success: true, message: 'Device binding available');
      default:
        return SecurityResult(success: true, message: 'Feature available');
    }
  }

  /// 🎯 GET FEATURE CONFIGURATION
  SecurityFeatureConfig? getFeatureConfig(SecurityFeatureType featureType) {
    return currentProfile.getFeature(featureType);
  }

  /// ✅ CHECK IF FEATURE IS ENABLED
  bool isFeatureEnabled(SecurityFeatureType featureType) {
    return currentProfile.isFeatureEnabled(featureType);
  }

  /// 📊 GET SECURITY STATUS SUMMARY
  Map<String, dynamic> getSecurityStatusSummary() {
    return {
      'profileType': currentProfile.type.name,
      'securityScore': currentProfile.securityScore,
      'enabledFeatures': currentProfile.features.values
          .where((f) => f.enabled)
          .map((f) => f.type.name)
          .toList(),
      'lastUpdated': currentConfig.lastUpdated.toIso8601String(),
    };
  }

  /// 🔄 RESET TO DEFAULT CONFIGURATION
  Future<bool> resetToDefault() async {
    try {
      print('🔄 Resetting to default security configuration');
      await _createDefaultConfiguration();

      _notifyListeners(SecurityConfigEvent(
        type: SecurityConfigEventType.configReset,
      ));

      print('✅ Security configuration reset to default');
      return true;
    } catch (e) {
      print('🚨 Failed to reset configuration: $e');
      return false;
    }
  }

  /// 📤 EXPORT CONFIGURATION
  Future<Map<String, dynamic>> exportConfiguration() async {
    return {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'configuration': currentConfig.toJson(),
    };
  }

  /// 📥 IMPORT CONFIGURATION
  Future<bool> importConfiguration(Map<String, dynamic> configData) async {
    try {
      print('📥 Importing security configuration');

      final configJson = configData['configuration'] as Map<String, dynamic>;
      final importedConfig = SecurityConfig.fromJson(configJson);

      // Validate imported configuration
      final validationResult =
          await _validateProfile(importedConfig.currentProfile);
      if (!validationResult.success) {
        print('🚨 Imported configuration validation failed');
        return false;
      }

      await _saveConfiguration(importedConfig);
      _currentConfig = importedConfig;

      _notifyListeners(SecurityConfigEvent(
        type: SecurityConfigEventType.configImported,
      ));

      print('✅ Security configuration imported successfully');
      return true;
    } catch (e) {
      print('🚨 Failed to import configuration: $e');
      return false;
    }
  }

  /// 👂 ADD CONFIGURATION LISTENER
  void addListener(SecurityConfigListener listener) {
    _listeners.add(listener);
  }

  /// 🚫 REMOVE CONFIGURATION LISTENER
  void removeListener(SecurityConfigListener listener) {
    _listeners.remove(listener);
  }

  /// 🧹 DISPOSE
  void dispose() {
    _listeners.clear();
    _currentConfig = null;
  }

  // 🔒 PRIVATE METHODS

  /// Load configuration from storage
  Future<void> _loadConfiguration() async {
    try {
      final configJson = await _storageService.getSecurityState();
      if (configJson != null) {
        final configData = jsonDecode(configJson);
        _currentConfig = SecurityConfig.fromJson(configData);
        print('✅ Security configuration loaded');
      }
    } catch (e) {
      print('⚠️ Failed to load security configuration: $e');
    }
  }

  /// Save configuration to storage
  Future<void> _saveConfiguration(SecurityConfig config) async {
    try {
      final configJson = jsonEncode(config.toJson());
      await _storageService.storeSecurityState(configJson);
      print('✅ Security configuration saved');
    } catch (e) {
      print('🚨 Failed to save security configuration: $e');
      throw SecurityException('Failed to save security configuration: $e');
    }
  }

  /// Create default configuration
  Future<void> _createDefaultConfiguration() async {
    try {
      final defaultProfile = SecurityProfiles.basic;
      _currentConfig = SecurityConfig(
        currentProfile: defaultProfile,
        lastUpdated: DateTime.now(),
        autoUpgrade: false,
        gracefulDegradation: true,
        userNotifications: true,
      );

      await _saveConfiguration(_currentConfig!);
      print('✅ Default security configuration created');
    } catch (e) {
      print('🚨 Failed to create default configuration: $e');
      // Fallback to in-memory basic config
      _currentConfig = _createBasicConfig();
    }
  }

  /// Create basic configuration fallback
  SecurityConfig _createBasicConfig() {
    return SecurityConfig(
      currentProfile: SecurityProfiles.basic,
      lastUpdated: DateTime.now(),
    );
  }

  /// Validate security profile
  Future<SecurityResult> _validateProfile(SecurityProfile profile) async {
    try {
      // Check each enabled feature
      for (final feature in profile.features.values) {
        if (feature.enabled) {
          final availability = await checkFeatureAvailability(feature.type);
          if (!availability.success) {
            return SecurityResult(
              success: false,
              message:
                  'Feature ${feature.type.name} not available: ${availability.message}',
            );
          }

          // Check dependencies
          final dependencyCheck = await _checkFeatureDependencies(feature);
          if (!dependencyCheck.success) {
            return SecurityResult(
              success: false,
              message:
                  'Dependency check failed for ${feature.type.name}: ${dependencyCheck.message}',
            );
          }
        }
      }

      return SecurityResult(
          success: true, message: 'Profile validation successful');
    } catch (e) {
      return SecurityResult(
        success: false,
        message: 'Profile validation error: $e',
      );
    }
  }

  /// Validate feature configuration
  Future<SecurityResult> _validateFeatureConfig(
    SecurityFeatureType featureType,
    SecurityFeatureConfig config,
  ) async {
    // Check if feature is user configurable
    if (!config.userConfigurable && config.enabled) {
      // Only allow system to enable non-user-configurable features
      return SecurityResult(
        success: false,
        message: 'Feature ${featureType.name} is not user configurable',
      );
    }

    // Feature-specific validation
    switch (featureType) {
      case SecurityFeatureType.biometricAuth:
        if (config.enabled) {
          final availability = await _checkBiometricAvailability();
          if (!availability.success) {
            return SecurityResult(
              success: false,
              message: 'Biometric authentication not available',
            );
          }
        }
        break;
      case SecurityFeatureType.locationVerification:
        if (config.enabled) {
          final availability = await _checkLocationAvailability();
          if (!availability.success) {
            return SecurityResult(
              success: false,
              message: 'Location services not available',
            );
          }
        }
        break;
      default:
        break;
    }

    return SecurityResult(
        success: true, message: 'Feature configuration valid');
  }

  /// Check feature dependencies
  Future<SecurityResult> _checkFeatureDependencies(
      SecurityFeatureConfig config) async {
    for (final dependency in config.dependencies) {
      final dependencyConfig = currentProfile.getFeature(dependency);
      if (dependencyConfig == null || !dependencyConfig.enabled) {
        return SecurityResult(
          success: false,
          message: 'Required dependency ${dependency.name} is not enabled',
        );
      }
    }

    return SecurityResult(success: true, message: 'All dependencies satisfied');
  }

  /// Check biometric availability
  Future<SecurityResult> _checkBiometricAvailability() async {
    try {
      // This would integrate with local_auth plugin
      // For now, assume available on mobile platforms
      return SecurityResult(
          success: true, message: 'Biometric authentication available');
    } catch (e) {
      return SecurityResult(
        success: false,
        message: 'Biometric authentication not available: $e',
      );
    }
  }

  /// Check location availability
  Future<SecurityResult> _checkLocationAvailability() async {
    try {
      // This would integrate with location services
      // For now, assume available
      return SecurityResult(
          success: true, message: 'Location services available');
    } catch (e) {
      return SecurityResult(
        success: false,
        message: 'Location services not available: $e',
      );
    }
  }

  /// Notify all listeners of configuration changes
  void _notifyListeners(SecurityConfigEvent event) {
    for (final listener in _listeners) {
      try {
        listener(event);
      } catch (e) {
        print('🚨 Listener notification failed: $e');
      }
    }
  }
}

/// 📢 SECURITY CONFIGURATION EVENT
class SecurityConfigEvent {
  final SecurityConfigEventType type;
  final SecurityProfile? oldProfile;
  final SecurityProfile? newProfile;
  final SecurityFeatureType? featureType;
  final SecurityFeatureConfig? oldConfig;
  final SecurityFeatureConfig? newConfig;
  final String? message;

  SecurityConfigEvent({
    required this.type,
    this.oldProfile,
    this.newProfile,
    this.featureType,
    this.oldConfig,
    this.newConfig,
    this.message,
  });
}

/// 🎯 SECURITY CONFIGURATION EVENT TYPES
enum SecurityConfigEventType {
  profileChanged,
  featureChanged,
  configReset,
  configImported,
  validationFailed,
}

/// 👂 SECURITY CONFIGURATION LISTENER
typedef SecurityConfigListener = void Function(SecurityConfigEvent event);

/// 🚨 SECURITY EXCEPTION
class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}
