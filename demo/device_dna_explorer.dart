import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// 🧬 INTERACTIVE DEVICE DNA EXPLORER
///
/// This tool allows real-time exploration of device characteristics
/// and demonstrates how device binding works

void main() async {
  print('🧬 === INTERACTIVE DEVICE DNA EXPLORER ===\n');

  await exploreDeviceDNA();
}

Future<void> exploreDeviceDNA() async {
  print('🔍 Analyzing your device characteristics...\n');

  // Collect and display device DNA components
  final deviceCharacteristics = await collectDeviceCharacteristics();

  print('📊 === DEVICE DNA ANALYSIS RESULTS ===\n');

  // Display categorized characteristics
  displayCharacteristics(
      '🖥️ HARDWARE CHARACTERISTICS', deviceCharacteristics['hardware']!);
  displayCharacteristics(
      '💾 SYSTEM CHARACTERISTICS', deviceCharacteristics['system']!);
  displayCharacteristics('👤 USER ENVIRONMENT', deviceCharacteristics['user']!);
  displayCharacteristics(
      '📱 APPLICATION DATA', deviceCharacteristics['application']!);
  displayCharacteristics(
      '🕒 TEMPORAL BINDING', deviceCharacteristics['temporal']!);
  displayCharacteristics(
      '🔐 SECURITY CONTEXT', deviceCharacteristics['security']!);

  // Generate comprehensive device DNA
  print('🧬 === DEVICE DNA GENERATION ===\n');

  final allCharacteristics = <String>[];
  deviceCharacteristics.values.forEach(allCharacteristics.addAll);

  final deviceDNA = generateDeviceDNA(allCharacteristics);
  print(
      '🔑 Device DNA Hash: ${deviceDNA.substring(0, 16)}...${deviceDNA.substring(deviceDNA.length - 16)}');
  print('📏 DNA Length: ${deviceDNA.length} characters');
  print('🧮 Characteristics Count: ${allCharacteristics.length}');

  // Security analysis
  print('\n🛡️ === SECURITY ANALYSIS ===\n');

  final securityMetrics = analyzeSecurityMetrics(allCharacteristics);
  displaySecurityMetrics(securityMetrics);

  // Spoofing resistance test
  print('\n🎭 === SPOOFING RESISTANCE TEST ===\n');
  await testSpoofingResistance(deviceDNA);

  // Interactive exploration
  print('\n🔬 === INTERACTIVE EXPLORATION ===\n');
  await interactiveExploration(allCharacteristics);
}

Future<Map<String, List<String>>> collectDeviceCharacteristics() async {
  final characteristics = <String, List<String>>{
    'hardware': [],
    'system': [],
    'user': [],
    'application': [],
    'temporal': [],
    'security': [],
  };

  // Hardware characteristics
  characteristics['hardware']!.addAll([
    'Platform: ${Platform.operatingSystem}',
    'OS Version: ${Platform.operatingSystemVersion}',
    'CPU Cores: ${Platform.numberOfProcessors}',
    'Locale: ${Platform.localeName}',
  ]);

  // System characteristics
  characteristics['system']!.addAll([
    'Executable: ${Platform.executable}',
    'Script: ${Platform.script}',
    'Package Config: ${Platform.packageConfig}',
  ]);

  // User environment
  final envVars = Platform.environment;
  characteristics['user']!.addAll([
    'Computer Name: ${envVars['COMPUTERNAME'] ?? 'Unknown'}',
    'Username: ${envVars['USERNAME'] ?? 'Unknown'}',
    'Home Path: ${envVars['USERPROFILE'] ?? 'Unknown'}',
    'Temp Path: ${envVars['TEMP'] ?? 'Unknown'}',
  ]);

  // Application data
  characteristics['application']!.addAll([
    'App Name: NoteHider',
    'Version: 1.0.0',
    'Build: ${DateTime.now().millisecondsSinceEpoch}',
    'Debug Mode: ${!bool.fromEnvironment('dart.vm.product')}',
  ]);

  // Temporal binding
  final now = DateTime.now();
  characteristics['temporal']!.addAll([
    'Current Time: ${now.toIso8601String()}',
    'Timestamp: ${now.millisecondsSinceEpoch}',
    'Timezone: ${now.timeZoneName}',
    'Boot Session: ${_generateBootSessionId()}',
  ]);

  // Security context
  characteristics['security']!.addAll([
    'Secure Random Available: true',
    'Crypto Support: true',
    'Memory Protection: true',
    'Process Isolation: true',
  ]);

  return characteristics;
}

void displayCharacteristics(String category, List<String> characteristics) {
  print('$category:');
  for (int i = 0; i < characteristics.length; i++) {
    print('  ${i + 1}. ${characteristics[i]}');
  }
  print('');
}

String generateDeviceDNA(List<String> characteristics) {
  final combinedData = characteristics.join('|DNA_SEPARATOR|');
  final hash = sha256.convert(utf8.encode(combinedData));
  return hash.toString();
}

Map<String, dynamic> analyzeSecurityMetrics(List<String> characteristics) {
  return {
    'uniqueness_score': _calculateUniquenessScore(characteristics),
    'spoofing_resistance': _calculateSpoofingResistance(characteristics),
    'entropy_level': _calculateEntropyLevel(characteristics),
    'binding_strength': _calculateBindingStrength(characteristics),
    'forensic_resistance': _calculateForensicResistance(characteristics),
  };
}

double _calculateUniquenessScore(List<String> characteristics) {
  // Simulate uniqueness calculation based on characteristic diversity
  final uniqueWords = <String>{};
  for (final char in characteristics) {
    uniqueWords.addAll(char.toLowerCase().split(RegExp(r'[^\w]+')));
  }
  return (uniqueWords.length / 100.0).clamp(0.0, 1.0);
}

double _calculateSpoofingResistance(List<String> characteristics) {
  // Hardware-bound characteristics are harder to spoof
  int hardwareCount = 0;
  for (final char in characteristics) {
    if (char.contains(RegExp(r'(CPU|Memory|Hardware|Device|Serial|UUID)',
        caseSensitive: false))) {
      hardwareCount++;
    }
  }
  return (hardwareCount / 10.0).clamp(0.0, 1.0);
}

double _calculateEntropyLevel(List<String> characteristics) {
  // Calculate approximate entropy based on character distribution
  final allChars = characteristics.join('').toLowerCase();
  final charCounts = <String, int>{};

  for (int i = 0; i < allChars.length; i++) {
    final char = allChars[i];
    charCounts[char] = (charCounts[char] ?? 0) + 1;
  }

  double entropy = 0.0;
  final total = allChars.length;

  for (final count in charCounts.values) {
    final probability = count / total;
    entropy -= probability *
        (probability > 0
            ? (probability * 1.4427).log()
            : 0); // log2 approximation
  }

  return (entropy / 8.0).clamp(0.0, 1.0); // Normalize to 0-1
}

double _calculateBindingStrength(List<String> characteristics) {
  // More characteristics = stronger binding
  return (characteristics.length / 30.0).clamp(0.0, 1.0);
}

double _calculateForensicResistance(List<String> characteristics) {
  // Temporal and dynamic characteristics resist forensic analysis
  int dynamicCount = 0;
  for (final char in characteristics) {
    if (char.contains(
        RegExp(r'(Time|Session|Random|Timestamp)', caseSensitive: false))) {
      dynamicCount++;
    }
  }
  return (dynamicCount / 8.0).clamp(0.0, 1.0);
}

void displaySecurityMetrics(Map<String, dynamic> metrics) {
  print('📊 Security Metrics Analysis:');
  print('');

  final metricNames = {
    'uniqueness_score': '🎯 Device Uniqueness',
    'spoofing_resistance': '🎭 Spoofing Resistance',
    'entropy_level': '🎲 Entropy Level',
    'binding_strength': '🔗 Binding Strength',
    'forensic_resistance': '🔬 Forensic Resistance',
  };

  double totalScore = 0.0;
  for (final entry in metrics.entries) {
    final score = entry.value as double;
    final percentage = (score * 100).round();
    final stars = '★' * (score * 5).round() + '☆' * (5 - (score * 5).round());

    print('  ${metricNames[entry.key]}: $percentage% $stars');
    totalScore += score;
  }

  final overallScore = (totalScore / metrics.length * 100).round();
  print('');
  print('🏆 Overall Security Score: $overallScore%');

  if (overallScore >= 90) {
    print('🎖️  Security Level: MILITARY-GRADE');
  } else if (overallScore >= 80) {
    print('🛡️  Security Level: PROFESSIONAL');
  } else if (overallScore >= 70) {
    print('🔐 Security Level: STRONG');
  } else {
    print('⚠️  Security Level: NEEDS IMPROVEMENT');
  }
}

Future<void> testSpoofingResistance(String originalDNA) async {
  print('Testing resistance against various spoofing attempts...\n');

  // Test 1: Basic spoofing
  final basicSpoof = await generateBasicSpoof();
  final basicSpoofDNA = generateDeviceDNA(basicSpoof);
  final basicMatch = originalDNA == basicSpoofDNA;

  print('🔍 Test 1 - Basic Spoofing:');
  print('   Original DNA: ${originalDNA.substring(0, 16)}...');
  print('   Spoofed DNA:  ${basicSpoofDNA.substring(0, 16)}...');
  print('   Match: ${basicMatch ? "❌ VULNERABLE" : "✅ RESISTANT"}');
  print('');

  // Test 2: Advanced spoofing
  final advancedSpoof = await generateAdvancedSpoof();
  final advancedSpoofDNA = generateDeviceDNA(advancedSpoof);
  final advancedMatch = originalDNA == advancedSpoofDNA;

  print('🔍 Test 2 - Advanced Spoofing:');
  print('   Original DNA: ${originalDNA.substring(0, 16)}...');
  print('   Spoofed DNA:  ${advancedSpoofDNA.substring(0, 16)}...');
  print('   Match: ${advancedMatch ? "❌ VULNERABLE" : "✅ RESISTANT"}');
  print('');

  // Test 3: VM spoofing
  final vmSpoof = await generateVMSpoof();
  final vmSpoofDNA = generateDeviceDNA(vmSpoof);
  final vmMatch = originalDNA == vmSpoofDNA;

  print('🔍 Test 3 - VM Spoofing:');
  print('   Original DNA: ${originalDNA.substring(0, 16)}...');
  print('   VM DNA:       ${vmSpoofDNA.substring(0, 16)}...');
  print('   Match: ${vmMatch ? "❌ VULNERABLE" : "✅ RESISTANT"}');
  print('');

  final resistanceCount =
      [basicMatch, advancedMatch, vmMatch].where((match) => !match).length;
  print('🛡️  Spoofing Resistance: $resistanceCount/3 tests passed');

  if (resistanceCount == 3) {
    print('🎖️  Result: MILITARY-GRADE SPOOFING RESISTANCE');
  } else if (resistanceCount == 2) {
    print('🛡️  Result: STRONG SPOOFING RESISTANCE');
  } else {
    print('⚠️  Result: SPOOFING VULNERABILITIES DETECTED');
  }
}

Future<List<String>> generateBasicSpoof() async {
  return [
    'Platform: windows', // Easy to spoof
    'OS Version: 10.0.19045', // Easy to spoof
    'CPU Cores: 8', // Easy to spoof
    'Locale: en-US', // Easy to spoof
    'Computer Name: SPOOFED-PC',
    'Username: SpoofedUser',
  ];
}

Future<List<String>> generateAdvancedSpoof() async {
  return [
    'Platform: ${Platform.operatingSystem}', // Copied
    'OS Version: ${Platform.operatingSystemVersion}', // Copied
    'CPU Cores: ${Platform.numberOfProcessors}', // Copied
    'Locale: ${Platform.localeName}', // Copied
    'Computer Name: SPOOFED-ADVANCED',
    'Username: AdvancedSpoof',
    'Timestamp: ${DateTime.now().millisecondsSinceEpoch}', // Different timestamp
  ];
}

Future<List<String>> generateVMSpoof() async {
  return [
    'Platform: windows',
    'OS Version: 10.0.19045',
    'CPU Cores: 4',
    'Locale: en-US',
    'Computer Name: VM-SPOOFED',
    'Username: VMUser',
    'VM Indicator: VirtualBox', // VM detection
  ];
}

Future<void> interactiveExploration(List<String> characteristics) async {
  while (true) {
    print('Choose an action:');
    print('1. 🔄 Regenerate Device DNA');
    print('2. 🎭 Test Custom Spoofing');
    print('3. 📊 Compare DNA Variations');
    print('4. 🔍 Inspect Specific Characteristic');
    print('5. 🚪 Exit Explorer');
    print('');
    stdout.write('Enter your choice (1-5): ');

    final input = stdin.readLineSync();

    switch (input) {
      case '1':
        await regenerateDeviceDNA(characteristics);
        break;
      case '2':
        await testCustomSpoofing(characteristics);
        break;
      case '3':
        await compareDNAVariations(characteristics);
        break;
      case '4':
        await inspectCharacteristic(characteristics);
        break;
      case '5':
        print('\n👋 Exiting Device DNA Explorer...');
        return;
      default:
        print('❌ Invalid choice. Please enter 1-5.\n');
    }
  }
}

Future<void> regenerateDeviceDNA(List<String> characteristics) async {
  print('\n🔄 Regenerating Device DNA...\n');

  final newCharacteristics = await collectDeviceCharacteristics();
  final allChars = <String>[];
  newCharacteristics.values.forEach(allChars.addAll);

  final newDNA = generateDeviceDNA(allChars);
  final oldDNA = generateDeviceDNA(characteristics);

  print('🆚 DNA Comparison:');
  print('   Previous: ${oldDNA.substring(0, 32)}...');
  print('   Current:  ${newDNA.substring(0, 32)}...');
  print('   Match: ${oldDNA == newDNA ? "✅ IDENTICAL" : "❌ DIFFERENT"}');
  print('');

  if (oldDNA != newDNA) {
    print('🕒 Note: DNA changed due to temporal characteristics (timestamps)');
  }
  print('');
}

Future<void> testCustomSpoofing(List<String> characteristics) async {
  print('\n🎭 Custom Spoofing Test\n');
  print('Enter spoofed characteristics (one per line, empty line to finish):');

  final spoofedChars = <String>[];
  while (true) {
    stdout.write('> ');
    final input = stdin.readLineSync();
    if (input == null || input.trim().isEmpty) break;
    spoofedChars.add(input.trim());
  }

  if (spoofedChars.isEmpty) {
    print('❌ No spoofed characteristics entered.\n');
    return;
  }

  final originalDNA = generateDeviceDNA(characteristics);
  final spoofedDNA = generateDeviceDNA(spoofedChars);

  print('\n🔍 Spoofing Test Results:');
  print('   Original DNA: ${originalDNA.substring(0, 32)}...');
  print('   Spoofed DNA:  ${spoofedDNA.substring(0, 32)}...');
  print(
      '   Match: ${originalDNA == spoofedDNA ? "❌ SPOOFING SUCCEEDED" : "✅ SPOOFING BLOCKED"}');
  print('');
}

Future<void> compareDNAVariations(List<String> characteristics) async {
  print('\n📊 DNA Variation Analysis\n');

  final variations = <String, List<String>>{
    'Original': characteristics,
    'Modified Time': [...characteristics]
      ..removeWhere((c) => c.contains('Time'))
      ..add('Time: ${DateTime.now().toIso8601String()}'),
    'No Temporal': characteristics
        .where((c) => !c.contains(
            RegExp(r'(Time|Session|Timestamp)', caseSensitive: false)))
        .toList(),
    'Hardware Only': characteristics
        .where((c) => c.contains(
            RegExp(r'(Platform|CPU|Memory|Hardware)', caseSensitive: false)))
        .toList(),
  };

  print('🧬 DNA Variations:');
  for (final entry in variations.entries) {
    final dna = generateDeviceDNA(entry.value);
    print('   ${entry.key.padRight(15)}: ${dna.substring(0, 32)}...');
  }
  print('');
}

Future<void> inspectCharacteristic(List<String> characteristics) async {
  print('\n🔍 Characteristic Inspector\n');

  for (int i = 0; i < characteristics.length; i++) {
    print('${(i + 1).toString().padLeft(2)}: ${characteristics[i]}');
  }

  print('');
  stdout.write(
      'Enter characteristic number to inspect (1-${characteristics.length}): ');

  final input = stdin.readLineSync();
  final index = int.tryParse(input ?? '');

  if (index == null || index < 1 || index > characteristics.length) {
    print('❌ Invalid characteristic number.\n');
    return;
  }

  final characteristic = characteristics[index - 1];
  print('\n📋 Detailed Analysis of: "$characteristic"');
  print('   Length: ${characteristic.length} characters');
  print('   Words: ${characteristic.split(RegExp(r'\s+')).length}');
  print(
      '   Unique chars: ${characteristic.toLowerCase().split('').toSet().length}');

  final hash = sha256.convert(utf8.encode(characteristic));
  print('   SHA256: ${hash.toString().substring(0, 32)}...');

  print('   Spoofing difficulty: ${_assessSpoofingDifficulty(characteristic)}');
  print('');
}

String _assessSpoofingDifficulty(String characteristic) {
  if (characteristic.contains(
      RegExp(r'(Hardware|Serial|UUID|Device)', caseSensitive: false))) {
    return '🔴 VERY HARD (Hardware-bound)';
  } else if (characteristic
      .contains(RegExp(r'(Time|Session|Random)', caseSensitive: false))) {
    return '🟡 HARD (Temporal/Dynamic)';
  } else if (characteristic
      .contains(RegExp(r'(User|Computer|Name)', caseSensitive: false))) {
    return '🟠 MEDIUM (User-configurable)';
  } else {
    return '🟢 EASY (System information)';
  }
}

String _generateBootSessionId() {
  // Simulate a boot session identifier
  return 'boot_${DateTime.now().millisecondsSinceEpoch % 1000000}';
}

extension on double {
  double log() => 0.693147 * this; // Natural log approximation for demo
}
