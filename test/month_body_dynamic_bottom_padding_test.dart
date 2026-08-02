import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalender/kalender.dart';
import 'package:kalender/src/widgets/components/multi_day_overlay_portal_button.dart';
import 'package:kalender/src/widgets/event_tiles/multi_day_event_tile.dart';
import 'package:kalender/src/widgets/events_widgets/multi_day_events_widget.dart';

import 'utilities.dart';

void main() {
  const tileHeight = 20.0;
  const bottomPadding = 37.0;
  final displayRange = DateTimeRange(start: DateTime(2024, 12), end: DateTime(2025, 3));

  // The [Padding] widget that wraps the event area of a single week in the
  // dynamic-height month layout. There is exactly one of these per week.
  final eventAreaPadding = find.byWidgetPredicate(
    (w) => w is Padding && w.child is Align && (w.child as Align).child is MultiDayEventWidget,
  );

  final eventsWidgetFinder = find.byType(MultiDayEventLayoutWidget);

  /// Pumps a month view using the provided [configuration] and [events].
  Future<void> pumpMonth(
    WidgetTester tester, {
    required MultiDayHeaderConfiguration? configuration,
    List<CalendarEvent> events = const [],
  }) async {
    final eventsController = DefaultEventsController();
    for (final event in events) {
      eventsController.addEvent(event);
    }

    await pumpAndSettleWithMaterialApp(
      tester,
      // The dynamic month body scrolls vertically inside a bounded viewport, so
      // the calendar must be given a bounded height (as it is in real usage).
      SizedBox(
        height: 600,
        child: CalendarView(
          eventsController: eventsController,
          calendarController: CalendarController(initialDate: DateTime(2025, 1, 15)),
          viewConfiguration: MonthViewConfiguration.singleMonth(displayRange: displayRange),
          body: CalendarBody(monthBodyConfiguration: configuration),
        ),
      ),
    );
  }

  /// Creates [count] single-day events on the same day, so they stack into
  /// [count] rows within a single week.
  List<CalendarEvent> stackedEvents(DateTime day, int count) {
    return List.generate(count, (i) {
      return CalendarEvent(
        dateTimeRange: DateTimeRange(start: day.copyWith(hour: 8), end: day.copyWith(hour: 9 + i)),
      );
    });
  }

  /// The bottom inset configured on the [i]th event-area padding.
  double insetOf(int i) {
    final padding = eventAreaPadding.evaluate().elementAt(i).widget as Padding;
    return padding.padding.resolve(TextDirection.ltr).bottom;
  }

  /// The gap between the bottom of the rendered events and the bottom of the
  /// [i]th event-area padding (i.e. the visible space below the event list).
  double gapOf(WidgetTester tester, int i) {
    final paddingRect = tester.getRect(eventAreaPadding.at(i));
    final eventsRect = tester.getRect(
      find.descendant(of: eventAreaPadding.at(i), matching: eventsWidgetFinder),
    );
    return paddingRect.bottom - eventsRect.bottom;
  }

  /// Returns the index of the first event-area padding whose week contains at
  /// least [minTiles] event tiles, or -1 if none is found.
  int busyWeekIndex(int minTiles) {
    final count = eventAreaPadding.evaluate().length;
    for (var i = 0; i < count; i++) {
      final tiles = find.descendant(of: eventAreaPadding.at(i), matching: find.byType(MultiDayEventTile));
      if (tiles.evaluate().length >= minTiles) return i;
    }
    return -1;
  }

  testWidgets('busy week taller than minEventRows still renders bottomPadding once', (tester) async {
    await pumpMonth(
      tester,
      configuration: MonthBodyConfiguration(
        dynamicRowHeight: true,
        tileHeight: tileHeight,
        minEventRows: 2,
        bottomPadding: bottomPadding,
      ),
      events: stackedEvents(DateTime(2025, 1, 15), 5),
    );

    // A busy week (5 stacked events => 5 rows) exceeds the minimum area of 2 rows.
    final busyIndex = busyWeekIndex(5);
    expect(busyIndex, isNonNegative, reason: 'Expected a week with 5 stacked events.');

    // The bottom padding is still applied beneath the full event list.
    expect(insetOf(busyIndex), moreOrLessEquals(bottomPadding));
    expect(gapOf(tester, busyIndex), moreOrLessEquals(bottomPadding, epsilon: 0.5));

    // Every week still reserves at least the configured bottom padding.
    final count = eventAreaPadding.evaluate().length;
    for (var i = 0; i < count; i++) {
      expect(gapOf(tester, i), greaterThanOrEqualTo(bottomPadding - 0.5));
    }
  });

  testWidgets('bottomPadding is applied once per week, not once per event', (tester) async {
    await pumpMonth(
      tester,
      configuration: MonthBodyConfiguration(
        dynamicRowHeight: true,
        tileHeight: tileHeight,
        minEventRows: 2,
        bottomPadding: bottomPadding,
      ),
      events: stackedEvents(DateTime(2025, 1, 15), 6),
    );

    // Exactly one event-area padding per week (one per event-layout widget).
    expect(eventAreaPadding, findsWidgets);
    expect(eventAreaPadding.evaluate().length, eventsWidgetFinder.evaluate().length);

    // The busy week contains many tiles but only a single bottom padding.
    final busyIndex = busyWeekIndex(6);
    expect(busyIndex, isNonNegative);
    final tilesInBusyWeek = find.descendant(
      of: eventAreaPadding.at(busyIndex),
      matching: find.byType(MultiDayEventTile),
    );
    expect(tilesInBusyWeek, findsNWidgets(6));
  });

  testWidgets('sparse weeks retain minEventRows plus bottomPadding', (tester) async {
    const minEventRows = 3;
    await pumpMonth(
      tester,
      configuration: MonthBodyConfiguration(
        dynamicRowHeight: true,
        tileHeight: tileHeight,
        minEventRows: minEventRows,
        bottomPadding: bottomPadding,
      ),
    );

    const expectedMinHeight = minEventRows * tileHeight + bottomPadding;

    expect(eventAreaPadding, findsWidgets);
    final count = eventAreaPadding.evaluate().length;
    for (var i = 0; i < count; i++) {
      // The reserved area is at least minEventRows tiles + the bottom padding.
      expect(
        tester.getSize(eventAreaPadding.at(i)).height,
        greaterThanOrEqualTo(expectedMinHeight - 0.5),
      );
      // The bottom padding remains present.
      expect(insetOf(i), moreOrLessEquals(bottomPadding));
      expect(gapOf(tester, i), greaterThanOrEqualTo(bottomPadding - 0.5));
    }
  });

  testWidgets('maxEventsBeforeOverlay still collapses excess events', (tester) async {
    await pumpMonth(
      tester,
      configuration: MonthBodyConfiguration(
        dynamicRowHeight: true,
        tileHeight: tileHeight,
        minEventRows: 2,
        bottomPadding: bottomPadding,
        maxEventsBeforeOverlay: 3,
      ),
      events: stackedEvents(DateTime(2025, 1, 15), 6),
    );

    // The overlay ("+ X more") button is shown for the overflowing day.
    expect(find.byType(MultiDayPortalOverlayButton), findsWidgets);
    // The event area is still wrapped with the bottom padding.
    expect(eventAreaPadding, findsWidgets);
    expect(insetOf(0), moreOrLessEquals(bottomPadding));
  });

  testWidgets('dynamicRowHeight: false does not wrap the event area', (tester) async {
    await pumpMonth(
      tester,
      configuration: MonthBodyConfiguration(
        dynamicRowHeight: false,
        tileHeight: tileHeight,
        bottomPadding: bottomPadding,
      ),
      events: stackedEvents(DateTime(2025, 1, 15), 3),
    );

    // Fixed-height mode renders the month body but never adds the dynamic
    // event-area padding.
    expect(find.byType(MonthBody), findsOneWidget);
    expect(eventAreaPadding, findsNothing);
  });

  testWidgets('bottomPadding: 0 preserves the existing dynamic layout', (tester) async {
    await pumpMonth(
      tester,
      configuration: MonthBodyConfiguration(
        dynamicRowHeight: true,
        tileHeight: tileHeight,
        minEventRows: 2,
        bottomPadding: 0,
      ),
      events: stackedEvents(DateTime(2025, 1, 15), 5),
    );

    final busyIndex = busyWeekIndex(5);
    expect(busyIndex, isNonNegative);

    // With zero bottom padding there is no extra space below the event list.
    expect(insetOf(busyIndex), moreOrLessEquals(0));
    expect(gapOf(tester, busyIndex), moreOrLessEquals(0, epsilon: 0.5));
  });
}
