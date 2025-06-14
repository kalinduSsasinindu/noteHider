import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notehider/features/authentication/bloc/auth_event.dart';
import 'package:notehider/features/authentication/bloc/auth_state.dart';
import 'package:notehider/features/authentication/bloc/auth_bloc.dart';
import 'package:notehider/features/notes/bloc/notes_bloc.dart';
import 'package:notehider/features/notes/bloc/notes_event.dart';
import 'package:notehider/features/notes/bloc/notes_state.dart';
import '../../services/storage_service.dart';
import '../../features/secure_area/secure_area_main_page.dart';
import 'package:notehider/features/authentication/bloc/auth_coordinator.dart';

class AddEditNotesPage extends StatefulWidget {
  final Note? note; // null for new note, Note object for editing

  const AddEditNotesPage({super.key, this.note});

  @override
  State<AddEditNotesPage> createState() => _AddEditNotesPageState();
}

class _AddEditNotesPageState extends State<AddEditNotesPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  bool get isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    // If editing, populate fields with existing note data
    if (isEditing) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: MultiBlocListener(
          listeners: [
            BlocListener<AuthBloc, AuthState>(
              listener: (context, state) {
                // Debug print to see what's happening
                print(
                    '🔍 AuthBloc State: ${state.status}, error: ${state.errorMessage}');

                if (state.status == AuthStatus.authenticated &&
                    context.read<NotesBloc>().state.isCheckingPassword) {
                  // Password was verified successfully, navigate to hidden area
                  print('✅ Password correct - navigating to hidden area');
                  context.read<NotesBloc>().add(const StopPasswordCheck());
                  _navigateToHiddenArea();
                } else if (state.status == AuthStatus.locked &&
                    context.read<NotesBloc>().state.isCheckingPassword) {
                  // Password verification failed, save as regular note
                  print('❌ Password incorrect - saving as regular note');
                  context.read<NotesBloc>().add(const StopPasswordCheck());
                  if (isEditing) {
                    _updateNote();
                  } else {
                    _saveAsRegularNote();
                  }
                } else if (state.status == AuthStatus.authenticated &&
                    !context.read<NotesBloc>().state.isCheckingPassword) {
                  // First time password setup completed, save password note
                  print('🆕 First time setup complete - saving password note');
                  _savePasswordNote();
                } else if (state.errorMessage != null &&
                    !context.read<NotesBloc>().state.isCheckingPassword) {
                  // Reset loading state on any authentication error
                  context.read<NotesBloc>().add(const StopAddNotesLoading());
                } else if (state.errorMessage != null &&
                    context.read<NotesBloc>().state.isCheckingPassword) {
                  // Handle authentication errors during password check
                  print(
                      '🔴 Auth error during password check: ${state.errorMessage}');
                  context.read<NotesBloc>().add(const StopPasswordCheck());
                  if (isEditing) {
                    _updateNote();
                  } else {
                    _saveAsRegularNote();
                  }
                }
              },
            ),
            BlocListener<NotesBloc, NotesState>(
              listener: (context, state) {
                if (state.status == NotesStatus.saved) {
                  // Loading state is automatically reset by SaveNote handler
                  // Don't navigate back automatically - only when back button is pressed
                } else if (state.status == NotesStatus.error &&
                    state.errorMessage != null) {
                  // Loading state is automatically reset by SaveNote handler on error
                }
              },
            ),
          ],
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              final isFirstTimeSetup =
                  authState.status == AuthStatus.firstTimeSetup;

              return Column(
                children: [
                  // Top navigation bar with save button
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.black,
                              size: 24,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Save button
                        BlocBuilder<NotesBloc, NotesState>(
                          builder: (context, notesState) {
                            final isLoading = isEditing
                                ? (notesState.status == NotesStatus.updating ||
                                    notesState.status == NotesStatus.saving)
                                : (notesState.isAddNotesLoading ||
                                    notesState.isCheckingPassword ||
                                    notesState.status == NotesStatus.saving);

                            return GestureDetector(
                              onTap: isLoading
                                  ? null
                                  : () => _handleSave(isFirstTimeSetup),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFFFFA726),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.check,
                                      color: Color(0xFFFFA726),
                                      size: 28,
                                    ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Content area
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // First time setup hint (only for new notes)
                          if (isFirstTimeSetup && !isEditing)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3C4),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                      const Color(0xFFFFA726).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.lock_shield,
                                    color: const Color(0xFFFFA726),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Your first note title will be your secret key',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFFB8860B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Title field
                          TextField(
                            controller: _titleController,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText: isFirstTimeSetup && !isEditing
                                  ? 'Create your secret key'
                                  : 'Title',
                              hintStyle: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: isFirstTimeSetup && !isEditing
                                    ? const Color(0xFFFFA726).withOpacity(0.7)
                                    : Colors.grey,
                              ),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Content field
                          Expanded(
                            child: TextField(
                              controller: _contentController,
                              maxLines: null,
                              expands: true,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Start typing',
                                hintStyle: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),

                          // Mind map option (only for regular notes and not editing)
                          if (!isFirstTimeSetup && !isEditing)
                            Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              child: Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.tree,
                                    color: const Color(0xFFFFA726),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Create a mind map',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFFFFA726),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _handleSave(bool isFirstTimeSetup) {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      return;
    }

    if (isEditing) {
      // If editing existing note, just update it (UpdateNote handles its own loading state)
      _updateNote();
    } else {
      // Only set loading state for new notes
      context.read<NotesBloc>().add(const StartAddNotesLoading());

      if (isFirstTimeSetup) {
        // First time setup - set password through AuthBloc
        context.read<AuthBloc>().add(SetupPassword(title));
      } else {
        // Check if title matches password through AuthBloc
        context.read<NotesBloc>().add(const StartPasswordCheck());
        context.read<AuthBloc>().add(VerifyPassword(title));

        // Safety timeout to prevent getting stuck in loading state
        Future.delayed(const Duration(seconds: 30), () {
          if (mounted && context.read<NotesBloc>().state.isCheckingPassword) {
            print('⏰ Password check timeout - saving as regular note');
            context.read<NotesBloc>().add(const StopPasswordCheck());
            _saveAsRegularNote();
          }
        });
      }
    }
  }

  void _updateNote() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    // Create updated note with new content but preserve original metadata
    final updatedNote = Note(
      id: widget.note!.id,
      title: title,
      content: content,
      createdAt: widget.note!.createdAt,
      updatedAt: DateTime.now(),
      isPasswordNote: widget.note!.isPasswordNote,
    );

    context.read<NotesBloc>().add(UpdateNote(updatedNote));
  }

  void _savePasswordNote() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    // Save the password note as a disguise
    context.read<NotesBloc>().add(SaveNote(
          title: title,
          content: content.isEmpty ? 'My first note' : content,
          isPasswordNote: true,
        ));
  }

  void _saveAsRegularNote() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    // Save as regular note since password didn't match
    context.read<NotesBloc>().add(SaveNote(
          title: title,
          content: content,
          isPasswordNote: false,
        ));
  }

  void _navigateToHiddenArea() {
    context.read<NotesBloc>().add(const StopAddNotesLoading());

    // Navigate to secure area screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (newContext) => MultiBlocProvider(
          providers: [
            BlocProvider.value(
              value: context.read<AuthBloc>(),
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

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
