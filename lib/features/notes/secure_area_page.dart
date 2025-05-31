import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../authentication/bloc/auth_bloc.dart';
import '../authentication/bloc/auth_event.dart';
import '../../homepage.dart';

class SecureAreaPage extends StatefulWidget {
  const SecureAreaPage({super.key});

  @override
  State<SecureAreaPage> createState() => _SecureAreaPageState();
}

class _SecureAreaPageState extends State<SecureAreaPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Add observer to detect app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Remove observer when widget is disposed
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // When app comes back to foreground from background, navigate to homepage for security
    if (state == AppLifecycleState.resumed) {
      // Check if widget is still mounted and context is valid
      if (!mounted || !context.mounted) {
        return;
      }

      // Just navigate directly without trying to access potentially closed blocs
      print('🔒 App resumed - navigating to homepage for security');
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/',
        (route) => false,
      );
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
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/',
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    const Spacer(),
                    const Text(
                      'Secure Area',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        // TODO: Add secure area settings
                      },
                      icon: const Icon(
                        Icons.settings,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Lock icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA726).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: const Icon(
                    CupertinoIcons.lock_shield_fill,
                    size: 60,
                    color: Color(0xFFFFA726),
                  ),
                ),

                const SizedBox(height: 32),

                // Welcome text
                const Text(
                  'Welcome to the Secure Area',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                Text(
                  'This is a protected space where you can store your most sensitive information.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 60),

                // Action buttons
                Column(
                  children: [
                    _buildActionButton(
                      icon: CupertinoIcons.doc_text_fill,
                      title: 'Secure Notes',
                      subtitle: 'Create and manage private notes',
                      onTap: () {
                        // TODO: Navigate to secure notes
                        _showSnackBar(context, 'Secure notes coming soon');
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildActionButton(
                      icon: CupertinoIcons.photo_fill,
                      title: 'Secure Media',
                      subtitle: 'Store photos and videos privately',
                      onTap: () {
                        // TODO: Navigate to secure media
                        _showSnackBar(context, 'Secure media coming soon');
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildActionButton(
                      icon: CupertinoIcons.folder_fill,
                      title: 'Secure Files',
                      subtitle: 'Hide important documents',
                      onTap: () {
                        // TODO: Navigate to secure files
                        _showSnackBar(context, 'Secure files coming soon');
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildActionButton(
                      icon: CupertinoIcons.lock_fill,
                      title: 'Lock App',
                      subtitle: 'Return to main area',
                      onTap: () {
                        try {
                          // Lock the app and navigate back to homepage
                          context.read<AuthBloc>().add(const LockApp());

                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/',
                            (route) => false,
                          );
                        } catch (e) {
                          // If bloc is closed, just navigate
                          print('🔴 Manual lock error: $e');
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/',
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[800]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA726).withOpacity(0.2),
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
                          fontSize: 18,
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
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
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
