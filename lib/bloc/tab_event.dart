import 'package:equatable/equatable.dart';

abstract class TabEvent extends Equatable {
  const TabEvent();

  @override
  List<Object> get props => [];
}

class TabChanged extends TabEvent {
  final int tabIndex;

  const TabChanged(this.tabIndex);

  @override
  List<Object> get props => [tabIndex];
}
