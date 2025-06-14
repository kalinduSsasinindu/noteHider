import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../authentication/bloc/auth_bloc.dart';
import '../authentication/bloc/auth_state.dart';
import '../authentication/bloc/auth_event.dart';
import '../authentication/bloc/auth_coordinator.dart';
import '../../services/security_config_service.dart';

/// 🛡️ SECURITY TAB PAGE
///
/// Security configuration and monitoring interface
/// Now includes additional security layer configuration via AuthCoordinator
class SecurityTabPage extends StatefulWidget {
  const SecurityTabPage({super.key});

  @override
  State<SecurityTabPage> createState() => _SecurityTabPageState();
}

class _SecurityTabPageState extends State<SecurityTabPage> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        return Builder(
          builder: (context) {
            try {
              return BlocBuilder<AuthCoordinator, AuthCoordinatorState>(
                builder: (context, coordinatorState) {
                  return _buildScaffold(authState, coordinatorState);
                },
              );
            } catch (e) {
              // AuthCoordinator not available, use default state
              print('⚠️ AuthCoordinator not available in SecurityTabPage: $e');
              const defaultCoordinatorState = AuthCoordinatorState.initial();
              return _buildScaffold(authState, defaultCoordinatorState);
            }
          },
        );
      },
    );
  }

  Widget _buildScaffold(
      AuthState authState, AuthCoordinatorState coordinatorState) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Security Status Card
            _buildEnhancedSecurityCard(authState, coordinatorState),

            const SizedBox(height: 24),

            // Security Profile Configuration
            _buildSecurityProfileSection(coordinatorState),

            const SizedBox(height: 24),

            // Basic Settings
            _buildBasicSettings(authState),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedSecurityCard(
      AuthState authState, AuthCoordinatorState coordinatorState) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF424242), Color(0xFF616161)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
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
                    'Security Status',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    coordinatorState.canAccessSecureArea ? 'SECURE' : 'PENDING',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
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
                  coordinatorState.canAccessSecureArea
                      ? Icons.security
                      : Icons.security_outlined,
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
                      'Profile: ${coordinatorState.currentSecurityProfile?.toUpperCase() ?? 'BASIC'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Password: ${authState.isPasswordSet ? "✅" : "❌"} | Additional: ${coordinatorState.multiFactorCompleted ? "✅" : "⚪"}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityProfileSection(AuthCoordinatorState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Security Profiles',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Configure additional security layers for enhanced protection',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),

        // Security Profile Options
        _buildProfileOption(
          'Basic',
          'Password only authentication',
          Icons.lock,
          Colors.blue,
          state.currentSecurityProfile == 'basic',
          () => _enableSecurityProfile('basic'),
        ),
        const SizedBox(height: 12),
        _buildProfileOption(
          'Professional',
          'Password + Biometric authentication',
          Icons.fingerprint,
          Colors.green,
          state.currentSecurityProfile == 'professional',
          () => _enableSecurityProfile('professional'),
        ),
        const SizedBox(height: 12),
        _buildProfileOption(
          'Military',
          'Password + Biometric + Location + TOTP',
          Icons.shield,
          Colors.orange,
          state.currentSecurityProfile == 'military',
          () => _enableSecurityProfile('military'),
        ),
        const SizedBox(height: 12),
        _buildProfileOption(
          'Paranoid',
          'All security features enabled',
          Icons.gpp_maybe,
          Colors.red,
          state.currentSecurityProfile == 'paranoid',
          () => _enableSecurityProfile('paranoid'),
        ),
      ],
    );
  }

  Widget _buildProfileOption(
    String title,
    String description,
    IconData icon,
    Color color,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey[800]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.3) : Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? color : const Color(0xFFFFA726),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isSelected ? color : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.check_circle,
                          color: color,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
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

  Widget _buildBasicSettings(AuthState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Basic Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingCard(
          'Lock App',
          'Immediately lock the application',
          Icons.lock,
          () {
            try {
              context.read<AuthCoordinator>().add(const LockApplication());
            } catch (e) {
              // Fallback to AuthBloc if AuthCoordinator is not available
              try {
                context.read<AuthBloc>().add(const LockApp());
              } catch (e2) {
                print('⚠️ No auth system available for lock: $e2');
              }
            }
          },
        ),
        const SizedBox(height: 12),
        _buildSettingCard(
          'Reset App',
          'Clear all data and restart',
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

  void _enableSecurityProfile(String profileType) {
    try {
      context
          .read<AuthCoordinator>()
          .add(EnableAdditionalSecurity(profileType));
      _showSnackBar('Configuring $profileType security profile...');
    } catch (e) {
      print('⚠️ AuthCoordinator not available for security profile change: $e');
      _showSnackBar('Security profile configuration not available');
    }
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Reset Application?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will clear all data and reset the app to initial state. This action cannot be undone.',
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
              context.read<AuthBloc>().add(const ResetApp());
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

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFFFA726),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}
