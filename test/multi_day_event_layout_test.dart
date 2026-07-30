import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalender/kalender.dart';
import 'package:kalender/src/widgets/events_widgets/multi_day_events_widget.dart';

import 'utilities.dart';

void main() {
  group('MultiDayEventLayoutWidget', () {
    final eventsController = DefaultEventsController<int>();
    final controller = CalendarController<int>();
    final tileComponents = TileComponents<int>(
      tileBuilder: (event, tileRange) => Container(
        key: ValueKey(event.data!),
        child: Text(event.data.toString()),
      ),
    );

    final start = DateTime(2025, 3, 24);
    final end = DateTime(2025, 3, 31);
    final visibleRange = DateTimeRange(start: start.asUtc, end: end.asUtc);

    ValueKey<int> getKey(int data) => ValueKey(data);

    /// Clear the events controller after each test.
    tearDown(eventsController.clearEvents);

    testWidgets('Basic', (tester) async {
      final events = [
        CalendarEvent<int>(
          dateTimeRange: DateTimeRange(start: start, end: start.copyWith(day: start.day + 3)),
          data: 1,
        ),
        CalendarEvent<int>(
          dateTimeRange: DateTimeRange(start: start, end: start.copyWith(day: start.day + 3)),
          data: 2,
        ),
        CalendarEvent<int>(
          dateTimeRange: DateTimeRange(start: start, end: start.add(const Duration(hours: 6))),
          data: 3,
        ),
      ];
      eventsController.addEvents(events);

      const tileHeight = 50.0;
      const maxNumberOfVerticalEvents = 2;

      await tester.pumpWidget(
        wrapWithMaterialApp(
          TestProvider(
            calendarController: controller,
            eventsController: eventsController,
            tileComponents: tileComponents,
            child: MultiDayEventLayoutWidget<int>(
              events: eventsController.events.toList(),
              eventsController: eventsController,
              visibleDateTimeRange: visibleRange,
              showAllEvents: true,
              tileHeight: tileHeight,
              maxNumberOfVerticalEvents: maxNumberOfVerticalEvents,
              generateMultiDayLayoutFrame: defaultMultiDayFrameGenerator<int>,
              eventPadding: const EdgeInsets.all(0),
              textDirection: TextDirection.ltr,
              multiDayOverlayBuilders: null,
              multiDayOverlayStyles: null,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that the events are laid out correctly
      expect(find.byKey(getKey(1)), findsOneWidget);
      expect(find.byKey(getKey(2)), findsOneWidget);
      // Single-day hidden events are now shown directly instead of "+1 more" button
      expect(find.byKey(getKey(3)), findsOneWidget);

      // No buttons expected since the single hidden event is shown directly
      final buttonFinder = find.byType(MultiDayPortalOverlayButton);
      expect(buttonFinder, findsNothing);
    });

    testWidgets('Multiple events', (tester) async {
      ///   24   25   26   27   28   29  30
      ///   |------1------||-----2----|
      ///   |--3--||---4---||---5-----|
      ///                  |-----6----|

      final events = [
        CalendarEvent<int>(
          dateTimeRange: DateTimeRange(
            start: DateTime(2025, 3, 24),
            end: DateTime(2025, 3, 27),
          ),
          data: 1,
        ),
        CalendarEvent<int>(
          dateTimeRange: DateTimeRange(
            start: DateTime(2025, 3, 27),
            end: DateTime(2025, 3, 30),
          ),
          data: 2,
        ),
        CalendarEvent<int>(
          dateTimeRange: DateTimeRange(
            start: DateTime(2025, 3, 24),
            end: DateTime(2025, 3, 25),
          ),
          data: 3,
        ),
        CalendarEvent<int>(
          dateTimeRange: DateTimeRange(
            start: DateTime(2025, 3, 25),
            end: DateTime(2025, 3, 28),
          ),
          data: 4,
        ),
        CalendarEvent<int>(
          dateTimeRange: DateTimeRange(
            start: DateTime(2025, 3, 28),
            end: DateTime(2025, 3, 30),
          ),
          data: 5,
        ),
        CalendarEvent<int>(
          dateTimeRange: DateTimeRange(
            start: DateTime(2025, 3, 27),
            end: DateTime(2025, 3, 30),
          ),
          data: 6,
        ),
      ];
      eventsController.addEvents(events);

      const tileHeight = 50.0;
      const dayWidth = 50.0;
      const maxNumberOfVerticalEvents = 3;

      await tester.pumpWidget(
        wrapWithMaterialApp(
          TestProvider(
            calendarController: controller,
            eventsController: eventsController,
            tileComponents: tileComponents,
            child: SizedBox(
              key: const ValueKey('test'),
              width: dayWidth * 7,
              height: tileHeight * 3,
              child: MultiDayEventLayoutWidget<int>(
                events: eventsController.events.toList(),
                eventsController: eventsController,
                visibleDateTimeRange: visibleRange,
                showAllEvents: true,
                tileHeight: tileHeight,
                maxNumberOfVerticalEvents: maxNumberOfVerticalEvents,
                generateMultiDayLayoutFrame: defaultMultiDayFrameGenerator<int>,
                eventPadding: const EdgeInsets.all(0),
                textDirection: TextDirection.ltr,
                multiDayOverlayBuilders: null,
                multiDayOverlayStyles: null,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that the events are present.
      expect(find.byKey(getKey(1)), findsOneWidget);
      expect(find.byKey(getKey(2)), findsOneWidget);
      expect(find.byKey(getKey(3)), findsOneWidget);
      expect(find.byKey(getKey(4)), findsOneWidget);
      expect(find.byKey(getKey(5)), findsOneWidget);
      expect(find.byKey(getKey(6)), findsOneWidget);

      /// Check that the events are not overlapping.
      final rects = [
        tester.getRect(find.byKey(getKey(1))),
        tester.getRect(find.byKey(getKey(2))),
        tester.getRect(find.byKey(getKey(3))),
        tester.getRect(find.byKey(getKey(4))),
        tester.getRect(find.byKey(getKey(5))),
        tester.getRect(find.byKey(getKey(6))),
      ];

      for (var i = 0; i < rects.length; i++) {
        for (var j = i + 1; j < rects.length; j++) {
          expect(
            rects[i].overlaps(rects[j]),
            isFalse,
            reason: 'Rect ${i + 1} overlaps with Rect ${j + 1}',
          );
        }
      }
    });

    testWidgets('Button values', (tester) async {
      ///   24   25   26   27   28   29  30
      ///   |-----1-------||-----2----|
      ///        |----3---|
      ///                  | +1 || +1 |
      /// _______________________________
      ///                 |------4----|
      final events = [
        CalendarEvent<int>(
          dateTimeRange: DateTimeRange(
            start: DateTime(2025, 3, 24),
            end: DateTime(2025, 3, 27),
          ),
          data: 1,
        ),
        CalendarEvent<int>(
          dateTimeRange: DateTimeRange(
            start: DateTime(2025, 3, 27),
            end: DateTime(2025, 3, 30),
          ),
          data: 2,
        ),
        CalendarEvent<int>(
          dateTimeRange: DateTimeRange(
            start: DateTime(2025, 3, 25),
            end: DateTime(2025, 3, 28),
          ),
          data: 3,
        ),
        CalendarEvent<int>(
          dateTimeRange: DateTimeRange(
            start: DateTime(2025, 3, 27),
            end: DateTime(2025, 3, 30),
          ),
          data: 4,
        ),
      ];
      eventsController.addEvents(events);

      const tileHeight = 50.0;
      const maxNumberOfVerticalEvents = 2;

      await tester.pumpWidget(
        wrapWithMaterialApp(
          TestProvider(
            calendarController: controller,
            eventsController: eventsController,
            tileComponents: tileComponents,
            child: MultiDayEventLayoutWidget<int>(
              events: eventsController.events.toList(),
              eventsController: eventsController,
              visibleDateTimeRange: visibleRange,
              showAllEvents: true,
              tileHeight: tileHeight,
              maxNumberOfVerticalEvents: maxNumberOfVerticalEvents,
              generateMultiDayLayoutFrame: defaultMultiDayFrameGenerator<int>,
              eventPadding: const EdgeInsets.all(0),
              textDirection: TextDirection.ltr,
              multiDayOverlayBuilders: null,
              multiDayOverlayStyles: null,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that the events are present.
      expect(find.byKey(getKey(1)), findsOneWidget);
      expect(find.byKey(getKey(2)), findsOneWidget);
      expect(find.byKey(getKey(3)), findsOneWidget);
      expect(find.byKey(getKey(4)), findsNothing);

      final buttonFinder = find.byType(MultiDayPortalOverlayButton);
      expect(buttonFinder, findsNWidgets(3));

      final buttonTextFinder = find.byKey(MultiDayPortalOverlayButton.textKey);
      buttonTextFinder.evaluate().forEach((element) {
        final text = (element.widget as Text).data;
        expect(text, isNotNull, reason: 'Button text should not be null');
        expect(text!.contains('1'), isTrue, reason: 'Button text should contain the number "1" but found: "$text"');
      });
    });

    testWidgets('Sorting by start time', (tester) async {
      ///   24   25   26   27   28   29  30
      ///   |-----2-------|
      ///   |-3-|
      ///   |----1--------|
      ///   | +1 |
      /// _______________________________
      ///   |-4-|
      final events = [
        CalendarEvent<int>(
          dateTimeRange: DateTimeRange(start: start.copyWith(hour: 6), end: start.copyWith(day: start.day + 3)),
          data: 1,
        ),
        CalendarEvent<int>(
          dateTimeRange: DateTimeRange(start: start, end: start.copyWith(day: start.day + 3)),
          data: 2,
        ),
        CalendarEvent<int>(
          dateTimeRange: DateTimeRange(start: start.copyWith(hour: 3), end: start.copyWith(hour: 6)),
          data: 3,
        ),
        CalendarEvent<int>(
          dateTimeRange: DateTimeRange(start: start.copyWith(hour: 7), end: start.copyWith(hour: 10)),
          data: 4,
        ),
      ];
      eventsController.addEvents(events);
      int customComparator(CalendarEvent<int> a, CalendarEvent<int> b) {
        return a.start.compareTo(b.start);
      }

      const tileHeight = 50.0;
      const maxNumberOfVerticalEvents = 3;

      await tester.pumpWidget(
        wrapWithMaterialApp(
          TestProvider(
            calendarController: controller,
            eventsController: eventsController,
            tileComponents: tileComponents,
            child: MultiDayEventLayoutWidget<int>(
              events: eventsController.events.toList(),
              eventsController: eventsController,
              visibleDateTimeRange: visibleRange,
              showAllEvents: true,
              tileHeight: tileHeight,
              maxNumberOfVerticalEvents: maxNumberOfVerticalEvents,
              generateMultiDayLayoutFrame: ({required events, required textDirection, required visibleDateTimeRange}) =>
                  defaultMultiDayFrameGenerator(
                visibleDateTimeRange: visibleDateTimeRange,
                events: events,
                textDirection: textDirection,
                eventComparator: customComparator,
              ),
              eventPadding: const EdgeInsets.all(0),
              textDirection: TextDirection.ltr,
              multiDayOverlayBuilders: null,
              multiDayOverlayStyles: null,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that the events are laid out correctly
      expect(find.byKey(getKey(1)), findsOneWidget);
      expect(find.byKey(getKey(2)), findsOneWidget);
      // Single-day hidden events are now shown directly instead of "+1 more" button
      expect(find.byKey(getKey(4)), findsOneWidget);

      // No buttons expected since the single hidden event is shown directly
      final buttonFinder = find.byType(MultiDayPortalOverlayButton);
      expect(buttonFinder, findsNothing);

      // Get positions of each event
      final pos1 = tester.getTopLeft(find.byKey(getKey(1)));
      final pos2 = tester.getTopLeft(find.byKey(getKey(2)));
      final pos3 = tester.getTopLeft(find.byKey(getKey(3)));

      expect(pos2.dy, lessThan(pos3.dy));
      expect(pos3.dy, lessThan(pos1.dy));

      // Ensure that the rects do not overlap
      final rects = [
        tester.getRect(find.byKey(getKey(1))),
        tester.getRect(find.byKey(getKey(2))),
        tester.getRect(find.byKey(getKey(3))),
      ];

      for (var i = 0; i < rects.length; i++) {
        for (var j = i + 1; j < rects.length; j++) {
          expect(
            rects[i].overlaps(rects[j]),
            isFalse,
            reason: 'Rect ${i + 1} overlaps with Rect ${j + 1}',
          );
        }
      }
    });

    testWidgets('Sorting by end time', (tester) async {
      ///   24   25   26   27   28   29  30
      ///   |-3-|
      ///   |-2-|
      ///   |-1-|
      ///   | +1 |
      /// _______________________________
      ///   |-4-|
      final events = [
        CalendarEvent<int>(
          dateTimeRange: DateTimeRange(start: start, end: start.copyWith(hour: 12)),
          data: 1,
        ),
        CalendarEvent<int>(
          dateTimeRange: DateTimeRange(start: start, end: start.copyWith(hour: 8)),
          data: 2,
        ),
        CalendarEvent<int>(
          dateTimeRange: DateTimeRange(start: start.copyWith(hour: 3), end: start.copyWith(hour: 4)),
          data: 3,
        ),
        CalendarEvent<int>(
          dateTimeRange: DateTimeRange(start: start.copyWith(hour: 3), end: start.copyWith(hour: 16)),
          data: 4,
        ),
      ];
      eventsController.addEvents(events);
      int customComparator(CalendarEvent<int> a, CalendarEvent<int> b) {
        return a.end.compareTo(b.end);
      }

      const tileHeight = 50.0;
      const maxNumberOfVerticalEvents = 3;

      await tester.pumpWidget(
        wrapWithMaterialApp(
          TestProvider(
            calendarController: controller,
            eventsController: eventsController,
            tileComponents: tileComponents,
            child: MultiDayEventLayoutWidget<int>(
              events: eventsController.events.toList(),
              eventsController: eventsController,
              visibleDateTimeRange: visibleRange,
              showAllEvents: true,
              tileHeight: tileHeight,
              maxNumberOfVerticalEvents: maxNumberOfVerticalEvents,
              generateMultiDayLayoutFrame: ({required events, required textDirection, required visibleDateTimeRange}) =>
                  defaultMultiDayFrameGenerator(
                visibleDateTimeRange: visibleDateTimeRange,
                events: events,
                textDirection: textDirection,
                eventComparator: customComparator,
              ),
              eventPadding: const EdgeInsets.all(0),
              textDirection: TextDirection.ltr,
              multiDayOverlayBuilders: null,
              multiDayOverlayStyles: null,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that the events are laid out correctly
      expect(find.byKey(getKey(1)), findsOneWidget);
      expect(find.byKey(getKey(2)), findsOneWidget);
      expect(find.byKey(getKey(3)), findsOneWidget);
      // Single-day hidden events are now shown directly instead of "+1 more" button
      expect(find.byKey(getKey(4)), findsOneWidget);

      // No buttons expected since the single hidden event is shown directly
      final buttonFinder = find.byType(MultiDayPortalOverlayButton);
      expect(buttonFinder, findsNothing);

      // Get positions of each event
      final pos1 = tester.getTopLeft(find.byKey(getKey(1)));
      final pos2 = tester.getTopLeft(find.byKey(getKey(2)));
      final pos3 = tester.getTopLeft(find.byKey(getKey(3)));

      expect(pos3.dy, lessThan(pos2.dy));
      expect(pos2.dy, lessThan(pos1.dy));

      // Ensure that the rects do not overlap
      final rects = [
        tester.getRect(find.byKey(getKey(1))),
        tester.getRect(find.byKey(getKey(2))),
        tester.getRect(find.byKey(getKey(3))),
      ];

      for (var i = 0; i < rects.length; i++) {
        for (var j = i + 1; j < rects.length; j++) {
          expect(
            rects[i].overlaps(rects[j]),
            isFalse,
            reason: 'Rect ${i + 1} overlaps with Rect ${j + 1}',
          );
        }
      }
    });

    testWidgets('Row spanning tile is positioned and sized by rowSpan', (tester) async {
      final events = [
        CalendarEvent<int>(
          dateTimeRange: DateTimeRange(start: start, end: start.copyWith(day: start.day + 1)),
          data: 1,
        ),
      ];
      eventsController.addEvents(events);

      const tileHeight = 50.0;

      // A custom frame generator that places the event at row 1 and spans 3 rows.
      MultiDayLayoutFrame<int> spanningFrame({
        required DateTimeRange visibleDateTimeRange,
        required List<CalendarEvent<int>> events,
        required TextDirection textDirection,
      }) {
        return MultiDayLayoutFrame<int>(
          dateTimeRange: visibleDateTimeRange,
          events: events,
          layoutInfo: [
            EventLayoutInformation(id: events.first.id, row: 1, columns: const [0], rowSpan: 3),
          ],
          totalNumberOfRows: 4,
          columnRowMap: const {0: 3},
        );
      }

      await tester.pumpWidget(
        wrapWithMaterialApp(
          TestProvider(
            calendarController: controller,
            eventsController: eventsController,
            tileComponents: tileComponents,
            child: MultiDayEventLayoutWidget<int>(
              events: eventsController.events.toList(),
              eventsController: eventsController,
              visibleDateTimeRange: visibleRange,
              showAllEvents: true,
              tileHeight: tileHeight,
              maxNumberOfVerticalEvents: null,
              generateMultiDayLayoutFrame: spanningFrame,
              eventPadding: const EdgeInsets.all(0),
              textDirection: TextDirection.ltr,
              multiDayOverlayBuilders: null,
              multiDayOverlayStyles: null,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final tileFinder = find.byKey(getKey(1));
      expect(tileFinder, findsOneWidget);

      // Positioned at row 1 -> tileHeight.
      final position = tester.getTopLeft(tileFinder);
      final layoutPosition = tester.getTopLeft(find.byType(CustomMultiChildLayout).last);
      expect(position.dy - layoutPosition.dy, tileHeight);

      // Sized to 3 * tileHeight.
      final size = tester.getSize(tileFinder);
      expect(size.height, 3 * tileHeight);
    });

    testWidgets('Row spanning tile is clamped when numberOfRows is limited', (tester) async {
      final events = [
        CalendarEvent<int>(
          dateTimeRange: DateTimeRange(start: start, end: start.copyWith(day: start.day + 1)),
          data: 1,
        ),
      ];
      eventsController.addEvents(events);

      const tileHeight = 50.0;

      // The event spans 3 rows starting at row 0, but only 2 rows are available.
      MultiDayLayoutFrame<int> spanningFrame({
        required DateTimeRange visibleDateTimeRange,
        required List<CalendarEvent<int>> events,
        required TextDirection textDirection,
      }) {
        return MultiDayLayoutFrame<int>(
          dateTimeRange: visibleDateTimeRange,
          events: events,
          layoutInfo: [
            EventLayoutInformation(id: events.first.id, row: 0, columns: const [0], rowSpan: 3),
          ],
          totalNumberOfRows: 2,
          columnRowMap: const {0: 1},
        );
      }

      await tester.pumpWidget(
        wrapWithMaterialApp(
          TestProvider(
            calendarController: controller,
            eventsController: eventsController,
            tileComponents: tileComponents,
            child: MultiDayEventLayoutWidget<int>(
              events: eventsController.events.toList(),
              eventsController: eventsController,
              visibleDateTimeRange: visibleRange,
              showAllEvents: true,
              tileHeight: tileHeight,
              maxNumberOfVerticalEvents: null,
              generateMultiDayLayoutFrame: spanningFrame,
              eventPadding: const EdgeInsets.all(0),
              textDirection: TextDirection.ltr,
              multiDayOverlayBuilders: null,
              multiDayOverlayStyles: null,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final tileFinder = find.byKey(getKey(1));
      expect(tileFinder, findsOneWidget);

      // Clamped to numberOfRows - row = 2 - 0 = 2 rows.
      final size = tester.getSize(tileFinder);
      expect(size.height, 2 * tileHeight);
    });
  });

  group('EventLayoutInformation rowSpan', () {
    test('Defaults to 1', () {
      final info = EventLayoutInformation(id: 1, row: 0, columns: const [0]);
      expect(info.rowSpan, 1);
    });

    test('preliminary sets rowSpan to 1', () {
      final info = EventLayoutInformation.preliminary(id: 1, columns: const [0]);
      expect(info.rowSpan, 1);
    });

    test('copyWith updates rowSpan', () {
      final info = EventLayoutInformation(id: 1, row: 0, columns: const [0]);
      final copy = info.copyWith(rowSpan: 3);
      expect(copy.rowSpan, 3);
      // Other fields are preserved.
      expect(copy.id, info.id);
      expect(copy.row, info.row);
      expect(copy.columns, info.columns);
    });

    test('Asserts rowSpan is greater than zero', () {
      expect(
        () => EventLayoutInformation(id: 1, row: 0, columns: const [0], rowSpan: 0),
        throwsAssertionError,
      );
    });

    test('toString includes rowSpan', () {
      final info = EventLayoutInformation(id: 1, row: 2, columns: const [0], rowSpan: 3);
      expect(info.toString(), contains('rowSpan: 3'));
    });
  });
}
