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

                if (state.status == AuthStatus.unlocked &&
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
                } else if (state.status == AuthStatus.unlocked &&
                    !context.read<NotesBloc>().state.isCheckingPassword) {
                  // First time password setup completed, save password note
                  print('🆕 First time setup complete - saving password note');
                  _savePasswordNote();
                } else if (state.errorMessage != null &&
                    !context.read<NotesBloc>().state.isCheckingPassword) {
                  _showSnackBar('Error: ${state.errorMessage}');
                  context.read<NotesBloc>().add(const StopAddNotesLoading());
                }
              },
            ),
            BlocListener<NotesBloc, NotesState>(
              listener: (context, state) {
                if (state.status == NotesStatus.saved) {
                  _showSnackBar(isEditing
                      ? 'Note updated successfully!'
                      : 'Note saved successfully!');
                  Navigator.pop(context);
                } else if (state.status == NotesStatus.error &&
                    state.errorMessage != null) {
                  _showSnackBar('Error: ${state.errorMessage}');
                  context.read<NotesBloc>().add(const StopAddNotesLoading());
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
                            final isLoading = notesState.isAddNotesLoading ||
                                notesState.isCheckingPassword ||
                                notesState.status == NotesStatus.saving;

                            return GestureDetector(
                              onTap: isLoading
                                  ? null
                                  : () => _handleSave(isFirstTimeSetup),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFA726),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        isEditing ? 'Update' : 'Save',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
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
      _showSnackBar('Please enter a title');
      return;
    }

    context.read<NotesBloc>().add(const StartAddNotesLoading());

    if (isEditing) {
      // If editing existing note, just update it
      _updateNote();
    } else if (isFirstTimeSetup) {
      // First time setup - set password through AuthBloc
      context.read<AuthBloc>().add(SetupPassword(title));
    } else {
      // Check if title matches password through AuthBloc
      context.read<NotesBloc>().add(const StartPasswordCheck());
      context.read<AuthBloc>().add(VerifyPassword(title));
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

    Navigator.pop(context); // Close add note page immediately
    _showSnackBar('Hidden area access granted!');
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFFFA726),
          behavior: SnackBarBehavior.fixed,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
