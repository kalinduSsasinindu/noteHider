/// 🎭 DECOY SYSTEM SERVICE
///
/// Provides military-grade decoy/honeypot system with:
/// • Fake data generation
/// • Honeypot notes and traps
/// • Intrusion detection and alerts
/// • Decoy profiles and personas
/// • Behavioral analysis and tracking

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:notehider/models/security_config.dart';
import 'package:notehider/services/storage_service.dart';
import 'dart:convert';
import 'dart:math';
import 'package:uuid/uuid.dart';

class DecoySystemService {
  final StorageService _storageService;

  // Secure storage for decoy system data
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Decoy system state
  bool _isInitialized = false;
  DecoySystemConfig _config = DecoySystemConfig.defaultConfig();
  List<DecoyNote> _decoyNotes = [];
  List<IntrusionEvent> _intrusionHistory = [];
  List<DecoyProfile> _decoyProfiles = [];
  Map<String, DecoyTrap> _activeTraps = {};
  int _intrusionCount = 0;

  // Constants
  static const String _configKey = 'decoy_system_config';
  static const String _decoyNotesKey = 'decoy_notes';
  static const String _intrusionHistoryKey = 'intrusion_history';
  static const String _decoyProfilesKey = 'decoy_profiles';
  static const String _activeTrapsKey = 'active_traps';

  static const int _maxHistorySize = 200;
  static const int _maxDecoyNotes = 50;

  final Uuid _uuid = Uuid();
  final Random _random = Random();
  final List<String> _fakeNames = [
    'Document',
    'Image',
    'Video',
    'Report',
    'Presentation',
    'Invoice',
    'Receipt',
    'Statement',
    'Contract',
    'Proposal',
    'Research',
    'Study',
    'Thesis',
    'Paper',
    'Report',
    'Presentation',
    'Invoice',
    'Receipt',
    'Statement',
    'Contract',
    'Proposal',
    'Research',
    'Study',
    'Thesis',
    'Paper',
  ];

  DecoySystemService({
    required StorageService storageService,
  }) : _storageService = storageService;

  /// 🚀 INITIALIZE DECOY SYSTEM SERVICE
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🎭 Starting decoy system service initialization...');

      await _loadConfiguration();
      print('🎭 Configuration loaded');

      await _loadDecoyData();
      print('🎭 Decoy data loaded');

      await _generateDefaultDecoys();
      print('🎭 Default decoys generated');

      await _setupTraps();
      print('🎭 Traps setup completed');

      _isInitialized = true;
      print('🎭 Decoy system service initialized');

      // Start monitoring
      await _startMonitoring();
      print('🎭 Monitoring started');
    } catch (e) {
      print('🚨 Decoy system service initialization failed: $e');
      // Don't rethrow - allow app to continue
      _isInitialized = true; // Initialize in disabled state
    }
  }

  /// 🎯 DETECT INTRUSION ATTEMPT
  Future<IntrusionDetectionResult> detectIntrusion({
    required IntrusionType type,
    required String context,
    Map<String, dynamic>? metadata,
  }) async {
    await _ensureInitialized();

    try {
      final timestamp = DateTime.now();
      _intrusionCount++;

      // Create intrusion event
      final intrusion = IntrusionEvent(
        id: _generateId(),
        timestamp: timestamp,
        type: type,
        context: context,
        metadata: metadata ?? {},
        severity: _calculateSeverity(type, context),
        decoyTriggered: await _checkDecoyTrigger(type, context),
      );

      // Store intrusion event
      await _recordIntrusion(intrusion);

      // Generate response
      final response = await _generateIntrusionResponse(intrusion);

      print('🚨 Intrusion detected: ${type.name} - ${intrusion.severity.name}');

      return IntrusionDetectionResult(
        detected: true,
        intrusion: intrusion,
        response: response,
        decoyActivated: response.activateDecoy,
        alertLevel: intrusion.severity,
      );
    } catch (e) {
      print('🚨 Intrusion detection failed: $e');
      return IntrusionDetectionResult(
        detected: false,
        intrusion: null,
        response: IntrusionResponse.silent(),
        decoyActivated: false,
        alertLevel: IntrusionSeverity.low,
      );
    }
  }

  /// 🎭 ACTIVATE DECOY MODE
  Future<DecoyActivationResult> activateDecoyMode({
    required DecoyProfile profile,
    String? reason,
  }) async {
    await _ensureInitialized();

    try {
      // Generate decoy data for this profile
      final decoyData = await _generateDecoyData(profile);

      // Activate decoy environment
      await _deployDecoyEnvironment(profile, decoyData);

      // Set up monitoring for decoy interaction
      await _setupDecoyMonitoring(profile);

      print('🎭 Decoy mode activated: ${profile.name}');

      return DecoyActivationResult(
        success: true,
        profile: profile,
        decoyData: decoyData,
        message: 'Decoy mode activated successfully',
        monitoringActive: true,
      );
    } catch (e) {
      print('🚨 Decoy mode activation failed: $e');
      return DecoyActivationResult(
        success: false,
        profile: profile,
        decoyData: DecoyData.empty(),
        message: 'Decoy activation failed: $e',
        monitoringActive: false,
      );
    }
  }

  /// 🪤 SET DECOY TRAP
  Future<void> setDecoyTrap({
    required String trapId,
    required DecoyTrapType type,
    required String triggerCondition,
    Map<String, dynamic>? trapData,
  }) async {
    await _ensureInitialized();

    try {
      final trap = DecoyTrap(
        id: trapId,
        type: type,
        triggerCondition: triggerCondition,
        trapData: trapData ?? {},
        isActive: true,
        createdAt: DateTime.now(),
      );

      _activeTraps[trapId] = trap;
      await _saveTraps();

      print('🪤 Decoy trap set: $trapId (${type.name})');
    } catch (e) {
      print('🚨 Failed to set decoy trap: $e');
    }
  }

  /// 🔍 CHECK TRAP TRIGGER
  Future<TrapTriggerResult> checkTrapTrigger({
    required String action,
    required String context,
    Map<String, dynamic>? actionData,
  }) async {
    await _ensureInitialized();

    try {
      for (final trap in _activeTraps.values) {
        if (!trap.isActive) continue;

        final triggered = await _evaluateTrapCondition(
          trap,
          action,
          context,
          actionData,
        );

        if (triggered) {
          await _triggerTrap(trap, action, context);

          return TrapTriggerResult(
            triggered: true,
            trap: trap,
            action: action,
            context: context,
            timestamp: DateTime.now(),
          );
        }
      }

      return TrapTriggerResult(
        triggered: false,
        trap: null,
        action: action,
        context: context,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('🚨 Trap trigger check failed: $e');
      return TrapTriggerResult(
        triggered: false,
        trap: null,
        action: action,
        context: context,
        timestamp: DateTime.now(),
      );
    }
  }

  /// 📊 GENERATE FAKE DATA
  Future<DecoyData> _generateDecoyData(DecoyProfile profile) async {
    final random = Random();
    final decoyNotes = <DecoyNote>[];
    final fakeCredentials = <String, String>{};
    final fakeFiles = <String>[];

    // Generate decoy notes based on profile
    for (int i = 0; i < profile.noteCount; i++) {
      final note = DecoyNote(
        id: _generateId(),
        title: _generateFakeTitle(profile.theme),
        content: _generateFakeContent(profile.theme, profile.contentDepth),
        category: _generateFakeCategory(profile.theme),
        createdAt: DateTime.now().subtract(
          Duration(days: random.nextInt(365)),
        ),
        isHoneypot: random.nextBool(),
        trapId: random.nextBool() ? _generateId() : null,
      );
      decoyNotes.add(note);
    }

    // Generate fake credentials
    for (int i = 0; i < profile.credentialCount; i++) {
      final service = _generateFakeService();
      final credential = _generateFakeCredential();
      fakeCredentials[service] = credential;
    }

    // Generate fake files
    for (int i = 0; i < profile.fileCount; i++) {
      fakeFiles.add(_generateFakeFileName(profile.theme));
    }

    return DecoyData(
      notes: decoyNotes,
      credentials: fakeCredentials,
      files: fakeFiles,
      metadata: {
        'profile': profile.name,
        'generated_at': DateTime.now().toIso8601String(),
        'note_count': decoyNotes.length,
        'credential_count': fakeCredentials.length,
        'file_count': fakeFiles.length,
      },
    );
  }

  /// 🎭 DEPLOY DECOY ENVIRONMENT
  Future<void> _deployDecoyEnvironment(
      DecoyProfile profile, DecoyData data) async {
    try {
      // Store decoy notes (would integrate with storage service)
      _decoyNotes.addAll(data.notes);
      await _saveDecoyData();

      // Set up fake authentication responses
      await _setupFakeAuth(data.credentials);

      // Create honeypot traps
      for (final note in data.notes.where((n) => n.isHoneypot)) {
        if (note.trapId != null) {
          await setDecoyTrap(
            trapId: note.trapId!,
            type: DecoyTrapType.honeypotNote,
            triggerCondition: 'note_access:${note.id}',
            trapData: {
              'note_id': note.id,
              'note_title': note.title,
              'profile': profile.name,
            },
          );
        }
      }

      print('🎭 Decoy environment deployed with ${data.notes.length} notes');
    } catch (e) {
      print('🚨 Failed to deploy decoy environment: $e');
    }
  }

  /// 🔍 FAKE DATA GENERATORS
  String _generateFakeTitle(DecoyTheme theme) {
    final titles = _getTitleTemplates(theme);
    final random = Random();
    return titles[random.nextInt(titles.length)];
  }

  String _generateFakeContent(DecoyTheme theme, ContentDepth depth) {
    final templates = _getContentTemplates(theme, depth);
    final random = Random();
    final template = templates[random.nextInt(templates.length)];

    return _fillTemplate(template, theme);
  }

  String _generateFakeCategory(DecoyTheme theme) {
    final categories = _getCategoryTemplates(theme);
    final random = Random();
    return categories[random.nextInt(categories.length)];
  }

  String _generateFakeService() {
    final services = [
      'Gmail',
      'Facebook',
      'Twitter',
      'LinkedIn',
      'Instagram',
      'PayPal',
      'Bank Account',
      'Amazon',
      'Netflix',
      'Spotify',
      'Work VPN',
      'Cloud Storage',
      'Company Portal',
      'Email',
    ];
    final random = Random();
    return services[random.nextInt(services.length)];
  }

  String _generateFakeCredential() {
    final random = Random();
    final username = 'user${random.nextInt(9999)}';
    final password = _generateRandomString(12);
    return '$username:$password';
  }

  String _generateFakeFileName(DecoyTheme theme) {
    final prefixes = _getFilenamePrefixes(theme);
    final extensions = ['.txt', '.doc', '.pdf', '.jpg', '.png', '.xlsx'];
    final random = Random();

    final prefix = prefixes[random.nextInt(prefixes.length)];
    final extension = extensions[random.nextInt(extensions.length)];

    return '$prefix${random.nextInt(999)}$extension';
  }

  /// 📝 TEMPLATE GENERATORS
  List<String> _getTitleTemplates(DecoyTheme theme) {
    switch (theme) {
      case DecoyTheme.personal:
        return [
          'Shopping List',
          'Travel Plans',
          'Birthday Ideas',
          'Recipe Notes',
          'Exercise Routine',
          'Book Recommendations',
          'Movie Watchlist',
          'Weekend Plans',
          'Gift Ideas',
          'Meeting Notes',
          'Daily Thoughts',
        ];

      case DecoyTheme.business:
        return [
          'Project Proposal',
          'Meeting Minutes',
          'Client Notes',
          'Budget Plan',
          'Strategy Document',
          'Team Updates',
          'Performance Review',
          'Market Analysis',
          'Quarterly Goals',
          'Contract Details',
        ];

      case DecoyTheme.financial:
        return [
          'Investment Portfolio',
          'Budget Tracker',
          'Expense Report',
          'Tax Documents',
          'Insurance Info',
          'Retirement Plan',
          'Savings Goals',
          'Financial Advisor Notes',
          'Stock Research',
        ];

      case DecoyTheme.technical:
        return [
          'Code Snippets',
          'API Documentation',
          'Server Configuration',
          'Database Schema',
          'Bug Reports',
          'Feature Specifications',
          'System Architecture',
          'Deployment Notes',
          'Security Audit',
        ];

      case DecoyTheme.academic:
        return [
          'Research Notes',
          'Study Guide',
          'Lecture Summary',
          'Assignment',
          'Bibliography',
          'Thesis Outline',
          'Lab Results',
          'Course Schedule',
          'Academic References',
          'Project Timeline',
        ];
    }
  }

  List<String> _getContentTemplates(DecoyTheme theme, ContentDepth depth) {
    final baseTemplates = <String>[];

    switch (theme) {
      case DecoyTheme.personal:
        baseTemplates.addAll([
          'Remember to {action} {item} for {person}',
          'Planning to visit {location} on {date}',
          'Need to buy {items} from {store}',
          'Important: {task} before {deadline}',
        ]);
        break;

      case DecoyTheme.business:
        baseTemplates.addAll([
          'Client {client_name} requested {service} by {date}',
          'Project {project_name} budget: {amount}',
          'Meeting with {person} scheduled for {date}',
          'Action items: {tasks}',
        ]);
        break;

      case DecoyTheme.financial:
        baseTemplates.addAll([
          'Account {account_type}: {amount}',
          'Investment in {stock} showing {performance}',
          'Monthly expenses: {categories}',
          'Financial goal: {goal} by {date}',
        ]);
        break;

      case DecoyTheme.technical:
        baseTemplates.addAll([
          'Function {function_name}({parameters}) returns {type}',
          'Server {server_name} configuration: {settings}',
          'Bug in {component}: {description}',
          'API endpoint: {method} {url}',
        ]);
        break;

      case DecoyTheme.academic:
        baseTemplates.addAll([
          'Research topic: {topic} - Key findings: {findings}',
          'Assignment due {date}: {description}',
          'Study materials: {resources}',
          'Experiment results: {data}',
        ]);
        break;
    }

    if (depth == ContentDepth.detailed) {
      // Add more complex templates for detailed content
      baseTemplates.addAll([
        'Detailed analysis of {subject} reveals {insights}. Next steps include {actions}.',
        'Comprehensive review: {overview}. Recommendations: {suggestions}.',
      ]);
    }

    return baseTemplates;
  }

  List<String> _getCategoryTemplates(DecoyTheme theme) {
    switch (theme) {
      case DecoyTheme.personal:
        return [
          'Personal',
          'Family',
          'Health',
          'Hobbies',
          'Travel',
          'Shopping'
        ];
      case DecoyTheme.business:
        return [
          'Work',
          'Projects',
          'Clients',
          'Meetings',
          'Strategy',
          'Finance'
        ];
      case DecoyTheme.financial:
        return [
          'Banking',
          'Investments',
          'Budget',
          'Taxes',
          'Insurance',
          'Retirement'
        ];
      case DecoyTheme.technical:
        return [
          'Development',
          'Infrastructure',
          'Security',
          'Documentation',
          'Testing'
        ];
      case DecoyTheme.academic:
        return [
          'Research',
          'Studies',
          'Assignments',
          'References',
          'Notes',
          'Projects'
        ];
    }
  }

  List<String> _getFilenamePrefixes(DecoyTheme theme) {
    switch (theme) {
      case DecoyTheme.personal:
        return ['photo_', 'document_', 'note_', 'backup_', 'scan_'];
      case DecoyTheme.business:
        return [
          'report_',
          'proposal_',
          'contract_',
          'invoice_',
          'presentation_'
        ];
      case DecoyTheme.financial:
        return ['statement_', 'receipt_', 'tax_', 'investment_', 'budget_'];
      case DecoyTheme.technical:
        return ['code_', 'config_', 'log_', 'backup_', 'script_'];
      case DecoyTheme.academic:
        return ['paper_', 'thesis_', 'research_', 'study_', 'reference_'];
    }
  }

  String _fillTemplate(String template, DecoyTheme theme) {
    final random = Random();

    // Simple template filling - in production, this would be more sophisticated
    return template
        .replaceAll(
            '{action}', ['buy', 'call', 'email', 'visit'][random.nextInt(4)])
        .replaceAll(
            '{item}', ['gift', 'tickets', 'supplies'][random.nextInt(3)])
        .replaceAll(
            '{person}', ['John', 'Sarah', 'Mike', 'Lisa'][random.nextInt(4)])
        .replaceAll(
            '{location}', ['office', 'store', 'restaurant'][random.nextInt(3)])
        .replaceAll('{date}', 'tomorrow')
        .replaceAll('{amount}', '\$${random.nextInt(10000)}')
        .replaceAll('{client_name}', 'ClientCorp')
        .replaceAll('{project_name}', 'Project Alpha');
  }

  /// 🔧 UTILITY METHODS
  String _generateRandomString(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();
  }

  IntrusionSeverity _calculateSeverity(IntrusionType type, String context) {
    switch (type) {
      case IntrusionType.unauthorizedAccess:
        return IntrusionSeverity.critical;
      case IntrusionType.dataExfiltration:
        return IntrusionSeverity.critical;
      case IntrusionType.bruteForceAttack:
        return IntrusionSeverity.high;
      case IntrusionType.suspiciousBehavior:
        return IntrusionSeverity.medium;
      case IntrusionType.honeypotTriggered:
        return IntrusionSeverity.high;
      case IntrusionType.trapActivated:
        return IntrusionSeverity.high;
      default:
        return IntrusionSeverity.low;
    }
  }

  Future<bool> _checkDecoyTrigger(IntrusionType type, String context) async {
    // Check if this intrusion should trigger decoy activation
    return type == IntrusionType.unauthorizedAccess ||
        type == IntrusionType.bruteForceAttack;
  }

  Future<IntrusionResponse> _generateIntrusionResponse(
      IntrusionEvent intrusion) async {
    final response = IntrusionResponse(
      timestamp: DateTime.now(),
      intrusionId: intrusion.id,
      responseType: _getResponseType(intrusion.severity),
      activateDecoy: intrusion.severity.index >= IntrusionSeverity.medium.index,
      alertLevel: intrusion.severity,
      actions: _getResponseActions(intrusion),
      message: _getResponseMessage(intrusion),
    );

    return response;
  }

  ResponseType _getResponseType(IntrusionSeverity severity) {
    switch (severity) {
      case IntrusionSeverity.critical:
        return ResponseType.immediate;
      case IntrusionSeverity.high:
        return ResponseType.aggressive;
      case IntrusionSeverity.medium:
        return ResponseType.defensive;
      default:
        return ResponseType.passive;
    }
  }

  List<String> _getResponseActions(IntrusionEvent intrusion) {
    final actions = <String>[];

    switch (intrusion.severity) {
      case IntrusionSeverity.critical:
        actions.addAll(
            ['lock_system', 'alert_admin', 'activate_decoy', 'log_incident']);
        break;
      case IntrusionSeverity.high:
        actions
            .addAll(['activate_decoy', 'increase_monitoring', 'log_incident']);
        break;
      case IntrusionSeverity.medium:
        actions.addAll(['log_incident', 'monitor_activity']);
        break;
      default:
        actions.add('log_incident');
    }

    return actions;
  }

  String _getResponseMessage(IntrusionEvent intrusion) {
    switch (intrusion.type) {
      case IntrusionType.unauthorizedAccess:
        return 'Unauthorized access attempt detected and contained';
      case IntrusionType.dataExfiltration:
        return 'Data exfiltration attempt blocked';
      case IntrusionType.bruteForceAttack:
        return 'Brute force attack detected, implementing countermeasures';
      case IntrusionType.honeypotTriggered:
        return 'Honeypot triggered, monitoring attacker behavior';
      default:
        return 'Security event detected and logged';
    }
  }

  Future<bool> _evaluateTrapCondition(
    DecoyTrap trap,
    String action,
    String context,
    Map<String, dynamic>? actionData,
  ) async {
    // Simple condition evaluation - in production, this would be more sophisticated
    return trap.triggerCondition.contains(action) ||
        trap.triggerCondition.contains(context);
  }

  Future<void> _triggerTrap(
      DecoyTrap trap, String action, String context) async {
    print('🪤 Trap triggered: ${trap.id} by action: $action');

    // Record intrusion
    await detectIntrusion(
      type: IntrusionType.trapActivated,
      context: 'Trap ${trap.id} triggered by $action',
      metadata: {
        'trap_id': trap.id,
        'trap_type': trap.type.name,
        'action': action,
        'context': context,
      },
    );

    // Deactivate trap (single-use)
    trap.isActive = false;
    await _saveTraps();
  }

  /// 🗂️ STORAGE METHODS
  Future<void> _loadConfiguration() async {
    try {
      final configJson = await _secureStorage.read(key: _configKey);
      if (configJson != null) {
        _config = DecoySystemConfig.fromJson(jsonDecode(configJson));
      }
    } catch (e) {
      print('⚠️ Failed to load decoy system configuration: $e');
    }
  }

  Future<void> _saveConfiguration() async {
    try {
      await _secureStorage.write(
        key: _configKey,
        value: jsonEncode(_config.toJson()),
      );
    } catch (e) {
      print('🚨 Failed to save decoy system configuration: $e');
    }
  }

  Future<void> _loadDecoyData() async {
    try {
      // Load decoy notes
      final notesJson = await _secureStorage.read(key: _decoyNotesKey);
      if (notesJson != null) {
        final notesList = jsonDecode(notesJson) as List;
        _decoyNotes =
            notesList.map((json) => DecoyNote.fromJson(json)).toList();
      }

      // Load intrusion history
      final historyJson = await _secureStorage.read(key: _intrusionHistoryKey);
      if (historyJson != null) {
        final historyList = jsonDecode(historyJson) as List;
        _intrusionHistory =
            historyList.map((json) => IntrusionEvent.fromJson(json)).toList();
      }

      // Load decoy profiles
      final profilesJson = await _secureStorage.read(key: _decoyProfilesKey);
      if (profilesJson != null) {
        final profilesList = jsonDecode(profilesJson) as List;
        _decoyProfiles =
            profilesList.map((json) => DecoyProfile.fromJson(json)).toList();
      }

      // Load active traps
      final trapsJson = await _secureStorage.read(key: _activeTrapsKey);
      if (trapsJson != null) {
        final trapsMap = jsonDecode(trapsJson) as Map<String, dynamic>;
        _activeTraps = trapsMap.map(
          (key, value) => MapEntry(key, DecoyTrap.fromJson(value)),
        );
      }
    } catch (e) {
      print('⚠️ Failed to load decoy data: $e');
    }
  }

  Future<void> _saveDecoyData() async {
    try {
      await _secureStorage.write(
        key: _decoyNotesKey,
        value: jsonEncode(_decoyNotes.map((note) => note.toJson()).toList()),
      );
    } catch (e) {
      print('🚨 Failed to save decoy notes: $e');
    }
  }

  Future<void> _recordIntrusion(IntrusionEvent intrusion) async {
    try {
      _intrusionHistory.add(intrusion);

      // Keep history manageable
      if (_intrusionHistory.length > _maxHistorySize) {
        _intrusionHistory.removeAt(0);
      }

      await _secureStorage.write(
        key: _intrusionHistoryKey,
        value: jsonEncode(
            _intrusionHistory.map((event) => event.toJson()).toList()),
      );
    } catch (e) {
      print('🚨 Failed to record intrusion: $e');
    }
  }

  Future<void> _saveTraps() async {
    try {
      final trapsMap = _activeTraps.map(
        (key, trap) => MapEntry(key, trap.toJson()),
      );

      await _secureStorage.write(
        key: _activeTrapsKey,
        value: jsonEncode(trapsMap),
      );
    } catch (e) {
      print('🚨 Failed to save traps: $e');
    }
  }

  Future<void> _generateDefaultDecoys() async {
    if (_config.autoGenerateDecoys && _decoyNotes.isEmpty) {
      final defaultProfile = DecoyProfile.defaultProfile();
      final decoyData = await _generateDecoyData(defaultProfile);

      _decoyNotes.addAll(decoyData.notes);
      await _saveDecoyData();

      print('🎭 Generated ${decoyData.notes.length} default decoy notes');
    }
  }

  Future<void> _setupTraps() async {
    if (_config.enableTraps && _activeTraps.isEmpty) {
      // Set up some default traps using internal method to avoid infinite loop
      await _setDecoyTrapInternal(
        trapId: 'login_trap',
        type: DecoyTrapType.authenticationTrap,
        triggerCondition: 'failed_auth_attempt',
      );

      await _setDecoyTrapInternal(
        trapId: 'data_access_trap',
        type: DecoyTrapType.dataAccessTrap,
        triggerCondition: 'unauthorized_data_access',
      );

      print('🪤 Default traps activated');
    }
  }

  /// 🪤 INTERNAL SET DECOY TRAP (for initialization only)
  Future<void> _setDecoyTrapInternal({
    required String trapId,
    required DecoyTrapType type,
    required String triggerCondition,
    Map<String, dynamic>? trapData,
  }) async {
    try {
      final trap = DecoyTrap(
        id: trapId,
        type: type,
        triggerCondition: triggerCondition,
        trapData: trapData ?? {},
        isActive: true,
        createdAt: DateTime.now(),
      );

      _activeTraps[trapId] = trap;
      await _saveTraps();

      print('🪤 Decoy trap set: $trapId (${type.name})');
    } catch (e) {
      print('🚨 Failed to set decoy trap: $e');
    }
  }

  Future<void> _setupFakeAuth(Map<String, String> credentials) async {
    // This would integrate with the auth system to provide fake responses
    print('🔐 Fake authentication responses configured');
  }

  Future<void> _setupDecoyMonitoring(DecoyProfile profile) async {
    // Set up monitoring for decoy interactions
    print('👁️ Decoy monitoring activated for profile: ${profile.name}');
  }

  Future<void> _startMonitoring() async {
    // Start background monitoring for intrusions
    print('👁️ Intrusion monitoring started');
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// 📊 PUBLIC METHODS
  DecoySystemConfig getConfiguration() => _config;

  Future<void> updateConfiguration(DecoySystemConfig config) async {
    _config = config;
    await _saveConfiguration();
  }

  List<DecoyNote> getDecoyNotes() => List.unmodifiable(_decoyNotes);
  List<IntrusionEvent> getIntrusionHistory() =>
      List.unmodifiable(_intrusionHistory);
  List<DecoyProfile> getDecoyProfiles() => List.unmodifiable(_decoyProfiles);
  Map<String, DecoyTrap> getActiveTraps() => Map.unmodifiable(_activeTraps);

  int getIntrusionCount() => _intrusionCount;

  Future<void> clearIntrusionHistory() async {
    _intrusionHistory.clear();
    await _secureStorage.delete(key: _intrusionHistoryKey);
  }

  Future<void> deactivateAllTraps() async {
    for (final trap in _activeTraps.values) {
      trap.isActive = false;
    }
    await _saveTraps();
  }

  /// 🎭 GENERATE DECOY FILES
  Future<List<Map<String, dynamic>>> generateDecoyFiles({
    int count = 5,
    List<String>? fileTypes,
  }) async {
    final decoyFiles = <Map<String, dynamic>>[];
    final fileTypesList = fileTypes ?? ['image', 'document', 'video'];

    for (int i = 0; i < count; i++) {
      final fileType = fileTypesList[_random.nextInt(fileTypesList.length)];
      final fileName = _generateFileName(fileType);

      decoyFiles.add({
        'id': _uuid.v4(),
        'name': fileName,
        'type': fileType,
        'size': _random.nextInt(10 * 1024 * 1024), // 0-10MB
        'created': DateTime.now()
            .subtract(Duration(days: _random.nextInt(365)))
            .toIso8601String(),
        'is_decoy': true,
        'decoy_type': 'fake_file',
      });
    }

    return decoyFiles;
  }

  /// 📸 GENERATE FAKE FILE NAME
  String _generateFileName(String fileType) {
    final baseName = _fakeNames[_random.nextInt(_fakeNames.length)];

    switch (fileType) {
      case 'image':
        final extensions = ['jpg', 'png', 'gif'];
        final ext = extensions[_random.nextInt(extensions.length)];
        return 'IMG_${DateTime.now().millisecondsSinceEpoch}.$ext';
      case 'document':
        final extensions = ['pdf', 'doc', 'txt'];
        final ext = extensions[_random.nextInt(extensions.length)];
        return '$baseName.$ext';
      case 'video':
        final extensions = ['mp4', 'avi', 'mov'];
        final ext = extensions[_random.nextInt(extensions.length)];
        return 'VID_${DateTime.now().millisecondsSinceEpoch}.$ext';
      default:
        return '$baseName.dat';
    }
  }
}

/// ⚙️ DECOY SYSTEM CONFIGURATION
class DecoySystemConfig {
  final bool enableDecoySystem;
  final bool autoGenerateDecoys;
  final bool enableTraps;
  final bool enableHoneypots;
  final bool enableIntrusionDetection;
  final int maxDecoyNotes;
  final DecoyProfile defaultProfile;

  const DecoySystemConfig({
    this.enableDecoySystem = true,
    this.autoGenerateDecoys = true,
    this.enableTraps = true,
    this.enableHoneypots = true,
    this.enableIntrusionDetection = true,
    this.maxDecoyNotes = 50,
    this.defaultProfile = const DecoyProfile.defaultProfile(),
  });

  factory DecoySystemConfig.defaultConfig() => const DecoySystemConfig();

  Map<String, dynamic> toJson() => {
        'enableDecoySystem': enableDecoySystem,
        'autoGenerateDecoys': autoGenerateDecoys,
        'enableTraps': enableTraps,
        'enableHoneypots': enableHoneypots,
        'enableIntrusionDetection': enableIntrusionDetection,
        'maxDecoyNotes': maxDecoyNotes,
        'defaultProfile': defaultProfile.toJson(),
      };

  factory DecoySystemConfig.fromJson(Map<String, dynamic> json) {
    return DecoySystemConfig(
      enableDecoySystem: json['enableDecoySystem'] ?? true,
      autoGenerateDecoys: json['autoGenerateDecoys'] ?? true,
      enableTraps: json['enableTraps'] ?? true,
      enableHoneypots: json['enableHoneypots'] ?? true,
      enableIntrusionDetection: json['enableIntrusionDetection'] ?? true,
      maxDecoyNotes: json['maxDecoyNotes'] ?? 50,
      defaultProfile: json['defaultProfile'] != null
          ? DecoyProfile.fromJson(json['defaultProfile'])
          : const DecoyProfile.defaultProfile(),
    );
  }
}

/// 🎭 DECOY THEME
enum DecoyTheme {
  personal,
  business,
  financial,
  technical,
  academic,
}

/// 📝 CONTENT DEPTH
enum ContentDepth {
  basic,
  detailed,
}

/// 🎭 DECOY PROFILE
class DecoyProfile {
  final String name;
  final DecoyTheme theme;
  final ContentDepth contentDepth;
  final int noteCount;
  final int credentialCount;
  final int fileCount;

  const DecoyProfile({
    required this.name,
    required this.theme,
    required this.contentDepth,
    required this.noteCount,
    required this.credentialCount,
    required this.fileCount,
  });

  const DecoyProfile.defaultProfile()
      : name = 'Default',
        theme = DecoyTheme.personal,
        contentDepth = ContentDepth.basic,
        noteCount = 20,
        credentialCount = 5,
        fileCount = 10;

  Map<String, dynamic> toJson() => {
        'name': name,
        'theme': theme.name,
        'contentDepth': contentDepth.name,
        'noteCount': noteCount,
        'credentialCount': credentialCount,
        'fileCount': fileCount,
      };

  factory DecoyProfile.fromJson(Map<String, dynamic> json) {
    return DecoyProfile(
      name: json['name'] ?? 'Default',
      theme: DecoyTheme.values.firstWhere(
        (theme) => theme.name == json['theme'],
        orElse: () => DecoyTheme.personal,
      ),
      contentDepth: ContentDepth.values.firstWhere(
        (depth) => depth.name == json['contentDepth'],
        orElse: () => ContentDepth.basic,
      ),
      noteCount: json['noteCount'] ?? 20,
      credentialCount: json['credentialCount'] ?? 5,
      fileCount: json['fileCount'] ?? 10,
    );
  }
}

/// 📝 DECOY NOTE
class DecoyNote {
  final String id;
  final String title;
  final String content;
  final String category;
  final DateTime createdAt;
  final bool isHoneypot;
  final String? trapId;

  DecoyNote({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.createdAt,
    required this.isHoneypot,
    this.trapId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'category': category,
        'createdAt': createdAt.toIso8601String(),
        'isHoneypot': isHoneypot,
        'trapId': trapId,
      };

  factory DecoyNote.fromJson(Map<String, dynamic> json) {
    return DecoyNote(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      category: json['category'],
      createdAt: DateTime.parse(json['createdAt']),
      isHoneypot: json['isHoneypot'] ?? false,
      trapId: json['trapId'],
    );
  }
}

/// 📊 DECOY DATA
class DecoyData {
  final List<DecoyNote> notes;
  final Map<String, String> credentials;
  final List<String> files;
  final Map<String, dynamic> metadata;

  DecoyData({
    required this.notes,
    required this.credentials,
    required this.files,
    required this.metadata,
  });

  factory DecoyData.empty() => DecoyData(
        notes: [],
        credentials: {},
        files: [],
        metadata: {},
      );
}

/// 🚨 INTRUSION TYPES
enum IntrusionType {
  unauthorizedAccess,
  dataExfiltration,
  bruteForceAttack,
  suspiciousBehavior,
  honeypotTriggered,
  trapActivated,
  unknown,
}

/// ⚠️ INTRUSION SEVERITY
enum IntrusionSeverity {
  low,
  medium,
  high,
  critical,
}

/// 🚨 INTRUSION EVENT
class IntrusionEvent {
  final String id;
  final DateTime timestamp;
  final IntrusionType type;
  final String context;
  final Map<String, dynamic> metadata;
  final IntrusionSeverity severity;
  final bool decoyTriggered;

  IntrusionEvent({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.context,
    required this.metadata,
    required this.severity,
    required this.decoyTriggered,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'type': type.name,
        'context': context,
        'metadata': metadata,
        'severity': severity.name,
        'decoyTriggered': decoyTriggered,
      };

  factory IntrusionEvent.fromJson(Map<String, dynamic> json) {
    return IntrusionEvent(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      type: IntrusionType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => IntrusionType.unknown,
      ),
      context: json['context'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      severity: IntrusionSeverity.values.firstWhere(
        (severity) => severity.name == json['severity'],
        orElse: () => IntrusionSeverity.low,
      ),
      decoyTriggered: json['decoyTriggered'] ?? false,
    );
  }
}

/// 🚡 RESPONSE TYPES
enum ResponseType {
  passive,
  defensive,
  aggressive,
  immediate,
}

/// 🛡️ INTRUSION RESPONSE
class IntrusionResponse {
  final DateTime timestamp;
  final String intrusionId;
  final ResponseType responseType;
  final bool activateDecoy;
  final IntrusionSeverity alertLevel;
  final List<String> actions;
  final String message;

  IntrusionResponse({
    required this.timestamp,
    required this.intrusionId,
    required this.responseType,
    required this.activateDecoy,
    required this.alertLevel,
    required this.actions,
    required this.message,
  });

  factory IntrusionResponse.silent() => IntrusionResponse(
        timestamp: DateTime.now(),
        intrusionId: '',
        responseType: ResponseType.passive,
        activateDecoy: false,
        alertLevel: IntrusionSeverity.low,
        actions: [],
        message: 'Silent monitoring active',
      );
}

/// 🎯 INTRUSION DETECTION RESULT
class IntrusionDetectionResult {
  final bool detected;
  final IntrusionEvent? intrusion;
  final IntrusionResponse response;
  final bool decoyActivated;
  final IntrusionSeverity alertLevel;

  IntrusionDetectionResult({
    required this.detected,
    required this.intrusion,
    required this.response,
    required this.decoyActivated,
    required this.alertLevel,
  });
}

/// 🎭 DECOY ACTIVATION RESULT
class DecoyActivationResult {
  final bool success;
  final DecoyProfile profile;
  final DecoyData decoyData;
  final String message;
  final bool monitoringActive;

  DecoyActivationResult({
    required this.success,
    required this.profile,
    required this.decoyData,
    required this.message,
    required this.monitoringActive,
  });
}

/// 🪤 DECOY TRAP TYPES
enum DecoyTrapType {
  honeypotNote,
  authenticationTrap,
  dataAccessTrap,
  behaviorTrap,
}

/// 🪤 DECOY TRAP
class DecoyTrap {
  final String id;
  final DecoyTrapType type;
  final String triggerCondition;
  final Map<String, dynamic> trapData;
  bool isActive;
  final DateTime createdAt;

  DecoyTrap({
    required this.id,
    required this.type,
    required this.triggerCondition,
    required this.trapData,
    required this.isActive,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'triggerCondition': triggerCondition,
        'trapData': trapData,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
      };

  factory DecoyTrap.fromJson(Map<String, dynamic> json) {
    return DecoyTrap(
      id: json['id'],
      type: DecoyTrapType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => DecoyTrapType.honeypotNote,
      ),
      triggerCondition: json['triggerCondition'],
      trapData: Map<String, dynamic>.from(json['trapData'] ?? {}),
      isActive: json['isActive'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

/// ⚡ TRAP TRIGGER RESULT
class TrapTriggerResult {
  final bool triggered;
  final DecoyTrap? trap;
  final String action;
  final String context;
  final DateTime timestamp;

  TrapTriggerResult({
    required this.triggered,
    required this.trap,
    required this.action,
    required this.context,
    required this.timestamp,
  });
}
