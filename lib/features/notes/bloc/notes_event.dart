import 'package:equatable/equatable.dart';
import '../../../services/storage_service.dart';

abstract class NotesEvent extends Equatable {
  const NotesEvent();

  @override
  List<Object> get props => [];
}

class LoadNotes extends NotesEvent {
  const LoadNotes();
}

class SaveNote extends NotesEvent {
  final String title;
  final String content;
  final bool isPasswordNote;

  const SaveNote({
    required this.title,
    required this.content,
    this.isPasswordNote = false,
  });

  @override
  List<Object> get props => [title, content, isPasswordNote];
}

class UpdateNote extends NotesEvent {
  final Note note;

  const UpdateNote(this.note);

  @override
  List<Object> get props => [note];
}

class DeleteNote extends NotesEvent {
  final String noteId;

  const DeleteNote(this.noteId);

  @override
  List<Object> get props => [noteId];
}

class SearchNotes extends NotesEvent {
  final String query;

  const SearchNotes(this.query);

  @override
  List<Object> get props => [query];
}

// AddNotes related events
class StartAddNotesLoading extends NotesEvent {
  const StartAddNotesLoading();
}

class StopAddNotesLoading extends NotesEvent {
  const StopAddNotesLoading();
}

class StartPasswordCheck extends NotesEvent {
  const StartPasswordCheck();
}

class StopPasswordCheck extends NotesEvent {
  const StopPasswordCheck();
}

class ResetAddNotesState extends NotesEvent {
  const ResetAddNotesState();
}
