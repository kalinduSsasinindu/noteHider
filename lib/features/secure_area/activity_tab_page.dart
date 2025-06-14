import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../authentication/bloc/auth_bloc.dart';
import '../authentication/bloc/auth_state.dart';
import '../authentication/bloc/auth_event.dart';
import '../authentication/bloc/auth_coordinator.dart';

/// 📊 ACTIVITY TAB PAGE
///
/// Enhanced activity monitoring interface with AuthCoordinator integration
/// Shows basic authentication activity and security profile changes
class ActivityTabPage extends StatefulWidget {
  const ActivityTabPage({super.key});

  @override
  State<ActivityTabPage> createState() => _ActivityTabPageState();
}

class _ActivityTabPageState extends State<ActivityTabPage> {
  String _selectedFilter = 'all';
  List<Map<String, dynamic>> _recentActivities = [];

  final List<Map<String, dynamic>> _filters = [
    {'id': 'all', 'name': 'All Activity', 'icon': Icons.list},
    {'id': 'auth', 'name': 'Authentication', 'icon': Icons.login},
    {'id': 'security', 'name': 'Security Config', 'icon': Icons.security},
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentActivities();
  }

  void _loadRecentActivities() {
    // Simulate recent activities - in real app this would come from storage
    _recentActivities = [
      {
        'type': 'secure_area_access',
        'title': 'Secure Area Access',
        'description': 'Successfully entered secure area',
        'icon': Icons.security,
        'color': Colors.green,
        'timestamp': DateTime.now().subtract(const Duration(minutes: 2)),
      },
      {
        'type': 'password_auth',
        'title': 'Password Authentication',
        'description': 'Master password verified',
        'icon': Icons.key,
        'color': Colors.blue,
        'timestamp': DateTime.now().subtract(const Duration(minutes: 3)),
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        // Check if AuthCoordinator is available
        try {
          final coordinator = context.read<AuthCoordinator>();
          // If available, use the full listener
          return BlocListener<AuthCoordinator, AuthCoordinatorState>(
            listener: (context, coordinatorState) {
              // Track security profile changes
              if (coordinatorState.status ==
                  AuthCoordinatorStatus.configuringAdditionalSecurity) {
                _addActivity(
                  'Security Profile Change',
                  'Configuring ${coordinatorState.currentSecurityProfile} security profile',
                  Icons.shield,
                  Colors.orange,
                );
              } else if (coordinatorState.status ==
                  AuthCoordinatorStatus.fullyAuthenticated) {
                if (coordinatorState.multiFactorCompleted) {
                  _addActivity(
                    'Multi-Factor Authentication',
                    'All security factors completed successfully',
                    Icons.verified_user,
                    Colors.green,
                  );
                }
              }
            },
            child: _buildContent(),
          );
        } catch (e) {
          // AuthCoordinator not available, show basic content
          print('⚠️ AuthCoordinator not available in ActivityTabPage: $e');
          return _buildContent();
        }
      },
    );
  }

  Widget _buildContent() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        // Try to get AuthCoordinator state, but handle gracefully if not available
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
              print('⚠️ AuthCoordinator not available for BlocBuilder: $e');
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
      body: Column(
        children: [
          // Enhanced Status Card
          _buildEnhancedStatusCard(authState, coordinatorState),

          // Activity Filters
          _buildActivityFilters(),

          // Activity Content
          Expanded(
            child: _buildActivityContent(authState, coordinatorState),
          ),
        ],
      ),
      floatingActionButton: _buildBasicActionsFAB(),
    );
  }

  void _addActivity(
      String title, String description, IconData icon, Color color) {
    if (mounted) {
      setState(() {
        _recentActivities.insert(0, {
          'type': 'security_change',
          'title': title,
          'description': description,
          'icon': icon,
          'color': color,
          'timestamp': DateTime.now(),
        });

        // Keep only last 20 activities
        if (_recentActivities.length > 20) {
          _recentActivities = _recentActivities.take(20).toList();
        }
      });
    }
  }

  Widget _buildEnhancedStatusCard(
      AuthState authState, AuthCoordinatorState coordinatorState) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF424242), Color(0xFF616161)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  coordinatorState.canAccessSecureArea
                      ? Icons.check_circle
                      : Icons.info,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coordinatorState.canAccessSecureArea
                          ? '✅ SECURE ACCESS GRANTED'
                          : '⚪ AUTHENTICATION PENDING',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Profile: ${coordinatorState.currentSecurityProfile?.toUpperCase() ?? 'BASIC'}',
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatusMetric(
                  'Password',
                  authState.isPasswordSet ? 'SET' : 'NOT SET',
                  Icons.lock,
                ),
              ),
              Expanded(
                child: _buildStatusMetric(
                  'Additional Auth',
                  coordinatorState.multiFactorCompleted ? 'ACTIVE' : 'BASIC',
                  Icons.fingerprint,
                ),
              ),
              Expanded(
                child: _buildStatusMetric(
                  'Security Mode',
                  coordinatorState.canAccessSecureArea ? 'SECURE' : 'LOCKED',
                  Icons.shield,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityContent(
      AuthState authState, AuthCoordinatorState coordinatorState) {
    final filteredActivities = _getFilteredActivities();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 16),

        // Recent activity items
        ...filteredActivities.map((activity) => _buildActivityItem(
              activity['title'],
              activity['description'],
              activity['icon'],
              activity['color'],
              activity['timestamp'],
            )),

        // If no activities
        if (filteredActivities.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(
                  Icons.history,
                  size: 60,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 16),
                Text(
                  'No activity found',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Activity will appear here as you use the app',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

        const SizedBox(height: 100), // Space for FAB
      ],
    );
  }

  List<Map<String, dynamic>> _getFilteredActivities() {
    if (_selectedFilter == 'all') {
      return _recentActivities;
    } else if (_selectedFilter == 'auth') {
      return _recentActivities
          .where((activity) =>
              activity['type'] == 'password_auth' ||
              activity['type'] == 'secure_area_access')
          .toList();
    } else if (_selectedFilter == 'security') {
      return _recentActivities
          .where((activity) => activity['type'] == 'security_change')
          .toList();
    }
    return _recentActivities;
  }

  Widget _buildActivityItem(String title, String subtitle, IconData icon,
      Color color, DateTime timestamp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatTimestamp(timestamp),
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _buildActivityFilters() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter['id'];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter['id'];
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFFA726) : Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isSelected ? const Color(0xFFFFA726) : Colors.grey[800]!,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filter['icon'],
                    color: isSelected ? Colors.black : Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    filter['name'],
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBasicActionsFAB() {
    return FloatingActionButton.extended(
      onPressed: _showBasicActions,
      backgroundColor: const Color(0xFFFFA726),
      icon: const Icon(Icons.settings, color: Colors.black),
      label: const Text(
        'Actions',
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _showBasicActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Basic Actions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            _buildActionOption(
              'Lock App',
              'Immediately lock the application',
              Icons.lock,
              Colors.blue,
              () {
                Navigator.pop(context);
                context.read<AuthBloc>().add(const LockApp());
              },
            ),
            _buildActionOption(
              'Reset App',
              'Clear all data and restart',
              Icons.restore,
              Colors.red,
              () {
                Navigator.pop(context);
                _showResetConfirmation();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionOption(String title, String subtitle, IconData icon,
      Color color, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: color,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 14,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: Colors.white.withOpacity(0.5),
        size: 16,
      ),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Reset Application',
          style: TextStyle(color: Colors.red),
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
              'RESET NOW',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.7),
          size: 16,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
