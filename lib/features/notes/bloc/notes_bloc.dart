import 'package:bloc/bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../services/storage_service.dart';
import 'notes_event.dart';
import 'notes_state.dart';

class NotesBloc extends Bloc<NotesEvent, NotesState> {
  final StorageService _storageService;
  final Uuid _uuid = const Uuid();

  NotesBloc({
    required StorageService storageService,
  })  : _storageService = storageService,
        super(const NotesState.initial()) {
    on<LoadNotes>(_onLoadNotes);
    on<SaveNote>(_onSaveNote);
    on<UpdateNote>(_onUpdateNote);
    on<DeleteNote>(_onDeleteNote);
    on<SearchNotes>(_onSearchNotes);
    on<StartAddNotesLoading>(_onStartAddNotesLoading);
    on<StopAddNotesLoading>(_onStopAddNotesLoading);
    on<StartPasswordCheck>(_onStartPasswordCheck);
    on<StopPasswordCheck>(_onStopPasswordCheck);
    on<ResetAddNotesState>(_onResetAddNotesState);
  }

  Future<void> _onLoadNotes(
    LoadNotes event,
    Emitter<NotesState> emit,
  ) async {
    try {
      emit(state.copyWith(status: NotesStatus.loading));

      final notesData = await _storageService.getNotes();
      final notes = notesData.map((data) => Note.fromJson(data)).toList();

      emit(state.copyWith(
        status: NotesStatus.loaded,
        notes: notes,
        filteredNotes: notes,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: NotesStatus.error,
        errorMessage: 'Failed to load notes: ${e.toString()}',
      ));
    }
  }

  Future<void> _onSaveNote(
    SaveNote event,
    Emitter<NotesState> emit,
  ) async {
    try {
      emit(state.copyWith(status: NotesStatus.saving));

      final note = Note(
        id: _uuid.v4(),
        title: event.title,
        content: event.content.isEmpty
            ? (event.isPasswordNote ? 'My first note' : '')
            : event.content,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPasswordNote: event.isPasswordNote,
      );

      final existingNotesData = await _storageService.getNotes();
      final existingNotes =
          existingNotesData.map((data) => Note.fromJson(data)).toList();
      final updatedNotes = [...existingNotes, note];

      // Convert notes to Map format for military-grade storage
      final notesData = updatedNotes.map((note) => note.toJson()).toList();
      await _storageService.storeNotes(notesData);

      emit(state.copyWith(
        status: NotesStatus.saved,
        notes: updatedNotes,
        filteredNotes: updatedNotes,
        errorMessage: null,
        isAddNotesLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: NotesStatus.error,
        errorMessage: 'Failed to save note: ${e.toString()}',
        isAddNotesLoading: false,
      ));
    }
  }

  Future<void> _onUpdateNote(
    UpdateNote event,
    Emitter<NotesState> emit,
  ) async {
    try {
      emit(state.copyWith(status: NotesStatus.updating));

      final existingNotesData = await _storageService.getNotes();
      final existingNotes =
          existingNotesData.map((data) => Note.fromJson(data)).toList();

      final updatedNotes = existingNotes.map((note) {
        if (note.id == event.note.id) {
          return event.note;
        }
        return note;
      }).toList();

      // Convert notes to Map format for military-grade storage
      final notesData = updatedNotes.map((note) => note.toJson()).toList();
      await _storageService.storeNotes(notesData);

      emit(state.copyWith(
        status: NotesStatus.saved,
        notes: updatedNotes,
        filteredNotes: updatedNotes,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: NotesStatus.error,
        errorMessage: 'Failed to update note: ${e.toString()}',
      ));
    }
  }

  Future<void> _onDeleteNote(
    DeleteNote event,
    Emitter<NotesState> emit,
  ) async {
    try {
      emit(state.copyWith(status: NotesStatus.loading));

      final existingNotesData = await _storageService.getNotes();
      final existingNotes =
          existingNotesData.map((data) => Note.fromJson(data)).toList();
      final updatedNotes =
          existingNotes.where((note) => note.id != event.noteId).toList();

      // Convert notes to Map format for military-grade storage
      final notesData = updatedNotes.map((note) => note.toJson()).toList();
      await _storageService.storeNotes(notesData);

      emit(state.copyWith(
        status: NotesStatus.loaded,
        notes: updatedNotes,
        filteredNotes: updatedNotes,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: NotesStatus.error,
        errorMessage: 'Failed to delete note: ${e.toString()}',
      ));
    }
  }

  Future<void> _onSearchNotes(
    SearchNotes event,
    Emitter<NotesState> emit,
  ) async {
    try {
      final query = event.query.toLowerCase();

      if (query.isEmpty) {
        emit(state.copyWith(
          filteredNotes: state.notes,
          errorMessage: null,
        ));
        return;
      }

      final filteredNotes = state.notes.where((note) {
        return note.title.toLowerCase().contains(query) ||
            note.content.toLowerCase().contains(query);
      }).toList();

      emit(state.copyWith(
        filteredNotes: filteredNotes,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to search notes: ${e.toString()}',
      ));
    }
  }

  // AddNotes related event handlers
  void _onStartAddNotesLoading(
    StartAddNotesLoading event,
    Emitter<NotesState> emit,
  ) {
    emit(state.copyWith(isAddNotesLoading: true));
  }

  void _onStopAddNotesLoading(
    StopAddNotesLoading event,
    Emitter<NotesState> emit,
  ) {
    emit(state.copyWith(isAddNotesLoading: false));
  }

  void _onStartPasswordCheck(
    StartPasswordCheck event,
    Emitter<NotesState> emit,
  ) {
    emit(state.copyWith(isCheckingPassword: true));
  }

  void _onStopPasswordCheck(
    StopPasswordCheck event,
    Emitter<NotesState> emit,
  ) {
    emit(state.copyWith(isCheckingPassword: false));
  }

  void _onResetAddNotesState(
    ResetAddNotesState event,
    Emitter<NotesState> emit,
  ) {
    emit(state.copyWith(
      isAddNotesLoading: false,
      isCheckingPassword: false,
    ));
  }
}
