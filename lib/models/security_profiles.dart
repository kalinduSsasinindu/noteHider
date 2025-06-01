/// 🎖️ PREDEFINED SECURITY PROFILES
///
/// Factory class for creating standard security profiles with
/// predefined configurations for different security levels.

import 'security_config.dart';

class SecurityProfiles {
  SecurityProfiles._();

  /// 🟢 BASIC SECURITY PROFILE
  ///
  /// Balanced security and usability for everyday users
  /// - Low friction authentication
  /// - Basic device protection
  /// - Simple threat detection
  static SecurityProfile get basic => const SecurityProfile(
        type: SecurityProfileType.basic,
        name: 'Basic Security',
        description:
            'Balanced protection for everyday use with minimal friction',
        securityScore: 6.5,
        usabilityScore: 9.0,
        performanceImpact: 2.0,
        features: {
          SecurityFeatureType.biometricAuth: SecurityFeatureConfig(
            type: SecurityFeatureType.biometricAuth,
            enabled: true,
            level: SecurityLevel.basic,
            parameters: {
              'mode': 'optional',
              'fallbackToPassword': true,
              'timeoutSeconds': 30,
            },
            dependencies: [],
            userConfigurable: true,
          ),
          SecurityFeatureType.passwordComplexity: SecurityFeatureConfig(
            type: SecurityFeatureType.passwordComplexity,
            enabled: true,
            level: SecurityLevel.medium,
            parameters: {
              'minLength': 8,
              'requireSpecialChars': true,
              'requireNumbers': true,
              'requireUppercase': false,
            },
            dependencies: [],
            userConfigurable: true,
          ),
          SecurityFeatureType.autoLock: SecurityFeatureConfig(
            type: SecurityFeatureType.autoLock,
            enabled: true,
            level: SecurityLevel.basic,
            parameters: {
              'timeoutMinutes': 15,
              'lockOnAppSwitch': false,
              'lockOnScreenOff': true,
            },
            dependencies: [],
            userConfigurable: true,
          ),
          SecurityFeatureType.deviceBinding: SecurityFeatureConfig(
            type: SecurityFeatureType.deviceBinding,
            enabled: true,
            level: SecurityLevel.basic,
            parameters: {
              'strictMode': false,
              'allowDeviceChanges': true,
              'bindToHardware': false,
            },
            dependencies: [],
            userConfigurable: false,
          ),
          SecurityFeatureType.locationVerification: SecurityFeatureConfig(
            type: SecurityFeatureType.locationVerification,
            enabled: false,
            level: SecurityLevel.none,
            parameters: {},
            dependencies: [],
            userConfigurable: true,
          ),
          SecurityFeatureType.totpRequired: SecurityFeatureConfig(
            type: SecurityFeatureType.totpRequired,
            enabled: false,
            level: SecurityLevel.none,
            parameters: {},
            dependencies: [],
            userConfigurable: true,
          ),
          SecurityFeatureType.decoyFiles: SecurityFeatureConfig(
            type: SecurityFeatureType.decoyFiles,
            enabled: false,
            level: SecurityLevel.none,
            parameters: {},
            dependencies: [],
            userConfigurable: true,
          ),
          SecurityFeatureType.advancedTamperDetection:
              SecurityFeatureConfig(
            type: SecurityFeatureType.advancedTamperDetection,
            enabled: false,
            level: SecurityLevel.none,
            parameters: {},
            dependencies: [],
            userConfigurable: true,
          ),
          SecurityFeatureType.autoWipeOnTamper: SecurityFeatureConfig(
            type: SecurityFeatureType.autoWipeOnTamper,
            enabled: false,
            level: SecurityLevel.none,
            parameters: {},
            dependencies: [SecurityFeatureType.advancedTamperDetection],
            userConfigurable: true,
          ),
          SecurityFeatureType.remoteWipe: SecurityFeatureConfig(
            type: SecurityFeatureType.remoteWipe,
            enabled: false,
            level: SecurityLevel.none,
            parameters: {},
            dependencies: [],
            userConfigurable: true,
          ),
          SecurityFeatureType.malwareDetection: SecurityFeatureConfig(
            type: SecurityFeatureType.malwareDetection,
            enabled: false,
            level: SecurityLevel.none,
            parameters: {},
            dependencies: [],
            userConfigurable: true,
          ),
          SecurityFeatureType.behaviorMonitoring: SecurityFeatureConfig(
            type: SecurityFeatureType.behaviorMonitoring,
            enabled: false,
            level: SecurityLevel.none,
            parameters: {},
            dependencies: [],
            userConfigurable: true,
          ),
        },
      );

  /// 🟡 PROFESSIONAL SECURITY PROFILE
  ///
  /// Enhanced security for business and professional use
  /// - Multi-factor authentication options
  /// - Location-based protection
  /// - Basic threat monitoring
  static SecurityProfile get professional => const SecurityProfile(
        type: SecurityProfileType.professional,
        name: 'Professional Security',
        description: 'Enhanced protection for business and sensitive data',
        securityScore: 8.0,
        usabilityScore: 7.5,
        performanceImpact: 4.0,
        features: {
          SecurityFeatureType.biometricAuth: SecurityFeatureConfig(
            type: SecurityFeatureType.biometricAuth,
            enabled: true,
            level: SecurityLevel.high,
            parameters: {
              'mode': 'required',
              'fallbackToPassword': true,
              'timeoutSeconds': 15,
              'maxAttempts': 3,
            },
            dependencies: [],
            userConfigurable: true,
          ),
          SecurityFeatureType.passwordComplexity: SecurityFeatureConfig(
            type: SecurityFeatureType.passwordComplexity,
            enabled: true,
            level: SecurityLevel.high,
            parameters: {
              'minLength': 12,
              'requireSpecialChars': true,
              'requireNumbers': true,
              'requireUppercase': true,
              'requireLowercase': true,
            },
            dependencies: [],
            userConfigurable: true,
          ),
          SecurityFeatureType.autoLock: SecurityFeatureConfig(
            type: SecurityFeatureType.autoLock,
            enabled: true,
            level: SecurityLevel.medium,
            parameters: {
              'timeoutMinutes': 5,
              'lockOnAppSwitch': true,
              'lockOnScreenOff': true,
              'lockOnInactivity': true,
            },
            dependencies: [],
            userConfigurable: true,
          ),
          SecurityFeatureType.deviceBinding: SecurityFeatureConfig(
            type: SecurityFeatureType.deviceBinding,
            enabled: true,
            level: SecurityLevel.medium,
            parameters: {
              'strictMode': true,
              'allowDeviceChanges': false,
              'bindToHardware': true,
            },
            dependencies: [],
            userConfigurable: false,
          ),
          SecurityFeatureType.locationVerification: SecurityFeatureConfig(
            type: SecurityFeatureType.locationVerification,
            enabled: true,
            level: SecurityLevel.basic,
            parameters: {
              'mode': 'advisory',
              'safeZones': [],
              'radiusMeters': 100.0,
              'requireWifi': false,
            },
            dependencies: [],
            userConfigurable: true,
          ),
          SecurityFeatureType.totpRequired: SecurityFeatureConfig(
            type: SecurityFeatureType.totpRequired,
            enabled: false,
            level: SecurityLevel.none,
            parameters: {
              'optional': true,
              'windowSeconds': 30,
              'backupCodes': 10,
            },
            dependencies: [],
            userConfigurable: true,
          ),
          SecurityFeatureType.decoyFiles: SecurityFeatureConfig(
            type: SecurityFeatureType.decoyFiles,
            enabled: true,
            level: SecurityLevel.basic,
            parameters: {
              'complexity': 'basic',
              'count': 5,
              'types': ['document', 'image'],
              'alertOnAccess': true,
            },
            dependencies: [],
            userConfigurable: true,
          ),
          SecurityFeatureType.advancedTamperDetection:
              SecurityFeatureConfig(
            type: SecurityFeatureType.advancedTamperDetection,
            enabled: true,
            level: SecurityLevel.medium,
            parameters: {
              'rootDetection': true,
              'debugDetection': true,
              'emulatorDetection': true,
              'hookDetection': false,
            },
            dependencies: [],
            userConfigurable: true,
          ),
          SecurityFeatureType.autoWipeOnTamper: SecurityFeatureConfig(
            type: SecurityFeatureType.autoWipeOnTamper,
            enabled: false,
            level: SecurityLevel.none,
            parameters: {
              'confirmationRequired': true,
              'delaySeconds': 30,
            },
            dependencies: [SecurityFeatureType.advancedTamperDetection],
            userConfigurable: true,
          ),
          SecurityFeatureType.remoteWipe: SecurityFeatureConfig(
            type: SecurityFeatureType.remoteWipe,
            enabled: true,
            level: SecurityLevel.basic,
            parameters: {
              'channels': ['sms', 'email'],
              'authRequired': true,
              'confirmationRequired': true,
            },
            dependencies: [],
            userConfigurable: true,
          ),
          SecurityFeatureType.malwareDetection: SecurityFeatureConfig(
            type: SecurityFeatureType.malwareDetection,
            enabled: true,
            level: SecurityLevel.basic,
            parameters: {
              'intensity': 'basic',
              'scanFrequency': 'daily',
              'alertOnThreat': true,
            },
            dependencies: [],
            userConfigurable: true,
          ),
          SecurityFeatureType.behaviorMonitoring: SecurityFeatureConfig(
            type: SecurityFeatureType.behaviorMonitoring,
            enabled: true,
            level: SecurityLevel.basic,
            parameters: {
              'intensity': 'basic',
              'learningPeriodDays': 7,
              'alertThreshold': 'medium',
            },
            dependencies: [],
            userConfigurable: true,
          ),
        },
      );

  /// 🔴 MILITARY SECURITY PROFILE
  ///
  /// High-security configuration for sensitive environments
  /// - Mandatory multi-factor authentication
  /// - Comprehensive threat detection
  /// - Automatic security responses
  static SecurityProfile get military => const SecurityProfile(
        type: SecurityProfileType.military,
        name: 'Military Grade',
        description: 'Maximum security for highly sensitive operations',
        securityScore: 9.5,
        usabilityScore: 6.0,
        performanceImpact: 7.0,
        features: {
          SecurityFeatureType.biometricAuth:  SecurityFeatureConfig(
            type: SecurityFeatureType.biometricAuth,
            enabled: true,
            level: SecurityLevel.maximum,
            parameters: {
              'mode': 'requiredWithPassword',
              'fallbackToPassword': false,
              'timeoutSeconds': 10,
              'maxAttempts': 2,
              'antiSpoofing': true,
            },
            dependencies: [],
            userConfigurable: false,
          ),
          SecurityFeatureType.passwordComplexity:  SecurityFeatureConfig(
            type: SecurityFeatureType.passwordComplexity,
            enabled: true,
            level: SecurityLevel.maximum,
            parameters: {
              'minLength': 16,
              'requireSpecialChars': true,
              'requireNumbers': true,
              'requireUppercase': true,
              'requireLowercase': true,
              'prohibitCommonPasswords': true,
              'prohibitPersonalInfo': true,
            },
            dependencies: [],
            userConfigurable: false,
          ),
          SecurityFeatureType.autoLock:  SecurityFeatureConfig(
            type: SecurityFeatureType.autoLock,
            enabled: true,
            level: SecurityLevel.high,
            parameters: {
              'timeoutMinutes': 2,
              'lockOnAppSwitch': true,
              'lockOnScreenOff': true,
              'lockOnInactivity': true,
              'lockOnSuspiciousActivity': true,
            },
            dependencies: [],
            userConfigurable: false,
          ),
          SecurityFeatureType.deviceBinding:  SecurityFeatureConfig(
            type: SecurityFeatureType.deviceBinding,
            enabled: true,
            level: SecurityLevel.maximum,
            parameters: {
              'strictMode': true,
              'allowDeviceChanges': false,
              'bindToHardware': true,
              'requireSecureHardware': true,
            },
            dependencies: [],
            userConfigurable: false,
          ),
          SecurityFeatureType.locationVerification: SecurityFeatureConfig(
            type: SecurityFeatureType.locationVerification,
            enabled: true,
            level: SecurityLevel.high,
            parameters: {
              'mode': 'strict',
              'safeZones': [],
              'radiusMeters': 50.0,
              'requireWifi': true,
              'requireMultipleVerification': true,
            },
            dependencies: [],
            userConfigurable: true,
          ),
          SecurityFeatureType.totpRequired: SecurityFeatureConfig(
            type: SecurityFeatureType.totpRequired,
            enabled: true,
            level: SecurityLevel.high,
            parameters: {
              'optional': false,
              'windowSeconds': 30,
              'backupCodes': 20,
              'rotateSecret': true,
            },
            dependencies: [],
            userConfigurable: false,
          ),
          SecurityFeatureType.decoyFiles:  SecurityFeatureConfig(
            type: SecurityFeatureType.decoyFiles,
            enabled: true,
            level: SecurityLevel.high,
            parameters: {
              'complexity': 'advanced',
              'count': 20,
              'types': ['document', 'image', 'video'],
              'alertOnAccess': true,
              'realisticMetadata': true,
            },
            dependencies: [],
            userConfigurable: true,
          ),
          SecurityFeatureType.advancedTamperDetection:
               SecurityFeatureConfig(
            type: SecurityFeatureType.advancedTamperDetection,
            enabled: true,
            level: SecurityLevel.high,
            parameters: {
              'rootDetection': true,
              'debugDetection': true,
              'emulatorDetection': true,
              'hookDetection': true,
              'memoryProtection': true,
            },
            dependencies: [],
            userConfigurable: false,
          ),
          SecurityFeatureType.autoWipeOnTamper:  SecurityFeatureConfig(
            type: SecurityFeatureType.autoWipeOnTamper,
            enabled: true,
            level: SecurityLevel.high,
            parameters: {
              'confirmationRequired': false,
              'delaySeconds': 5,
              'multipassWipe': true,
            },
            dependencies: [SecurityFeatureType.advancedTamperDetection],
            userConfigurable: false,
          ),
          SecurityFeatureType.remoteWipe:  SecurityFeatureConfig(
            type: SecurityFeatureType.remoteWipe,
            enabled: true,
            level: SecurityLevel.high,
            parameters: {
              'channels': ['sms', 'email', 'push'],
              'authRequired': true,
              'confirmationRequired': false,
              'encryptedCommands': true,
            },
            dependencies: [],
            userConfigurable: true,
          ),
          SecurityFeatureType.malwareDetection:  SecurityFeatureConfig(
            type: SecurityFeatureType.malwareDetection,
            enabled: true,
            level: SecurityLevel.high,
            parameters: {
              'intensity': 'advanced',
              'scanFrequency': 'continuous',
              'alertOnThreat': true,
              'autoQuarantine': true,
            },
            dependencies: [],
            userConfigurable: false,
          ),
          SecurityFeatureType.behaviorMonitoring:  SecurityFeatureConfig(
            type: SecurityFeatureType.behaviorMonitoring,
            enabled: true,
            level: SecurityLevel.high,
            parameters: {
              'intensity': 'advanced',
              'learningPeriodDays': 14,
              'alertThreshold': 'low',
              'machineLearning': true,
            },
            dependencies: [],
            userConfigurable: false,
          ),
        },
      );

  /// 🟣 PARANOID SECURITY PROFILE
  ///
  /// Maximum security for extreme threat environments
  /// - Zero-tolerance security policies
  /// - Immediate threat responses
  /// - Advanced counter-surveillance
  static SecurityProfile get paranoid => const SecurityProfile(
        type: SecurityProfileType.paranoid,
        name: 'Paranoid Security',
        description: 'Extreme protection against nation-state level threats',
        securityScore: 10.0,
        usabilityScore: 4.0,
        performanceImpact: 9.0,
        features: {
          SecurityFeatureType.biometricAuth: SecurityFeatureConfig(
            type: SecurityFeatureType.biometricAuth,
            enabled: true,
            level: SecurityLevel.extreme,
            parameters: {
              'mode': 'requiredWithPassword',
              'fallbackToPassword': false,
              'timeoutSeconds': 5,
              'maxAttempts': 1,
              'antiSpoofing': true,
              'livenessDetection': true,
            },
            dependencies: [],
            userConfigurable: false,
          ),
          SecurityFeatureType.passwordComplexity: SecurityFeatureConfig(
            type: SecurityFeatureType.passwordComplexity,
            enabled: true,
            level: SecurityLevel.extreme,
            parameters: {
              'minLength': 24,
              'requireSpecialChars': true,
              'requireNumbers': true,
              'requireUppercase': true,
              'requireLowercase': true,
              'prohibitCommonPasswords': true,
              'prohibitPersonalInfo': true,
              'prohibitDictionaryWords': true,
              'requireEntropy': 80,
            },
            dependencies: [],
            userConfigurable: false,
          ),
          SecurityFeatureType.autoLock: SecurityFeatureConfig(
            type: SecurityFeatureType.autoLock,
            enabled: true,
            level: SecurityLevel.extreme,
            parameters: {
              'timeoutMinutes': 0.5, // 30 seconds
              'lockOnAppSwitch': true,
              'lockOnScreenOff': true,
              'lockOnInactivity': true,
              'lockOnSuspiciousActivity': true,
              'lockOnLocationChange': true,
            },
            dependencies: [],
            userConfigurable: false,
          ),
          SecurityFeatureType.deviceBinding: SecurityFeatureConfig(
            type: SecurityFeatureType.deviceBinding,
            enabled: true,
            level: SecurityLevel.extreme,
            parameters: {
              'strictMode': true,
              'allowDeviceChanges': false,
              'bindToHardware': true,
              'requireSecureHardware': true,
              'requireTEE': true,
            },
            dependencies: [],
            userConfigurable: false,
          ),
          SecurityFeatureType.locationVerification: SecurityFeatureConfig(
            type: SecurityFeatureType.locationVerification,
            enabled: true,
            level: SecurityLevel.extreme,
            parameters: {
              'mode': 'strict',
              'safeZones': [],
              'radiusMeters': 25.0,
              'requireWifi': true,
              'requireMultipleVerification': true,
              'requireCellTowerVerification': true,
            },
            dependencies: [],
            userConfigurable: false,
          ),
          SecurityFeatureType.totpRequired: SecurityFeatureConfig(
            type: SecurityFeatureType.totpRequired,
            enabled: true,
            level: SecurityLevel.extreme,
            parameters: {
              'optional': false,
              'windowSeconds': 30,
              'backupCodes': 50,
              'rotateSecret': true,
              'requireHardwareToken': true,
            },
            dependencies: [],
            userConfigurable: false,
          ),
          SecurityFeatureType.decoyFiles: SecurityFeatureConfig(
            type: SecurityFeatureType.decoyFiles,
            enabled: true,
            level: SecurityLevel.extreme,
            parameters: {
              'complexity': 'sophisticated',
              'count': 100,
              'types': ['document', 'image', 'video', 'audio'],
              'alertOnAccess': true,
              'realisticMetadata': true,
              'multiplePersonas': true,
              'aiGenerated': true,
            },
            dependencies: [],
            userConfigurable: false,
          ),
          SecurityFeatureType.advancedTamperDetection:
              SecurityFeatureConfig(
            type: SecurityFeatureType.advancedTamperDetection,
            enabled: true,
            level: SecurityLevel.extreme,
            parameters: {
              'rootDetection': true,
              'debugDetection': true,
              'emulatorDetection': true,
              'hookDetection': true,
              'memoryProtection': true,
              'sidechannelDetection': true,
              'physicalTamperDetection': true,
            },
            dependencies: [],
            userConfigurable: false,
          ),
          SecurityFeatureType.autoWipeOnTamper: SecurityFeatureConfig(
            type: SecurityFeatureType.autoWipeOnTamper,
            enabled: true,
            level: SecurityLevel.extreme,
            parameters: {
              'confirmationRequired': false,
              'delaySeconds': 0,
              'multipassWipe': true,
              'physicalDestruction': true,
            },
            dependencies: [SecurityFeatureType.advancedTamperDetection],
            userConfigurable: false,
          ),
          SecurityFeatureType.remoteWipe: SecurityFeatureConfig(
            type: SecurityFeatureType.remoteWipe,
            enabled: true,
            level: SecurityLevel.extreme,
            parameters: {
              'channels': ['sms', 'email', 'push', 'satellite'],
              'authRequired': true,
              'confirmationRequired': false,
              'encryptedCommands': true,
              'deadManSwitch': true,
            },
            dependencies: [],
            userConfigurable: false,
          ),
          SecurityFeatureType.malwareDetection: SecurityFeatureConfig(
            type: SecurityFeatureType.malwareDetection,
            enabled: true,
            level: SecurityLevel.extreme,
            parameters: {
              'intensity': 'realtime',
              'scanFrequency': 'continuous',
              'alertOnThreat': true,
              'autoQuarantine': true,
              'preventiveBlocking': true,
            },
            dependencies: [],
            userConfigurable: false,
          ),
          SecurityFeatureType.behaviorMonitoring: SecurityFeatureConfig(
            type: SecurityFeatureType.behaviorMonitoring,
            enabled: true,
            level: SecurityLevel.extreme,
            parameters: {
              'intensity': 'paranoid',
              'learningPeriodDays': 30,
              'alertThreshold': 'minimal',
              'machineLearning': true,
              'neuralNetworkAnalysis': true,
            },
            dependencies: [],
            userConfigurable: false,
          ),
          SecurityFeatureType.deadManSwitch: SecurityFeatureConfig(
            type: SecurityFeatureType.deadManSwitch,
            enabled: true,
            level: SecurityLevel.extreme,
            parameters: {
              'checkInIntervalHours': 24,
              'gracePeriodHours': 6,
              'wipeOnMissedCheckIn': true,
            },
            dependencies: [],
            userConfigurable: false,
          ),
          SecurityFeatureType.networkIsolation: SecurityFeatureConfig(
            type: SecurityFeatureType.networkIsolation,
            enabled: true,
            level: SecurityLevel.extreme,
            parameters: {
              'blockOnThreat': true,
              'whitelistOnly': true,
              'encryptAllTraffic': true,
            },
            dependencies: [],
            userConfigurable: false,
          ),
          SecurityFeatureType.antiForensics: SecurityFeatureConfig(
            type: SecurityFeatureType.antiForensics,
            enabled: true,
            level: SecurityLevel.extreme,
            parameters: {
              'memoryProtection': true,
              'antiDumping': true,
              'obfuscation': true,
              'runtimePacking': true,
            },
            dependencies: [],
            userConfigurable: false,
          ),
        },
      );

  /// 🎨 CUSTOM SECURITY PROFILE TEMPLATE
  ///
  /// Base template for user-customized security configurations
  static SecurityProfile get customTemplate => SecurityProfile(
        type: SecurityProfileType.custom,
        name: 'Custom Security',
        description: 'User-configured security settings',
        securityScore: 5.0,
        usabilityScore: 8.0,
        performanceImpact: 3.0,
        features: Map.fromEntries(
          SecurityFeatureType.values.map(
            (type) => MapEntry(
              type,
              SecurityFeatureConfig(
                type: type,
                enabled: false,
                level: SecurityLevel.basic,
                parameters: const {},
                dependencies: const [],
                userConfigurable: true,
              ),
            ),
          ),
        ),
      );

  /// 📋 GET ALL AVAILABLE PROFILES
  static List<SecurityProfile> get allProfiles => [
        basic,
        professional,
        military,
        paranoid,
      ];

  /// 🔍 GET PROFILE BY TYPE
  static SecurityProfile? getProfile(SecurityProfileType type) {
    switch (type) {
      case SecurityProfileType.basic:
        return basic;
      case SecurityProfileType.professional:
        return professional;
      case SecurityProfileType.military:
        return military;
      case SecurityProfileType.paranoid:
        return paranoid;
      case SecurityProfileType.custom:
        return customTemplate;
    }
  }

  /// 🎯 CALCULATE SECURITY SCORE
  static double calculateSecurityScore(SecurityProfile profile) {
    double totalScore = 0.0;
    int enabledFeatures = 0;

    for (final feature in profile.features.values) {
      if (feature.enabled) {
        enabledFeatures++;
        switch (feature.level) {
          case SecurityLevel.none:
            totalScore += 0.0;
            break;
          case SecurityLevel.basic:
            totalScore += 1.0;
            break;
          case SecurityLevel.medium:
            totalScore += 2.0;
            break;
          case SecurityLevel.high:
            totalScore += 3.0;
            break;
          case SecurityLevel.maximum:
            totalScore += 4.0;
            break;
          case SecurityLevel.extreme:
            totalScore += 5.0;
            break;
        }
      }
    }

    if (enabledFeatures == 0) return 0.0;

    // Normalize to 0-10 scale
    final maxPossibleScore = SecurityFeatureType.values.length * 5.0;
    return (totalScore / maxPossibleScore) * 10.0;
  }

  /// 📊 CALCULATE USABILITY SCORE
  static double calculateUsabilityScore(SecurityProfile profile) {
    double usabilityImpact = 0.0;
    int totalFeatures = 0;

    for (final feature in profile.features.values) {
      if (feature.enabled) {
        totalFeatures++;
        switch (feature.level) {
          case SecurityLevel.none:
            usabilityImpact += 0.0;
            break;
          case SecurityLevel.basic:
            usabilityImpact += 0.5;
            break;
          case SecurityLevel.medium:
            usabilityImpact += 1.0;
            break;
          case SecurityLevel.high:
            usabilityImpact += 2.0;
            break;
          case SecurityLevel.maximum:
            usabilityImpact += 3.5;
            break;
          case SecurityLevel.extreme:
            usabilityImpact += 5.0;
            break;
        }
      }
    }

    if (totalFeatures == 0) return 10.0;

    // Higher security impact means lower usability
    final averageImpact = usabilityImpact / totalFeatures;
    return 10.0 - (averageImpact * 2.0).clamp(0.0, 10.0);
  }

  /// ⚡ CALCULATE PERFORMANCE IMPACT
  static double calculatePerformanceImpact(SecurityProfile profile) {
    double performanceImpact = 0.0;

    for (final feature in profile.features.values) {
      if (feature.enabled) {
        switch (feature.type) {
          case SecurityFeatureType.biometricAuth:
            performanceImpact += 0.5;
            break;
          case SecurityFeatureType.passwordComplexity:
            performanceImpact += 0.1;
            break;
          case SecurityFeatureType.autoLock:
            performanceImpact += 0.1;
            break;
          case SecurityFeatureType.deviceBinding:
            performanceImpact += 0.5;
            break;
          case SecurityFeatureType.locationVerification:
            performanceImpact += 1.0;
            break;
          case SecurityFeatureType.totpRequired:
            performanceImpact += 0.2;
            break;
          case SecurityFeatureType.decoyFiles:
            performanceImpact += 1.5;
            break;
          case SecurityFeatureType.advancedTamperDetection:
            performanceImpact += 2.0;
            break;
          case SecurityFeatureType.autoWipeOnTamper:
            performanceImpact += 0.5;
            break;
          case SecurityFeatureType.remoteWipe:
            performanceImpact += 0.3;
            break;
          case SecurityFeatureType.malwareDetection:
            performanceImpact += 3.0;
            break;
          case SecurityFeatureType.behaviorMonitoring:
            performanceImpact += 2.5;
            break;
          case SecurityFeatureType.deadManSwitch:
            performanceImpact += 0.5;
            break;
          case SecurityFeatureType.networkIsolation:
            performanceImpact += 1.0;
            break;
          case SecurityFeatureType.antiForensics:
            performanceImpact += 4.0;
            break;
        }
      }
    }

    return performanceImpact.clamp(0.0, 10.0);
  }
}
