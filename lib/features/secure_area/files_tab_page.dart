import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../services/file_manager_service.dart';

/// 📁 FILES TAB PAGE
///
/// Main file management interface with:
/// • File category filtering
/// • Grid/List view toggle
/// • Search functionality
/// • Import/Export operations
/// • Bulk file operations
class FilesTabPage extends StatefulWidget {
  const FilesTabPage({super.key});

  @override
  State<FilesTabPage> createState() => _FilesTabPageState();
}

class _FilesTabPageState extends State<FilesTabPage> {
  String _selectedCategory = 'all';
  bool _isGridView = true;
  bool _isSelectionMode = false;
  final Set<String> _selectedFiles = {};
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'all',
      'name': 'All Files',
      'icon': Icons.folder,
      'color': Colors.grey
    },
    {
      'id': 'photos',
      'name': 'Photos',
      'icon': Icons.photo,
      'color': Colors.green
    },
    {
      'id': 'videos',
      'name': 'Videos',
      'icon': Icons.videocam,
      'color': Colors.red
    },
    {
      'id': 'documents',
      'name': 'Documents',
      'icon': Icons.description,
      'color': Colors.blue
    },
    {
      'id': 'music',
      'name': 'Music',
      'icon': Icons.music_note,
      'color': Colors.purple
    },
    {
      'id': 'archives',
      'name': 'Archives',
      'icon': Icons.archive,
      'color': Colors.orange
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Category tabs
          _buildCategoryTabs(),

          // Search and view controls
          _buildSearchAndControls(),

          // File grid/list
          Expanded(
            child: _buildFileView(),
          ),

          // Bulk actions (when in selection mode)
          if (_isSelectionMode) _buildBulkActions(),
        ],
      ),
      floatingActionButton: _buildImportFAB(),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category['id'];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category['id'];
                _isSelectionMode = false;
                _selectedFiles.clear();
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
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
                    category['icon'],
                    color: isSelected ? Colors.black : Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category['name'],
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

  Widget _buildSearchAndControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          // Search bar
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search files...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.white.withOpacity(0.5),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (value) {
                  // TODO: Implement file search
                },
              ),
            ),
          ),

          const SizedBox(width: 16),

          // View toggle
          GestureDetector(
            onTap: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Icon(
                _isGridView ? Icons.list : Icons.grid_view,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileView() {
    // TODO: Replace with actual file data from FileManagerService
    return _buildEmptyState();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              _selectedCategory == 'all'
                  ? Icons.folder_open
                  : _getCategoryIcon(_selectedCategory),
              color: const Color(0xFFFFA726),
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _selectedCategory == 'all'
                ? 'No files yet'
                : 'No ${_getCategoryName(_selectedCategory).toLowerCase()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Import files to get started with secure storage',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActions() {
    return Container(
      height: 60,
      color: Colors.grey[900],
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(
            '${_selectedFiles.length} selected',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () {
              // TODO: Export selected files
            },
            icon: const Icon(Icons.file_download, color: Color(0xFFFFA726)),
            label: const Text('Export',
                style: TextStyle(color: Color(0xFFFFA726))),
          ),
          const SizedBox(width: 16),
          TextButton.icon(
            onPressed: () {
              // TODO: Delete selected files
            },
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildImportFAB() {
    return FloatingActionButton(
      onPressed: () {
        _showImportOptions();
      },
      backgroundColor: const Color(0xFFFFA726),
      child: const Icon(
        Icons.add,
        color: Colors.black,
        size: 28,
      ),
    );
  }

  void _showImportOptions() {
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
            _buildImportOption(
              icon: Icons.photo_library,
              title: 'Import from Gallery',
              subtitle: 'Select photos and videos',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement gallery import
              },
            ),
            _buildImportOption(
              icon: Icons.folder,
              title: 'Import from Files',
              subtitle: 'Select any file type',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement file import
              },
            ),
            _buildImportOption(
              icon: Icons.camera_alt,
              title: 'Take Photo/Video',
              subtitle: 'Capture directly to secure area',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement camera capture
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
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

  IconData _getCategoryIcon(String categoryId) {
    final category = _categories.firstWhere((cat) => cat['id'] == categoryId);
    return category['icon'];
  }

  String _getCategoryName(String categoryId) {
    final category = _categories.firstWhere((cat) => cat['id'] == categoryId);
    return category['name'];
  }
}
