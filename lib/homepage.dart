import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/tab_bloc.dart';
import 'bloc/tab_event.dart';
import 'bloc/tab_state.dart';
import 'features/notes/add_edit_notes_page.dart';
import 'features/notes/notes_page.dart';
import 'features/authentication/bloc/auth_bloc.dart';
import 'features/notes/bloc/notes_bloc.dart';

class NotesHomePage extends StatefulWidget {
  const NotesHomePage({super.key});

  @override
  State<NotesHomePage> createState() => _NotesHomePageState();
}

class _NotesHomePageState extends State<NotesHomePage> {
  final TextEditingController _tasksSearchController = TextEditingController();
  final PageController _pageController = PageController();

  // Selection state
  bool _isNotesSelectionMode = false;
  int _selectedNotesCount = 0;
  VoidCallback? _onExitSelection;
  VoidCallback? _onSelectAll;

  void _onNotesSelectionChanged(
    bool isSelectionMode,
    int selectedCount,
    VoidCallback? onExitSelection,
    VoidCallback? onSelectAll,
  ) {
    setState(() {
      _isNotesSelectionMode = isSelectionMode;
      _selectedNotesCount = selectedCount;
      _onExitSelection = onExitSelection;
      _onSelectAll = onSelectAll;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<TabBloc, TabState>(
        listener: (context, state) {
          // Animate to the correct page when tab state changes
          _pageController.animateToPage(
            state.selectedTabIndex,
            duration: const Duration(milliseconds: 150),
            curve: Curves.ease,
          );
        },
        builder: (context, state) {
          return Column(
            children: [
              // Add some top padding for status bar
              const SizedBox(height: 30),
              // Tab Navigation or Selection Header
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: _isNotesSelectionMode && state.selectedTabIndex == 0
                    ? _buildSelectionHeader()
                    : _buildTabNavigation(state),
              ),
              // Content with PageView for swipe functionality
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    context.read<TabBloc>().add(TabChanged(index));
                  },
                  children: [
                    NotesPage(onSelectionChanged: _onNotesSelectionChanged),
                    _buildTasksPage(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: BlocBuilder<TabBloc, TabState>(
        builder: (context, state) {
          return FloatingActionButton(
            onPressed: () {
              if (state.selectedTabType == TabType.notes) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (newContext) => MultiBlocProvider(
                      providers: [
                        BlocProvider.value(
                          value: context.read<AuthBloc>(),
                        ),
                        BlocProvider.value(
                          value: context.read<TabBloc>(),
                        ),
                        BlocProvider.value(
                          value: context.read<NotesBloc>(),
                        ),
                      ],
                      child: const AddEditNotesPage(),
                    ),
                  ),
                );
              } else {
                // TODO: Add new task functionality
              }
            },
            backgroundColor: const Color(0xFFFFA726),
            child: Icon(
              state.selectedTabType == TabType.notes
                  ? Icons.add
                  : Icons.add_task,
              color: Colors.white,
              size: 28,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectionHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: _onExitSelection,
          icon: const Icon(Icons.close),
          iconSize: 24,
        ),
        const SizedBox(width: 8),
        Text(
          '$_selectedNotesCount item${_selectedNotesCount != 1 ? 's' : ''} selected',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: _onSelectAll,
          icon: const Icon(Icons.select_all),
          iconSize: 24,
        ),
      ],
    );
  }

  Widget _buildTabNavigation(TabState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTabIcon(
          icon: CupertinoIcons.doc_text,
          selectedIcon: CupertinoIcons.doc_text_fill,
          label: 'Notes',
          isSelected: state.selectedTabIndex == 0,
          onTap: () => context.read<TabBloc>().add(const TabChanged(0)),
        ),
        const SizedBox(width: 10),
        _buildTabIcon(
          icon: CupertinoIcons.list_bullet,
          selectedIcon: CupertinoIcons.list_bullet_below_rectangle,
          label: 'Tasks',
          isSelected: state.selectedTabIndex == 1,
          onTap: () => context.read<TabBloc>().add(const TabChanged(1)),
        ),
      ],
    );
  }

  Widget _buildTabIcon({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Icon(
          isSelected ? selectedIcon : icon,
          color: isSelected ? const Color(0xFFFFA726) : Colors.grey[600],
          size: 26,
        ),
      ),
    );
  }

  Widget _buildSearchBar(TextEditingController controller, String hintText) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 24,
        right: 24,
      ),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
        ),
        child: TextField(
          controller: controller,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.black.withOpacity(0.5),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.black.withOpacity(0.5),
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

  Widget _buildTasksPage() {
    return Column(
      children: [
        _buildSearchBar(_tasksSearchController, 'Search tasks'),
        Expanded(child: _buildTasksContent()),
      ],
    );
  }

  Widget _buildTasksContent() {
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
              Icons.assignment_outlined,
              size: 40,
              color: Color(0xFFFFA726),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No tasks here yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tasksSearchController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}
