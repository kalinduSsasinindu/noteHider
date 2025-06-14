/// 📁 FILE MANAGEMENT MODELS
///
/// Data models for secure file storage and management:
/// • FileMetadata - Complete file information
/// • FileCategory - Organization system
/// • FileType - File classification
/// • ImportResult - File import tracking
/// • StorageStats - Usage analytics

import 'dart:typed_data';

/// 📄 FILE TYPE CLASSIFICATION
enum FileType {
  image,
  video,
  document,
  audio,
  archive,
  text,
  other,
}

/// 🔒 FILE SECURITY LEVEL
enum FileSecurityLevel {
  basic,
  standard,
  high,
  military,
  extreme,
}

/// 📊 FILE STATUS
enum FileStatus {
  stored,
  importing,
  exporting,
  corrupted,
  deleted,
  quarantined,
}

/// 📁 FILE METADATA
class FileMetadata {
  final String id;
  final String originalName;
  final String displayName;
  final String encryptedPath;
  final FileType type;
  final int sizeBytes;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final DateTime lastAccessedAt;
  final String? categoryId;
  final String? thumbnailPath;
  final FileSecurityLevel securityLevel;
  final FileStatus status;
  final String mimeType;
  final String fileHash;
  final bool isFavorite;
  final bool isHidden;
  final Map<String, dynamic> customProperties;
  final Map<String, dynamic> metadata;

  const FileMetadata({
    required this.id,
    required this.originalName,
    required this.displayName,
    required this.encryptedPath,
    required this.type,
    required this.sizeBytes,
    required this.createdAt,
    required this.modifiedAt,
    required this.lastAccessedAt,
    this.categoryId,
    this.thumbnailPath,
    this.securityLevel = FileSecurityLevel.standard,
    this.status = FileStatus.stored,
    required this.mimeType,
    required this.fileHash,
    this.isFavorite = false,
    this.isHidden = false,
    this.customProperties = const {},
    this.metadata = const {},
  });

  FileMetadata copyWith({
    String? id,
    String? originalName,
    String? displayName,
    String? encryptedPath,
    FileType? type,
    int? sizeBytes,
    DateTime? createdAt,
    DateTime? modifiedAt,
    DateTime? lastAccessedAt,
    String? categoryId,
    String? thumbnailPath,
    FileSecurityLevel? securityLevel,
    FileStatus? status,
    String? mimeType,
    String? fileHash,
    bool? isFavorite,
    bool? isHidden,
    Map<String, dynamic>? customProperties,
    Map<String, dynamic>? metadata,
  }) {
    return FileMetadata(
      id: id ?? this.id,
      originalName: originalName ?? this.originalName,
      displayName: displayName ?? this.displayName,
      encryptedPath: encryptedPath ?? this.encryptedPath,
      type: type ?? this.type,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      categoryId: categoryId ?? this.categoryId,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      securityLevel: securityLevel ?? this.securityLevel,
      status: status ?? this.status,
      mimeType: mimeType ?? this.mimeType,
      fileHash: fileHash ?? this.fileHash,
      isFavorite: isFavorite ?? this.isFavorite,
      isHidden: isHidden ?? this.isHidden,
      customProperties: customProperties ?? this.customProperties,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'originalName': originalName,
        'displayName': displayName,
        'encryptedPath': encryptedPath,
        'type': type.name,
        'sizeBytes': sizeBytes,
        'createdAt': createdAt.toIso8601String(),
        'modifiedAt': modifiedAt.toIso8601String(),
        'lastAccessedAt': lastAccessedAt.toIso8601String(),
        'categoryId': categoryId,
        'thumbnailPath': thumbnailPath,
        'securityLevel': securityLevel.name,
        'status': status.name,
        'mimeType': mimeType,
        'fileHash': fileHash,
        'isFavorite': isFavorite,
        'isHidden': isHidden,
        'customProperties': customProperties,
        'metadata': metadata,
      };

  factory FileMetadata.fromJson(Map<String, dynamic> json) {
    return FileMetadata(
      id: json['id'] ?? '',
      originalName: json['originalName'] ?? '',
      displayName: json['displayName'] ?? '',
      encryptedPath: json['encryptedPath'] ?? '',
      type: FileType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => FileType.other,
      ),
      sizeBytes: json['sizeBytes'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      modifiedAt: DateTime.parse(json['modifiedAt']),
      lastAccessedAt: DateTime.parse(json['lastAccessedAt']),
      categoryId: json['categoryId'],
      thumbnailPath: json['thumbnailPath'],
      securityLevel: FileSecurityLevel.values.firstWhere(
        (s) => s.name == json['securityLevel'],
        orElse: () => FileSecurityLevel.standard,
      ),
      status: FileStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => FileStatus.stored,
      ),
      mimeType: json['mimeType'] ?? '',
      fileHash: json['fileHash'] ?? '',
      isFavorite: json['isFavorite'] ?? false,
      isHidden: json['isHidden'] ?? false,
      customProperties:
          Map<String, dynamic>.from(json['customProperties'] ?? {}),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// 📏 GET FORMATTED FILE SIZE
  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024)
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    if (sizeBytes < 1024 * 1024 * 1024)
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// 🎨 GET FILE ICON
  String get icon {
    switch (type) {
      case FileType.image:
        return '🖼️';
      case FileType.video:
        return '🎥';
      case FileType.document:
        return '📄';
      case FileType.audio:
        return '🎵';
      case FileType.archive:
        return '📦';
      case FileType.text:
        return '📝';
      default:
        return '📁';
    }
  }

  /// 🔒 GET SECURITY BADGE
  String get securityBadge {
    switch (securityLevel) {
      case FileSecurityLevel.basic:
        return '🔓';
      case FileSecurityLevel.standard:
        return '🔒';
      case FileSecurityLevel.high:
        return '🔐';
      case FileSecurityLevel.military:
        return '🛡️';
      case FileSecurityLevel.extreme:
        return '🔒🔥';
    }
  }
}

/// 🏷️ FILE CATEGORY
class FileCategory {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String color;
  final int fileCount;
  final int totalSizeBytes;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final bool isDefault;
  final bool isHidden;
  final FileSecurityLevel securityLevel;
  final Map<String, dynamic> settings;

  const FileCategory({
    required this.id,
    required this.name,
    this.description = '',
    this.icon = '📁',
    this.color = '#FF9800',
    this.fileCount = 0,
    this.totalSizeBytes = 0,
    required this.createdAt,
    required this.modifiedAt,
    this.isDefault = false,
    this.isHidden = false,
    this.securityLevel = FileSecurityLevel.standard,
    this.settings = const {},
  });

  FileCategory copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    String? color,
    int? fileCount,
    int? totalSizeBytes,
    DateTime? createdAt,
    DateTime? modifiedAt,
    bool? isDefault,
    bool? isHidden,
    FileSecurityLevel? securityLevel,
    Map<String, dynamic>? settings,
  }) {
    return FileCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      fileCount: fileCount ?? this.fileCount,
      totalSizeBytes: totalSizeBytes ?? this.totalSizeBytes,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      isDefault: isDefault ?? this.isDefault,
      isHidden: isHidden ?? this.isHidden,
      securityLevel: securityLevel ?? this.securityLevel,
      settings: settings ?? this.settings,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'icon': icon,
        'color': color,
        'fileCount': fileCount,
        'totalSizeBytes': totalSizeBytes,
        'createdAt': createdAt.toIso8601String(),
        'modifiedAt': modifiedAt.toIso8601String(),
        'isDefault': isDefault,
        'isHidden': isHidden,
        'securityLevel': securityLevel.name,
        'settings': settings,
      };

  factory FileCategory.fromJson(Map<String, dynamic> json) {
    return FileCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '📁',
      color: json['color'] ?? '#FF9800',
      fileCount: json['fileCount'] ?? 0,
      totalSizeBytes: json['totalSizeBytes'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      modifiedAt: DateTime.parse(json['modifiedAt']),
      isDefault: json['isDefault'] ?? false,
      isHidden: json['isHidden'] ?? false,
      securityLevel: FileSecurityLevel.values.firstWhere(
        (s) => s.name == json['securityLevel'],
        orElse: () => FileSecurityLevel.standard,
      ),
      settings: Map<String, dynamic>.from(json['settings'] ?? {}),
    );
  }

  /// 📏 GET FORMATTED SIZE
  String get formattedSize {
    if (totalSizeBytes < 1024) return '$totalSizeBytes B';
    if (totalSizeBytes < 1024 * 1024)
      return '${(totalSizeBytes / 1024).toStringAsFixed(1)} KB';
    if (totalSizeBytes < 1024 * 1024 * 1024)
      return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(totalSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// 📥 FILE IMPORT RESULT
class FileImportResult {
  final bool success;
  final String? fileId;
  final FileMetadata? metadata;
  final String message;
  final Duration importDuration;
  final int originalSizeBytes;
  final int encryptedSizeBytes;
  final String? thumbnailPath;
  final Map<String, dynamic> details;

  const FileImportResult({
    required this.success,
    this.fileId,
    this.metadata,
    required this.message,
    required this.importDuration,
    this.originalSizeBytes = 0,
    this.encryptedSizeBytes = 0,
    this.thumbnailPath,
    this.details = const {},
  });

  Map<String, dynamic> toJson() => {
        'success': success,
        'fileId': fileId,
        'metadata': metadata?.toJson(),
        'message': message,
        'importDurationMs': importDuration.inMilliseconds,
        'originalSizeBytes': originalSizeBytes,
        'encryptedSizeBytes': encryptedSizeBytes,
        'thumbnailPath': thumbnailPath,
        'details': details,
      };
}

/// 📤 FILE EXPORT RESULT
class FileExportResult {
  final bool success;
  final String? exportPath;
  final String message;
  final Duration exportDuration;
  final int fileSizeBytes;
  final Map<String, dynamic> details;

  const FileExportResult({
    required this.success,
    this.exportPath,
    required this.message,
    required this.exportDuration,
    this.fileSizeBytes = 0,
    this.details = const {},
  });
}

/// 📊 STORAGE STATISTICS
class StorageStats {
  final int totalFiles;
  final int totalSizeBytes;
  final int availableSpaceBytes;
  final int usedSpaceBytes;
  final Map<FileType, int> fileTypeCount;
  final Map<FileType, int> fileTypeSizes;
  final Map<String, int> categorySizes;
  final DateTime lastUpdated;
  final int duplicateFiles;
  final int corruptedFiles;
  final int hiddenFiles;
  final double compressionRatio;

  const StorageStats({
    this.totalFiles = 0,
    this.totalSizeBytes = 0,
    this.availableSpaceBytes = 0,
    this.usedSpaceBytes = 0,
    this.fileTypeCount = const {},
    this.fileTypeSizes = const {},
    this.categorySizes = const {},
    required this.lastUpdated,
    this.duplicateFiles = 0,
    this.corruptedFiles = 0,
    this.hiddenFiles = 0,
    this.compressionRatio = 1.0,
  });

  /// 📈 GET USAGE PERCENTAGE
  double get usagePercentage {
    if (usedSpaceBytes == 0 || availableSpaceBytes == 0) return 0.0;
    return (usedSpaceBytes / (usedSpaceBytes + availableSpaceBytes)) * 100;
  }

  /// 📏 GET FORMATTED TOTAL SIZE
  String get formattedTotalSize {
    if (totalSizeBytes < 1024) return '$totalSizeBytes B';
    if (totalSizeBytes < 1024 * 1024)
      return '${(totalSizeBytes / 1024).toStringAsFixed(1)} KB';
    if (totalSizeBytes < 1024 * 1024 * 1024)
      return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(totalSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Map<String, dynamic> toJson() => {
        'totalFiles': totalFiles,
        'totalSizeBytes': totalSizeBytes,
        'availableSpaceBytes': availableSpaceBytes,
        'usedSpaceBytes': usedSpaceBytes,
        'fileTypeCount': fileTypeCount.map((k, v) => MapEntry(k.name, v)),
        'fileTypeSizes': fileTypeSizes.map((k, v) => MapEntry(k.name, v)),
        'categorySizes': categorySizes,
        'lastUpdated': lastUpdated.toIso8601String(),
        'duplicateFiles': duplicateFiles,
        'corruptedFiles': corruptedFiles,
        'hiddenFiles': hiddenFiles,
        'compressionRatio': compressionRatio,
      };

  factory StorageStats.fromJson(Map<String, dynamic> json) {
    return StorageStats(
      totalFiles: json['totalFiles'] ?? 0,
      totalSizeBytes: json['totalSizeBytes'] ?? 0,
      availableSpaceBytes: json['availableSpaceBytes'] ?? 0,
      usedSpaceBytes: json['usedSpaceBytes'] ?? 0,
      fileTypeCount: (json['fileTypeCount'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(
              FileType.values.firstWhere(
                (t) => t.name == k,
                orElse: () => FileType.other,
              ),
              v as int,
            ),
          ) ??
          {},
      fileTypeSizes: (json['fileTypeSizes'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(
              FileType.values.firstWhere(
                (t) => t.name == k,
                orElse: () => FileType.other,
              ),
              v as int,
            ),
          ) ??
          {},
      categorySizes: Map<String, int>.from(json['categorySizes'] ?? {}),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      duplicateFiles: json['duplicateFiles'] ?? 0,
      corruptedFiles: json['corruptedFiles'] ?? 0,
      hiddenFiles: json['hiddenFiles'] ?? 0,
      compressionRatio: (json['compressionRatio'] ?? 1.0).toDouble(),
    );
  }
}

/// 🔍 FILE SEARCH QUERY
class FileSearchQuery {
  final String? searchTerm;
  final List<FileType>? fileTypes;
  final List<String>? categoryIds;
  final FileSecurityLevel? minSecurityLevel;
  final DateTime? createdAfter;
  final DateTime? createdBefore;
  final int? minSizeBytes;
  final int? maxSizeBytes;
  final bool? isFavorite;
  final bool? isHidden;
  final String? sortBy;
  final bool sortAscending;
  final int limit;
  final int offset;

  const FileSearchQuery({
    this.searchTerm,
    this.fileTypes,
    this.categoryIds,
    this.minSecurityLevel,
    this.createdAfter,
    this.createdBefore,
    this.minSizeBytes,
    this.maxSizeBytes,
    this.isFavorite,
    this.isHidden,
    this.sortBy = 'modifiedAt',
    this.sortAscending = false,
    this.limit = 50,
    this.offset = 0,
  });
}

/// 🎯 FILE SEARCH RESULT
class FileSearchResult {
  final List<FileMetadata> files;
  final int totalCount;
  final int pageCount;
  final Duration searchDuration;
  final String query;
  final Map<String, dynamic> facets;

  const FileSearchResult({
    required this.files,
    required this.totalCount,
    required this.pageCount,
    required this.searchDuration,
    required this.query,
    this.facets = const {},
  });
}
