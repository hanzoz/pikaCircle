import 'package:flutter_riverpod/flutter_riverpod.dart';

/// UI state for the main shell: which primary tab is selected and whether the
/// search field is expanded.
class ShellState {
  const ShellState({this.selectedIndex = 0, this.isSearchActive = false});

  final int selectedIndex;
  final bool isSearchActive;

  ShellState copyWith({int? selectedIndex, bool? isSearchActive}) {
    return ShellState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      isSearchActive: isSearchActive ?? this.isSearchActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ShellState &&
      other.selectedIndex == selectedIndex &&
      other.isSearchActive == isSearchActive;

  @override
  int get hashCode => Object.hash(selectedIndex, isSearchActive);
}

/// Manages navigation/search state for [ShellState].
///
/// Replaces the imperative `setState` logic from the former `_MainShellState`
/// in `main.dart`. Index constants are owned by the shell screen and passed in.
class ShellController extends Notifier<ShellState> {
  @override
  ShellState build() => const ShellState();

  /// Selects one of the primary (non-search) tabs and collapses search.
  void selectPrimaryTab(int index) {
    state = state.copyWith(selectedIndex: index, isSearchActive: false);
  }

  /// Activates or deactivates search. When [active], the shell should switch to
  /// [findPageIndex]; when deactivating from that page, fall back to [homeIndex].
  void setSearchActive(
    bool active, {
    required int findPageIndex,
    int homeIndex = 0,
  }) {
    if (active) {
      state = state.copyWith(isSearchActive: true, selectedIndex: findPageIndex);
    } else {
      final nextIndex =
          state.selectedIndex == findPageIndex ? homeIndex : state.selectedIndex;
      state = state.copyWith(isSearchActive: false, selectedIndex: nextIndex);
    }
  }
}

final shellControllerProvider =
    NotifierProvider<ShellController, ShellState>(ShellController.new);
