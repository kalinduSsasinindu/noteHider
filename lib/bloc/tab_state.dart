import 'package:equatable/equatable.dart';

enum TabType { notes, tasks }

class TabState extends Equatable {
  final int selectedTabIndex;
  final TabType selectedTabType;

  const TabState({
    required this.selectedTabIndex,
    required this.selectedTabType,
  });

  const TabState.initial()
      : selectedTabIndex = 0,
        selectedTabType = TabType.notes;

  TabState copyWith({
    int? selectedTabIndex,
    TabType? selectedTabType,
  }) {
    return TabState(
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      selectedTabType: selectedTabType ?? this.selectedTabType,
    );
  }

  @override
  List<Object> get props => [selectedTabIndex, selectedTabType];
}
