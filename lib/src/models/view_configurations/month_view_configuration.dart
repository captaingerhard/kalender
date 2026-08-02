import 'package:flutter/material.dart';

import 'package:kalender/kalender.dart';
import 'package:kalender/src/layout_delegates/multi_day_event_layout_delegate.dart';
import 'package:kalender/src/models/view_configurations/page_navigation_functions.dart';

class MonthViewConfiguration extends ViewConfiguration {
  @override
  final MonthPageFunctions pageNavigationFunctions;

  /// The first day of the week.
  final int firstDayOfWeek;

  /// The layout strategy used by the [MultiDayHeader] to layout events.
  @Deprecated('''
This method is deprecated and will be removed in a future release. 
Please use the `generateFrame` method in the `MonthBodyConfiguration` configuration instead.
''')
  final MultiDayEventLayoutStrategy<Object?>? eventLayoutStrategy;

  MonthViewConfiguration({
    required super.name,
    super.selectedDate,
    super.initialDateSelectionStrategy,
    required this.firstDayOfWeek,
    required this.pageNavigationFunctions,
    required this.eventLayoutStrategy,
  }) : assert(
          firstDayOfWeek >= 1 && firstDayOfWeek <= 7,
          'First day of week must be a valid week day number\n'
          'Use DateTime.monday, DateTime.tuesday, etc. to set the first day of the week',
        );

  MonthViewConfiguration.singleMonth({
    super.name = 'Month',
    super.selectedDate,
    super.initialDateSelectionStrategy = kDefaultToMonthly,
    DateTimeRange? displayRange,
    this.firstDayOfWeek = defaultFirstDayOfWeek,
    this.eventLayoutStrategy,
  }) : pageNavigationFunctions = MonthPageFunctions(
          originalRange: displayRange ?? DateTime.now().yearRange,
          firstDayOfWeek: firstDayOfWeek,
        );

  MonthViewConfiguration copyWith({
    String? name,
    DateTime? selectedDate,
    InitialDateSelectionStrategy? initialDateSelectionStrategy,
    int? firstDayOfWeek,
    EdgeInsets? eventPadding,
  }) {
    return MonthViewConfiguration.singleMonth(
      name: name ?? this.name,
      selectedDate: selectedDate ?? this.selectedDate,
      initialDateSelectionStrategy: initialDateSelectionStrategy ?? this.initialDateSelectionStrategy,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      eventLayoutStrategy: null,
      displayRange: pageNavigationFunctions.originalRange,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MonthViewConfiguration &&
        other.selectedDate == selectedDate &&
        other.pageNavigationFunctions == pageNavigationFunctions &&
        other.firstDayOfWeek == firstDayOfWeek;
  }

  @override
  int get hashCode {
    return Object.hash(selectedDate, pageNavigationFunctions, firstDayOfWeek);
  }
}

class MonthBodyConfiguration<T extends Object?> extends MultiDayHeaderConfiguration<T> {
  /// Whether the height of each week grows to fit its events instead of
  /// dividing the available height equally between the weeks.
  ///
  /// When `true` the [MonthBody] becomes vertically scrollable: if the combined
  /// height of all the weeks exceeds the available space the body can be
  /// scrolled instead of clipping/compressing the content.
  ///
  /// Defaults to `false` which keeps the original fixed-height grid behaviour.
  final bool dynamicRowHeight;

  /// The maximum number of event rows that are displayed for a day before an
  /// overlay ("+ X more") is shown.
  ///
  /// This is only used when [dynamicRowHeight] is `true`.
  ///
  /// * If `null` every event is rendered and the week grows to fit all of them
  ///   (pure dynamic mode).
  /// * If set the week grows up to this many event rows and any additional
  ///   events are collapsed into the overlay (mixed mode).
  final int? maxEventsBeforeOverlay;

  /// The minimum number of event rows that are reserved for every week when
  /// [dynamicRowHeight] is `true`.
  ///
  /// This ensures weeks with few or no events keep a usable, tappable height.
  final int minEventRows;

  /// The [ScrollPhysics] used by the vertical scroll view when
  /// [dynamicRowHeight] is `true`.
  final ScrollPhysics? scrollPhysics;

  /// The [ScrollPhysics] used by the horizontal [PageView] that navigates
  /// between months.
  final ScrollPhysics? pageScrollPhysics;

  MonthBodyConfiguration({
    super.generateMultiDayLayoutFrame,
    super.pageTriggerConfiguration,
    super.scrollTriggerConfiguration,
    super.tileHeight,
    super.eventPadding,
    super.bottomPadding,
    this.dynamicRowHeight = false,
    this.maxEventsBeforeOverlay,
    this.minEventRows = 2,
    this.scrollPhysics,
    this.pageScrollPhysics,
  })  : assert(
          maxEventsBeforeOverlay == null || maxEventsBeforeOverlay > 0,
          'maxEventsBeforeOverlay must be greater than 0',
        ),
        assert(minEventRows >= 0, 'minEventRows must be greater than or equal to 0'),
        super(showTiles: true, maximumNumberOfVerticalEvents: null);
}
