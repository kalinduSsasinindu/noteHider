import 'package:flutter_bloc/flutter_bloc.dart';
import 'tab_event.dart';
import 'tab_state.dart';

class TabBloc extends Bloc<TabEvent, TabState> {
  TabBloc() : super(const TabState.initial()) {
    on<TabChanged>(_onTabChanged);
  }

  void _onTabChanged(TabChanged event, Emitter<TabState> emit) {
    final TabType tabType = event.tabIndex == 0 ? TabType.notes : TabType.tasks;

    emit(state.copyWith(
      selectedTabIndex: event.tabIndex,
      selectedTabType: tabType,
    ));
  }
}
