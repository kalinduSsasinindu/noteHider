import 'package:equatable/equatable.dart';
import '../../../services/storage_service.dart';

enum NotesStatus {
  initial,
  loading,
  loaded,
  saving,
  saved,
  updating,
  error,
}

class NotesState extends Equatable {
  final NotesStatus status;
  final List<Note> notes;
  final List<Note> filteredNotes;
  final String? errorMessage;
  final bool isAddNotesLoading;
  final bool isCheckingPassword;

  const NotesState({
    required this.status,
    required this.notes,
    required this.filteredNotes,
    this.errorMessage,
    this.isAddNotesLoading = false,
    this.isCheckingPassword = false,
  });

  const NotesState.initial()
      : status = NotesStatus.initial,
        notes = const [],
        filteredNotes = const [],
        errorMessage = null,
        isAddNotesLoading = false,
        isCheckingPassword = false;

  NotesState copyWith({
    NotesStatus? status,
    List<Note>? notes,
    List<Note>? filteredNotes,
    String? errorMessage,
    bool? isAddNotesLoading,
    bool? isCheckingPassword,
  }) {
    return NotesState(
      status: status ?? this.status,
      notes: notes ?? this.notes,
      filteredNotes: filteredNotes ?? this.filteredNotes,
      errorMessage: errorMessage,
      isAddNotesLoading: isAddNotesLoading ?? this.isAddNotesLoading,
      isCheckingPassword: isCheckingPassword ?? this.isCheckingPassword,
    );
  }

  @override
  List<Object?> get props => [
        status,
        notes,
        filteredNotes,
        errorMessage,
        isAddNotesLoading,
        isCheckingPassword,
      ];
}
