import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../authentication/bloc/auth_bloc.dart';
import '../authentication/bloc/auth_state.dart';
import '../authentication/bloc/auth_event.dart';
import '../../services/security_config_service.dart';

/// 🛡️ SECURITY TAB PAGE
///
/// Security configuration and monitoring interface with:
/// • Security score and status display
/// • Individual feature toggles and configuration
/// • Security profile switching
/// • Real-time security monitoring
/// • Feature testing capabilities
class SecurityTabPage extends StatefulWidget {
  const SecurityTabPage({super.key});

  @override
  State<SecurityTabPage> createState() => _SecurityTabPageState();
}

class _SecurityTabPageState extends State<SecurityTabPage> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Security Score Card
                _buildSecurityScoreCard(state),

                const SizedBox(height: 24),

                // Quick Profile Switch
                _buildQuickProfileSwitch(state),

                const SizedBox(height: 32),

                // Security Features
                _buildSecurityFeatures(state),

                const SizedBox(height: 32),

                // Advanced Settings
                _buildAdvancedSettings(state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSecurityScoreCard(AuthState state) {
    final score = state.securityMetrics.securityScore;
    final level = state.securityMetrics.securityLevel;
    final threatLevel = state.securityMetrics.threatLevel;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: _getSecurityGradient(level),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getSecurityColor(level).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Security Score',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    score.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '/ 10.0',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getSecurityIcon(level),
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getSecurityLevelText(level),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.threatIndicator,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${state.securityMetrics.enabledFeaturesCount} features active',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickProfileSwitch(AuthState state) {
    final currentProfile = state.securityMetrics.currentSecurityProfile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Security Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildProfileCard(
                  'basic', 'Basic', 6.5, currentProfile == 'basic'),
              const SizedBox(width: 12),
              _buildProfileCard('professional', 'Professional', 8.0,
                  currentProfile == 'professional'),
              const SizedBox(width: 12),
              _buildProfileCard(
                  'military', 'Military', 9.5, currentProfile == 'military'),
              const SizedBox(width: 12),
              _buildProfileCard(
                  'paranoid', 'Paranoid', 10.0, currentProfile == 'paranoid'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(
      String profileId, String name, double score, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          context
              .read<AuthBloc>()
              .add(SwitchSecurityProfile(newProfileType: profileId));
        }
      },
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFA726) : Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFA726) : Colors.grey[800]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              name,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              score.toString(),
              style: TextStyle(
                color: isSelected ? Colors.black : const Color(0xFFFFA726),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '/10',
              style: TextStyle(
                color: isSelected
                    ? Colors.black.withOpacity(0.7)
                    : Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityFeatures(AuthState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Security Features',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          'biometric',
          'Biometric Authentication',
          'Fingerprint and face recognition',
          Icons.fingerprint,
          state.securityMetrics.isFeatureActive('biometric'),
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          'location',
          'Location Security',
          'Safe zone verification',
          Icons.location_on,
          state.securityMetrics.isFeatureActive('location'),
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          'totp',
          'TOTP Authentication',
          'Time-based one-time passwords',
          Icons.security,
          state.securityMetrics.isFeatureActive('totp'),
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          'tamper_detection',
          'Tamper Detection',
          'App integrity monitoring',
          Icons.shield,
          state.securityMetrics.isFeatureActive('tamper_detection'),
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          'auto_wipe',
          'Auto-Wipe System',
          'Emergency data destruction',
          Icons.delete_forever,
          state.securityMetrics.isFeatureActive('auto_wipe'),
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          'decoy_system',
          'Decoy System',
          'Honeypots and fake data',
          Icons.theater_comedy,
          state.securityMetrics.isFeatureActive('decoy_system'),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(String featureId, String title, String subtitle,
      IconData icon, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? const Color(0xFFFFA726) : Colors.grey[800]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFFFFA726).withOpacity(0.2)
                  : Colors.grey[800],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isActive ? const Color(0xFFFFA726) : Colors.grey[500],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  context.read<AuthBloc>().add(TestSecurityFeature(featureId));
                },
                icon: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              Switch(
                value: isActive,
                onChanged: (value) {
                  context.read<AuthBloc>().add(ToggleSecurityFeature(
                        featureType: featureId,
                        enabled: value,
                      ));
                },
                activeColor: const Color(0xFFFFA726),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettings(AuthState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Advanced Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingCard(
          'Session Timeout',
          '${state.securityMetrics.sessionTimeoutMinutes} minutes',
          Icons.timer,
          () {
            // TODO: Show session timeout dialog
          },
        ),
        const SizedBox(height: 12),
        _buildSettingCard(
          'Emergency Protocols',
          state.securityMetrics.emergencyProtocolActive
              ? 'Enabled'
              : 'Disabled',
          Icons.emergency,
          () {
            context.read<AuthBloc>().add(ToggleEmergencyProtocols(
                  enabled: !state.securityMetrics.emergencyProtocolActive,
                ));
          },
        ),
        const SizedBox(height: 12),
        _buildSettingCard(
          'Export Configuration',
          'Backup security settings',
          Icons.file_download,
          () {
            context.read<AuthBloc>().add(const ExportSecurityConfiguration());
          },
        ),
        const SizedBox(height: 12),
        _buildSettingCard(
          'Reset to Defaults',
          'Restore factory settings',
          Icons.restore,
          () {
            _showResetConfirmation();
          },
        ),
      ],
    );
  }

  Widget _buildSettingCard(
      String title, String subtitle, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFFFFA726),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Reset Security Configuration?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will reset all security settings to defaults. This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(const ResetSecurityConfiguration());
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _getSecurityGradient(SecurityLevel level) {
    switch (level) {
      case SecurityLevel.militaryGrade:
        return const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case SecurityLevel.professional:
        return const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case SecurityLevel.strong:
        return const LinearGradient(
          colors: [Color(0xFFE65100), Color(0xFFFF9800)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF424242), Color(0xFF616161)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Color _getSecurityColor(SecurityLevel level) {
    switch (level) {
      case SecurityLevel.militaryGrade:
        return const Color(0xFF2E7D32);
      case SecurityLevel.professional:
        return const Color(0xFF1565C0);
      case SecurityLevel.strong:
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF616161);
    }
  }

  IconData _getSecurityIcon(SecurityLevel level) {
    switch (level) {
      case SecurityLevel.militaryGrade:
        return Icons.military_tech;
      case SecurityLevel.professional:
        return Icons.verified_user;
      case SecurityLevel.strong:
        return Icons.security;
      default:
        return Icons.shield;
    }
  }

  String _getSecurityLevelText(SecurityLevel level) {
    switch (level) {
      case SecurityLevel.militaryGrade:
        return 'MILITARY-GRADE';
      case SecurityLevel.professional:
        return 'PROFESSIONAL';
      case SecurityLevel.strong:
        return 'STRONG';
      case SecurityLevel.moderate:
        return 'MODERATE';
      case SecurityLevel.weak:
        return 'WEAK';
      case SecurityLevel.compromised:
        return 'COMPROMISED';
      default:
        return 'UNKNOWN';
    }
  }
}
