import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'bloc/notes_bloc.dart';
import 'bloc/notes_event.dart';
import 'bloc/notes_state.dart';
import '../../services/storage_service.dart';
import '../authentication/bloc/auth_bloc.dart';
import '../authentication/bloc/auth_event.dart';
import '../authentication/bloc/auth_state.dart';
import '../authentication/bloc/auth_coordinator.dart';
import 'add_edit_notes_page.dart';
import '../../features/secure_area/secure_area_main_page.dart';

class NotesPage extends StatefulWidget {
  final Function(
      bool isSelectionMode,
      int selectedCount,
      VoidCallback? onExitSelection,
      VoidCallback? onSelectAll)? onSelectionChanged;

  const NotesPage({super.key, this.onSelectionChanged});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  bool _isSelectionMode = false;
  Set<String> _selectedNoteIds = {};

  @override
  void initState() {
    super.initState();
    // Load notes when page starts
    context.read<NotesBloc>().add(const LoadNotes());

    // Add listener for search
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final searchText = _searchController.text;

    // Perform immediate search for better UX
    context.read<NotesBloc>().add(SearchNotes(searchText));

    // Cancel previous timer
    _debounceTimer?.cancel();

    // Only check password after user stops typing for 300ms
    if (searchText.trim().isNotEmpty) {
      _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
        if (mounted && searchText.trim().isNotEmpty) {
          context.read<AuthBloc>().add(VerifyPassword(searchText.trim()));
        }
      });
    }
  }

  void _enterSelectionMode(String noteId) {
    setState(() {
      _isSelectionMode = true;
      _selectedNoteIds.add(noteId);
    });
    _notifySelectionChanged();
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedNoteIds.clear();
    });
    _notifySelectionChanged();
  }

  void _toggleNoteSelection(String noteId) {
    setState(() {
      if (_selectedNoteIds.contains(noteId)) {
        _selectedNoteIds.remove(noteId);
        if (_selectedNoteIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedNoteIds.add(noteId);
      }
    });
    _notifySelectionChanged();
  }

  void _selectAllNotes() {
    final state = context.read<NotesBloc>().state;
    final visibleNotes =
        state.filteredNotes.where((note) => !note.isPasswordNote).toList();
    setState(() {
      _selectedNoteIds = visibleNotes.map((note) => note.id).toSet();
    });
    _notifySelectionChanged();
  }

  void _notifySelectionChanged() {
    if (widget.onSelectionChanged != null) {
      widget.onSelectionChanged!(
        _isSelectionMode,
        _selectedNoteIds.length,
        _exitSelectionMode,
        _selectAllNotes,
      );
    }
  }

  void _deleteSelectedNotes() {
    for (String noteId in _selectedNoteIds) {
      context.read<NotesBloc>().add(DeleteNote(noteId));
    }
    _exitSelectionMode();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated &&
            _searchController.text.trim().isNotEmpty) {
          // Password was correct from search bar, clear search and navigate to secure area
          _searchController.clear();

          // Navigate to secure area (replace current screen for security)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (newContext) => MultiBlocProvider(
                providers: [
                  BlocProvider.value(
                    value: context.read<AuthBloc>(),
                  ),
                  BlocProvider.value(
                    value: context.read<NotesBloc>(),
                  ),
                  BlocProvider.value(
                    value: context.read<AuthCoordinator>(),
                  ),
                ],
                child: const SecureAreaMainPage(),
              ),
            ),
          );
        }
      },
      child: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildNotesContent()),
          if (_isSelectionMode) _buildBottomActionBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.only(
        left: 24,
        right: 24,
      ),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: _isSelectionMode
              ? Colors.grey.withOpacity(0.05)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
        ),
        child: TextField(
          controller: _searchController,
          enabled: !_isSelectionMode,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: 'Search notes',
            hintStyle: TextStyle(
              color: _isSelectionMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.5),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: _isSelectionMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.5),
              size: 18,
            ),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildNotesContent() {
    return BlocBuilder<NotesBloc, NotesState>(
      builder: (context, state) {
        if (state.status == NotesStatus.loading) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFFA726),
            ),
          );
        }

        if (state.status == NotesStatus.error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red[400],
                ),
                const SizedBox(height: 16),
                Text(
                  state.errorMessage ?? 'Something went wrong',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<NotesBloc>().add(const LoadNotes());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA726),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Filter out password notes - they should remain secret
        final notes =
            state.filteredNotes.where((note) => !note.isPasswordNote).toList();

        if (notes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3C4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.folder_open,
                    size: 40,
                    color: Color(0xFFFFA726),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _searchController.text.isNotEmpty
                      ? 'No notes found'
                      : 'No notes here yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_searchController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Try searching for something else',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<NotesBloc>().add(const LoadNotes());
          },
          color: const Color(0xFFFFA726),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return _buildNoteCard(note);
            },
          ),
        );
      },
    );
  }

  Widget _buildNoteCard(Note note) {
    final isSelected = _selectedNoteIds.contains(note.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.orange.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isSelected
              ? const Color(0xFFFFA726)
              : Colors.grey.withOpacity(0.1),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (_isSelectionMode) {
              _toggleNoteSelection(note.id);
            } else {
              // Navigate to edit note page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (newContext) => MultiBlocProvider(
                    providers: [
                      BlocProvider.value(
                        value: context.read<AuthBloc>(),
                      ),
                      BlocProvider.value(
                        value: context.read<NotesBloc>(),
                      ),
                    ],
                    child: AddEditNotesPage(note: note),
                  ),
                ),
              );
            }
          },
          onLongPress: () {
            if (!_isSelectionMode) {
              _enterSelectionMode(note.id);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Selection indicator
                if (_isSelectionMode) ...[
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? const Color(0xFFFFA726)
                          : Colors.transparent,
                      border: Border.all(
                        color:
                            isSelected ? const Color(0xFFFFA726) : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                ],

                // Note content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              note.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black.withOpacity(0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (note.content.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          note.content,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.time,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(note.updatedAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.visibility_off,
            label: 'Hide',
            onTap: () {
              // TODO: Implement hide functionality
              _showSnackBar('Hide functionality coming soon');
            },
          ),
          _buildActionButton(
            icon: Icons.push_pin_outlined,
            label: 'Pin',
            onTap: () {
              // TODO: Implement pin functionality
              _showSnackBar('Pin functionality coming soon');
            },
          ),
          _buildActionButton(
            icon: Icons.delete_outline,
            label: 'Delete',
            onTap: _deleteSelectedNotes,
          ),
          _buildActionButton(
            icon: Icons.drive_file_move_outline,
            label: 'Move to',
            onTap: () {
              // TODO: Implement move functionality
              _showSnackBar('Move functionality coming soon');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final noteDate = DateTime(date.year, date.month, date.day);

    if (noteDate == today) {
      return 'Today ${_formatTime(date)}';
    } else if (noteDate == yesterday) {
      return 'Yesterday ${_formatTime(date)}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
}
