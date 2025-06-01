import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../authentication/bloc/auth_bloc.dart';
import '../authentication/bloc/auth_state.dart';
import '../authentication/bloc/auth_event.dart';

/// 📊 ACTIVITY TAB PAGE
///
/// Security monitoring and activity dashboard with:
/// • Real-time threat status
/// • Security event timeline
/// • Activity metrics and statistics
/// • Emergency action controls
/// • Security audit logs
class ActivityTabPage extends StatefulWidget {
  const ActivityTabPage({super.key});

  @override
  State<ActivityTabPage> createState() => _ActivityTabPageState();
}

class _ActivityTabPageState extends State<ActivityTabPage> {
  String _selectedFilter = 'all';

  final List<Map<String, dynamic>> _filters = [
    {'id': 'all', 'name': 'All Activity', 'icon': Icons.list},
    {'id': 'security', 'name': 'Security Events', 'icon': Icons.security},
    {'id': 'threats', 'name': 'Threats', 'icon': Icons.warning},
    {'id': 'auth', 'name': 'Authentication', 'icon': Icons.login},
    {'id': 'files', 'name': 'File Access', 'icon': Icons.folder},
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Column(
            children: [
              // Threat Status Card
              _buildThreatStatusCard(state),

              // Activity Filters
              _buildActivityFilters(),

              // Activity Timeline
              Expanded(
                child: _buildActivityTimeline(state),
              ),
            ],
          ),
          floatingActionButton: _buildEmergencyFAB(),
        );
      },
    );
  }

  Widget _buildThreatStatusCard(AuthState state) {
    final threatLevel = state.securityMetrics.threatLevel;
    final lastAudit = state.securityMetrics.lastSecurityAudit;

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: _getThreatGradient(threatLevel),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _getThreatColor(threatLevel).withOpacity(0.3),
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
                  _getThreatIcon(threatLevel),
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
                      state.threatIndicator,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getThreatDescription(threatLevel),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  context.read<AuthBloc>().add(const PerformSecurityAudit());
                },
                child: const Text(
                  'Scan',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatusMetric(
                  'Active Threats',
                  '${state.securityMetrics.activeThreats.length}',
                  Icons.warning,
                ),
              ),
              Expanded(
                child: _buildStatusMetric(
                  'Failed Attempts',
                  '${state.securityMetrics.failedAttempts}',
                  Icons.block,
                ),
              ),
              Expanded(
                child: _buildStatusMetric(
                  'Last Scan',
                  lastAudit != null ? _formatTime(lastAudit) : 'Never',
                  Icons.schedule,
                ),
              ),
            ],
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
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

  Widget _buildActivityTimeline(AuthState state) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Security metrics summary
        _buildMetricsGrid(state),

        const SizedBox(height: 24),

        const Text(
          'Recent Activity',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 16),

        // Activity items
        ...state.securityLog
            .take(10)
            .map((logEntry) => _buildActivityItem(logEntry))
            .toList(),

        if (state.securityLog.isEmpty) _buildEmptyState(),

        const SizedBox(height: 100), // Space for FAB
      ],
    );
  }

  Widget _buildMetricsGrid(AuthState state) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildMetricCard(
          'Security Score',
          '${state.securityMetrics.securityScore.toStringAsFixed(1)}/10',
          Icons.security,
          _getScoreColor(state.securityMetrics.securityScore),
        ),
        _buildMetricCard(
          'Active Features',
          '${state.securityMetrics.enabledFeaturesCount}',
          Icons.verified_user,
          const Color(0xFFFFA726),
        ),
        _buildMetricCard(
          'Device Status',
          state.isDeviceBound ? 'Bound' : 'Unbound',
          Icons.devices,
          state.isDeviceBound ? Colors.green : Colors.orange,
        ),
        _buildMetricCard(
          'Session Time',
          '${state.securityMetrics.sessionTimeoutMinutes}m',
          Icons.timer,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
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
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String logEntry) {
    // Parse log entry (simplified)
    final icon = _getActivityIcon(logEntry);
    final color = _getActivityColor(logEntry);
    final time = DateTime.now().subtract(Duration(minutes: 5)); // Placeholder

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
                  logEntry,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(time),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              Icons.timeline,
              color: Colors.white.withOpacity(0.5),
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No activity yet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Security events will appear here',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyFAB() {
    return FloatingActionButton.extended(
      onPressed: _showEmergencyOptions,
      backgroundColor: Colors.red,
      icon: const Icon(Icons.emergency, color: Colors.white),
      label: const Text(
        'Emergency',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _showEmergencyOptions() {
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
              'Emergency Actions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            _buildEmergencyOption(
              'Security Scan',
              'Run immediate threat detection',
              Icons.security,
              Colors.orange,
              () {
                Navigator.pop(context);
                context.read<AuthBloc>().add(const PerformSecurityAudit());
              },
            ),
            _buildEmergencyOption(
              'Emergency Wipe',
              'Destroy all data immediately',
              Icons.delete_forever,
              Colors.red,
              () {
                Navigator.pop(context);
                _showWipeConfirmation();
              },
            ),
            _buildEmergencyOption(
              'Lock App',
              'Immediately lock the application',
              Icons.lock,
              Colors.blue,
              () {
                Navigator.pop(context);
                context.read<AuthBloc>().add(const LockApp());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyOption(String title, String subtitle, IconData icon,
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

  void _showWipeConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Emergency Wipe',
          style: TextStyle(color: Colors.red),
        ),
        content: const Text(
          'This will permanently destroy all encrypted data. This action cannot be undone.',
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
              context
                  .read<AuthBloc>()
                  .add(const TriggerEmergencyProtocol('Manual emergency wipe'));
            },
            child: const Text(
              'WIPE NOW',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  LinearGradient _getThreatGradient(ThreatLevel level) {
    switch (level) {
      case ThreatLevel.critical:
      case ThreatLevel.emergency:
        return const LinearGradient(
          colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ThreatLevel.high:
        return const LinearGradient(
          colors: [Color(0xFFE65100), Color(0xFFFF9800)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ThreatLevel.medium:
        return const LinearGradient(
          colors: [Color(0xFFF57F17), Color(0xFFFFEB3B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Color _getThreatColor(ThreatLevel level) {
    switch (level) {
      case ThreatLevel.critical:
      case ThreatLevel.emergency:
        return Colors.red;
      case ThreatLevel.high:
        return Colors.orange;
      case ThreatLevel.medium:
        return Colors.yellow;
      default:
        return Colors.green;
    }
  }

  IconData _getThreatIcon(ThreatLevel level) {
    switch (level) {
      case ThreatLevel.critical:
      case ThreatLevel.emergency:
        return Icons.dangerous;
      case ThreatLevel.high:
        return Icons.warning;
      case ThreatLevel.medium:
        return Icons.info;
      default:
        return Icons.verified_user;
    }
  }

  String _getThreatDescription(ThreatLevel level) {
    switch (level) {
      case ThreatLevel.emergency:
        return 'Immediate action required';
      case ThreatLevel.critical:
        return 'Severe security threat detected';
      case ThreatLevel.high:
        return 'Security concern detected';
      case ThreatLevel.medium:
        return 'Minor security issue';
      case ThreatLevel.low:
        return 'Minimal security risk';
      default:
        return 'All systems secure';
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 9.0) return Colors.green;
    if (score >= 7.0) return Colors.orange;
    if (score >= 5.0) return Colors.yellow;
    return Colors.red;
  }

  IconData _getActivityIcon(String logEntry) {
    if (logEntry.contains('authenticated') || logEntry.contains('login'))
      return Icons.login;
    if (logEntry.contains('threat') || logEntry.contains('detected'))
      return Icons.warning;
    if (logEntry.contains('security') || logEntry.contains('audit'))
      return Icons.security;
    if (logEntry.contains('file') || logEntry.contains('encrypted'))
      return Icons.folder;
    return Icons.info;
  }

  Color _getActivityColor(String logEntry) {
    if (logEntry.contains('threat') || logEntry.contains('failed'))
      return Colors.red;
    if (logEntry.contains('warning') || logEntry.contains('suspicious'))
      return Colors.orange;
    if (logEntry.contains('success') || logEntry.contains('completed'))
      return Colors.green;
    return const Color(0xFFFFA726);
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}
