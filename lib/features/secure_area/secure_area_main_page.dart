import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../authentication/bloc/auth_bloc.dart';
import '../authentication/bloc/auth_event.dart';
import '../authentication/bloc/auth_coordinator.dart';
import 'activity_tab_page.dart';
import 'files_tab_page.dart';
import 'security_tab_page.dart';

/// 🔐 SECURE AREA MAIN PAGE
///
/// Main interface for the secure area with tabbed navigation:
/// • Activity - Security monitoring and audit logs
/// • Files - Secure file management and hiding
/// • Security - Authentication and security configuration
class SecureAreaMainPage extends StatefulWidget {
  const SecureAreaMainPage({super.key});

  @override
  State<SecureAreaMainPage> createState() => _SecureAreaMainPageState();
}

class _SecureAreaMainPageState extends State<SecureAreaMainPage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _tabs = [
    {
      'id': 'activity',
      'title': 'Activity',
      'icon': Icons.analytics,
      'activeIcon': Icons.analytics,
    },
    {
      'id': 'files',
      'title': 'Files',
      'icon': Icons.folder_outlined,
      'activeIcon': Icons.folder,
    },
    {
      'id': 'security',
      'title': 'Security',
      'icon': Icons.security_outlined,
      'activeIcon': Icons.security,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabChange);

    // Add observer to detect app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // When app comes back to foreground from background, navigate to homepage for security
    if (state == AppLifecycleState.resumed) {
      if (!mounted || !context.mounted) return;

      print('🔒 App resumed - navigating to homepage for security');
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  void _handleTabChange() {
    if (mounted) {
      setState(() {
        _currentIndex = _tabController.index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent default back navigation
      onPopInvoked: (didPop) async {
        if (!didPop) {
          // Back button was pressed - navigate to homepage for security
          print('🔒 Back button pressed - navigating to homepage for security');
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              // Header with lock button
              _buildHeader(),

              // Custom tab bar
              _buildCustomTabBar(),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    ActivityTabPage(),
                    FilesTabPage(),
                    SecurityTabPage(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Lock indicator
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFA726).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.lock_open,
              color: Color(0xFFFFA726),
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          // Title
          const Expanded(
            child: Text(
              'Secure Area',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Quick lock button
          GestureDetector(
            onTap: _lockAndExit,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: const Icon(
                Icons.lock,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        children: _tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = _currentIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                _tabController.animateTo(index);
              },
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color:
                      isSelected ? const Color(0xFFFFA726) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isSelected ? tab['activeIcon'] : tab['icon'],
                      color: isSelected ? Colors.black : Colors.white,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tab['title'],
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _lockAndExit() {
    try {
      // Lock through coordinator
      context.read<AuthCoordinator>().add(const LockApplication());

      // Navigate back to homepage
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      // If coordinator is not available, try AuthBloc
      try {
        context.read<AuthBloc>().add(const LockApp());
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      } catch (e2) {
        // If all fails, just navigate
        print('🔴 Lock error: $e2');
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }
}
