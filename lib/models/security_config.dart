/// 🛡️ SECURITY CONFIGURATION DATA MODELS
///
/// Defines the structure for configurable security features,
/// profiles, and user preferences for the military-grade security system.

import 'package:flutter/foundation.dart';

/// 🎖️ SECURITY PROFILE LEVELS
enum SecurityProfileType {
  basic,
  professional,
  military,
  paranoid,
  custom,
}

/// 🔒 SECURITY FEATURE TYPES
enum SecurityFeatureType {
  biometricAuth,
  passwordComplexity,
  autoLock,
  deviceBinding,
  locationVerification,
  totpRequired,
  decoyFiles,
  advancedTamperDetection,
  autoWipeOnTamper,
  remoteWipe,
  malwareDetection,
  behaviorMonitoring,
  deadManSwitch,
  networkIsolation,
  antiForensics,
}

/// 🎯 SECURITY LEVELS
enum SecurityLevel {
  none,
  basic,
  medium,
  high,
  maximum,
  extreme,
}

/// 🚨 THREAT RESPONSE TYPES
enum SecurityResponse {
  log,
  warn,
  lockdown,
  wipe,
  alert,
}

/// 🔐 BIOMETRIC MODES
enum BiometricMode {
  optional,
  required,
  requiredWithPassword,
  disabled,
}

/// 📍 LOCATION VERIFICATION MODES
enum LocationMode {
  disabled,
  advisory,
  required,
  strict,
}

/// 🎭 DECOY FILE COMPLEXITY
enum DecoyComplexity {
  none,
  basic,
  advanced,
  sophisticated,
}

/// 🕵️ MONITORING INTENSITY
enum MonitoringIntensity {
  disabled,
  basic,
  medium,
  advanced,
  paranoid,
  realtime,
}

/// 🔧 INDIVIDUAL SECURITY FEATURE CONFIGURATION
class SecurityFeatureConfig {
  final SecurityFeatureType type;
  final bool enabled;
  final SecurityLevel level;
  final Map<String, dynamic> parameters;
  final List<SecurityFeatureType> dependencies;
  final bool userConfigurable;

  const SecurityFeatureConfig({
    required this.type,
    required this.enabled,
    required this.level,
    this.parameters = const {},
    this.dependencies = const [],
    this.userConfigurable = true,
  });

  SecurityFeatureConfig copyWith({
    SecurityFeatureType? type,
    bool? enabled,
    SecurityLevel? level,
    Map<String, dynamic>? parameters,
    List<SecurityFeatureType>? dependencies,
    bool? userConfigurable,
  }) {
    return SecurityFeatureConfig(
      type: type ?? this.type,
      enabled: enabled ?? this.enabled,
      level: level ?? this.level,
      parameters: parameters ?? Map.from(this.parameters),
      dependencies: dependencies ?? List.from(this.dependencies),
      userConfigurable: userConfigurable ?? this.userConfigurable,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'enabled': enabled,
        'level': level.name,
        'parameters': parameters,
        'dependencies': dependencies.map((d) => d.name).toList(),
        'userConfigurable': userConfigurable,
      };

  factory SecurityFeatureConfig.fromJson(Map<String, dynamic> json) {
    return SecurityFeatureConfig(
      type: SecurityFeatureType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => SecurityFeatureType.biometricAuth,
      ),
      enabled: json['enabled'] ?? false,
      level: SecurityLevel.values.firstWhere(
        (l) => l.name == json['level'],
        orElse: () => SecurityLevel.basic,
      ),
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
      dependencies: (json['dependencies'] as List<dynamic>?)
              ?.map((d) => SecurityFeatureType.values.firstWhere(
                    (t) => t.name == d,
                    orElse: () => SecurityFeatureType.biometricAuth,
                  ))
              .toList() ??
          [],
      userConfigurable: json['userConfigurable'] ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SecurityFeatureConfig &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          enabled == other.enabled &&
          level == other.level &&
          mapEquals(parameters, other.parameters);

  @override
  int get hashCode => Object.hash(type, enabled, level, parameters);
}

/// 🎖️ SECURITY PROFILE DEFINITION
class SecurityProfile {
  final SecurityProfileType type;
  final String name;
  final String description;
  final Map<SecurityFeatureType, SecurityFeatureConfig> features;
  final double securityScore;
  final double usabilityScore;
  final double performanceImpact;

  const SecurityProfile({
    required this.type,
    required this.name,
    required this.description,
    required this.features,
    required this.securityScore,
    required this.usabilityScore,
    required this.performanceImpact,
  });

  SecurityProfile copyWith({
    SecurityProfileType? type,
    String? name,
    String? description,
    Map<SecurityFeatureType, SecurityFeatureConfig>? features,
    double? securityScore,
    double? usabilityScore,
    double? performanceImpact,
  }) {
    return SecurityProfile(
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      features: features ?? Map.from(this.features),
      securityScore: securityScore ?? this.securityScore,
      usabilityScore: usabilityScore ?? this.usabilityScore,
      performanceImpact: performanceImpact ?? this.performanceImpact,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'name': name,
        'description': description,
        'features': features.map(
          (key, value) => MapEntry(key.name, value.toJson()),
        ),
        'securityScore': securityScore,
        'usabilityScore': usabilityScore,
        'performanceImpact': performanceImpact,
      };

  factory SecurityProfile.fromJson(Map<String, dynamic> json) {
    final featuresJson = json['features'] as Map<String, dynamic>? ?? {};
    final features = <SecurityFeatureType, SecurityFeatureConfig>{};

    for (final entry in featuresJson.entries) {
      final featureType = SecurityFeatureType.values.firstWhere(
        (t) => t.name == entry.key,
        orElse: () => SecurityFeatureType.biometricAuth,
      );
      features[featureType] = SecurityFeatureConfig.fromJson(entry.value);
    }

    return SecurityProfile(
      type: SecurityProfileType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => SecurityProfileType.basic,
      ),
      name: json['name'] ?? 'Unknown',
      description: json['description'] ?? '',
      features: features,
      securityScore: (json['securityScore'] ?? 0.0).toDouble(),
      usabilityScore: (json['usabilityScore'] ?? 0.0).toDouble(),
      performanceImpact: (json['performanceImpact'] ?? 0.0).toDouble(),
    );
  }

  /// Get specific feature configuration
  SecurityFeatureConfig? getFeature(SecurityFeatureType type) {
    return features[type];
  }

  /// Check if a feature is enabled
  bool isFeatureEnabled(SecurityFeatureType type) {
    return features[type]?.enabled ?? false;
  }

  /// Get feature level
  SecurityLevel getFeatureLevel(SecurityFeatureType type) {
    return features[type]?.level ?? SecurityLevel.none;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SecurityProfile &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          name == other.name &&
          mapEquals(features, other.features);

  @override
  int get hashCode => Object.hash(type, name, features);
}

/// 🔧 MAIN SECURITY CONFIGURATION
class SecurityConfig {
  final SecurityProfile currentProfile;
  final DateTime lastUpdated;
  final bool autoUpgrade;
  final bool gracefulDegradation;
  final bool userNotifications;
  final Map<String, dynamic> globalSettings;

  const SecurityConfig({
    required this.currentProfile,
    required this.lastUpdated,
    this.autoUpgrade = false,
    this.gracefulDegradation = true,
    this.userNotifications = true,
    this.globalSettings = const {},
  });

  SecurityConfig copyWith({
    SecurityProfile? currentProfile,
    DateTime? lastUpdated,
    bool? autoUpgrade,
    bool? gracefulDegradation,
    bool? userNotifications,
    Map<String, dynamic>? globalSettings,
  }) {
    return SecurityConfig(
      currentProfile: currentProfile ?? this.currentProfile,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      autoUpgrade: autoUpgrade ?? this.autoUpgrade,
      gracefulDegradation: gracefulDegradation ?? this.gracefulDegradation,
      userNotifications: userNotifications ?? this.userNotifications,
      globalSettings: globalSettings ?? Map.from(this.globalSettings),
    );
  }

  Map<String, dynamic> toJson() => {
        'currentProfile': currentProfile.toJson(),
        'lastUpdated': lastUpdated.toIso8601String(),
        'autoUpgrade': autoUpgrade,
        'gracefulDegradation': gracefulDegradation,
        'userNotifications': userNotifications,
        'globalSettings': globalSettings,
      };

  factory SecurityConfig.fromJson(Map<String, dynamic> json) {
    return SecurityConfig(
      currentProfile: SecurityProfile.fromJson(json['currentProfile']),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      autoUpgrade: json['autoUpgrade'] ?? false,
      gracefulDegradation: json['gracefulDegradation'] ?? true,
      userNotifications: json['userNotifications'] ?? true,
      globalSettings: Map<String, dynamic>.from(json['globalSettings'] ?? {}),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SecurityConfig &&
          runtimeType == other.runtimeType &&
          currentProfile == other.currentProfile &&
          lastUpdated == other.lastUpdated &&
          autoUpgrade == other.autoUpgrade &&
          gracefulDegradation == other.gracefulDegradation &&
          userNotifications == other.userNotifications;

  @override
  int get hashCode => Object.hash(
        currentProfile,
        lastUpdated,
        autoUpgrade,
        gracefulDegradation,
        userNotifications,
      );
}

/// 📍 SAFE ZONE CONFIGURATION
class SafeZone {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final List<TimeWindow> activeTimeWindows;
  final bool requiresWiFiSSID;
  final String? wifiSSID;

  const SafeZone({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.activeTimeWindows = const [],
    this.requiresWiFiSSID = false,
    this.wifiSSID,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters,
        'activeTimeWindows': activeTimeWindows.map((w) => w.toJson()).toList(),
        'requiresWiFiSSID': requiresWiFiSSID,
        'wifiSSID': wifiSSID,
      };

  factory SafeZone.fromJson(Map<String, dynamic> json) {
    return SafeZone(
      id: json['id'],
      name: json['name'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusMeters: (json['radiusMeters'] as num).toDouble(),
      activeTimeWindows: (json['activeTimeWindows'] as List<dynamic>?)
              ?.map((w) => TimeWindow.fromJson(w))
              .toList() ??
          [],
      requiresWiFiSSID: json['requiresWiFiSSID'] ?? false,
      wifiSSID: json['wifiSSID'],
    );
  }
}

/// ⏰ TIME WINDOW FOR SAFE ZONES
class TimeWindow {
  final int startHour; // 0-23
  final int startMinute; // 0-59
  final int endHour; // 0-23
  final int endMinute; // 0-59
  final List<int> daysOfWeek; // 1-7 (Monday-Sunday)

  const TimeWindow({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.daysOfWeek,
  });

  Map<String, dynamic> toJson() => {
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
        'daysOfWeek': daysOfWeek,
      };

  factory TimeWindow.fromJson(Map<String, dynamic> json) {
    return TimeWindow(
      startHour: json['startHour'],
      startMinute: json['startMinute'],
      endHour: json['endHour'],
      endMinute: json['endMinute'],
      daysOfWeek: List<int>.from(json['daysOfWeek']),
    );
  }
}

/// 🎯 SECURITY FEATURE RESULT
class SecurityResult {
  final bool success;
  final String message;
  final SecurityLevel threatLevel;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  SecurityResult({
    required this.success,
    required this.message,
    this.threatLevel = SecurityLevel.none,
    this.metadata = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  SecurityResult copyWith({
    bool? success,
    String? message,
    SecurityLevel? threatLevel,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
  }) {
    return SecurityResult(
      success: success ?? this.success,
      message: message ?? this.message,
      threatLevel: threatLevel ?? this.threatLevel,
      metadata: metadata ?? Map.from(this.metadata),
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'threatLevel': threatLevel.name,
        'metadata': metadata,
        'timestamp': timestamp.toIso8601String(),
      };

  factory SecurityResult.fromJson(Map<String, dynamic> json) {
    return SecurityResult(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      threatLevel: SecurityLevel.values.firstWhere(
        (l) => l.name == json['threatLevel'],
        orElse: () => SecurityLevel.none,
      ),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SecurityResult &&
          runtimeType == other.runtimeType &&
          success == other.success &&
          message == other.message &&
          threatLevel == other.threatLevel &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(success, message, threatLevel, timestamp);
}
