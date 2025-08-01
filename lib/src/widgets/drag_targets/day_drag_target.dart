import 'package:flutter/material.dart';
import 'package:kalender/kalender.dart';
import 'package:kalender/src/models/calendar_events/draggable_event.dart';
import 'package:kalender/src/models/mixins/drag_target_utils.dart';
import 'package:kalender/src/models/mixins/snap_points.dart';
import 'package:kalender/src/models/providers/calendar_provider.dart';
import 'package:kalender/src/widgets/internal_components/cursor_navigation_trigger.dart';

/// A [StatefulWidget] that provides a [DragTarget] for [Create], [Resize], [Reschedule] objects.
///
/// The [DayDragTarget] specializes in accepting [Draggable] widgets for a multi day body.
class DayDragTarget<T extends Object?> extends StatefulWidget {
  final CalendarController<T> controller;
  final MultiDayViewController<T> viewController;
  final MultiDayBodyConfiguration configuration;

  final double pageWidth;
  final double dayWidth;
  final double viewPortHeight;

  final ValueNotifier<CalendarSnapping> snapping;

  /// Creates a [DayDragTarget].
  const DayDragTarget({
    super.key,
    required this.controller,
    required this.viewController,
    required this.configuration,
    required this.pageWidth,
    required this.dayWidth,
    required this.viewPortHeight,
    required this.snapping,
  });

  @override
  State<DayDragTarget<T>> createState() => _DayDragTargetState<T>();
}

class _DayDragTargetState<T extends Object?> extends State<DayDragTarget<T>> with SnapPoints, DragTargetUtilities<T> {
  @override
  EventsController<T> get eventsController => context.eventsController<T>();

  @override
  CalendarController<T> get controller => widget.controller;

  @override
  List<DateTime> get visibleDates => viewController.visibleDateTimeRange.value.dates();

  @override
  CalendarCallbacks<T>? get callbacks => context.callbacks<T>();

  @override
  double get dayWidth => widget.dayWidth;

  @override
  bool get multiDayDragTarget => false;

  MultiDayViewController<T> get viewController => widget.viewController;
  ScrollController get scrollController => viewController.scrollController;
  TimeOfDayRange get timeOfDayRange => viewController.viewConfiguration.timeOfDayRange;

  MultiDayBodyConfiguration get bodyConfiguration => widget.configuration;
  bool get showMultiDayEvents => bodyConfiguration.showMultiDayEvents;
  PageTriggerConfiguration get pageTrigger => bodyConfiguration.pageTriggerConfiguration;
  ScrollTriggerConfiguration get scrollTrigger => bodyConfiguration.scrollTriggerConfiguration;

  CalendarSnapping get snapping => widget.snapping.value;
  bool get snapToOtherEvents => snapping.snapToOtherEvents;
  int get snapIntervalMinutes => snapping.snapIntervalMinutes;
  bool get snapToTimeIndicator => snapping.snapToTimeIndicator;
  Duration get snapRange => snapping.snapRange;

  double get heightPerMinute => context.heightPerMinute;
  double get pageWidth => widget.pageWidth;
  double get viewPortHeight => widget.viewPortHeight;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSnapPoints();
      widget.snapping.addListener(_updateSnapPoints);
      controller.visibleEvents.addListener(_updateSnapPoints);
    });
  }

  @override
  void didUpdateWidget(covariant DayDragTarget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.snapping != widget.snapping) {
      oldWidget.snapping.removeListener(_updateSnapPoints);
      widget.snapping.addListener(_updateSnapPoints);
    }
  }

  @override
  void dispose() {
    widget.snapping.removeListener(_updateSnapPoints);
    controller.visibleEvents.removeListener(_updateSnapPoints);
    super.dispose();
  }

  /// Update the snap points.
  void _updateSnapPoints() {
    if (!snapToOtherEvents) return;
    clearSnapPoints();
    addEventSnapPoints(controller.visibleEvents.value);
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget(
      hitTestBehavior: HitTestBehavior.translucent,
      onWillAcceptWithDetails: (details) {
        return onWillAcceptWithDetails(
          details,
          onResize: (event, direction) => direction.vertical,
          onReschedule: (event) {
            final eventDuration = event.duration;
            // Check if the event will fit within the time of day range.
            if (!timeOfDayRange.isAllDay && event.duration > timeOfDayRange.duration) return false;
            // Check if the event is a multi day event.
            if (!showMultiDayEvents && event.isMultiDayEvent) return false;
            // Calculate the size of the feedback widget.
            final eventHeight = eventDuration.inMinutes * heightPerMinute;
            // Set the size of the feedback widget.

            context.feedbackWidgetSizeNotifier<T>().value = Size(dayWidth, eventHeight);
            // Select the event as an internal one.
            controller.selectEvent(event, internal: true);
            return true;
          },
        );
      },
      onMove: onMove,
      onAcceptWithDetails: onAcceptWithDetails,
      onLeave: onLeave,
      builder: (context, candidateData, rejectedData) {
        // Check if the candidateData is null.
        if (candidateData.firstOrNull == null) return const SizedBox();
        final components = context.components<T>()?.multiDayComponents?.bodyComponents ?? MultiDayBodyComponents<T>();

        final triggerWidth = pageWidth / 50;
        final rightTrigger = CursorNavigationTrigger(
          triggerDelay: pageTrigger.triggerDelay,
          onTrigger: () => viewController.animateToNextPage(
            duration: pageTrigger.animationDuration,
            curve: pageTrigger.animationCurve,
          ),
          child:
              components.rightTriggerBuilder?.call(pageWidth) ?? SizedBox(width: triggerWidth, height: viewPortHeight),
        );

        final leftTrigger = CursorNavigationTrigger(
          triggerDelay: pageTrigger.triggerDelay,
          onTrigger: () => viewController.animateToPreviousPage(
            duration: pageTrigger.animationDuration,
            curve: pageTrigger.animationCurve,
          ),
          child:
              components.leftTriggerBuilder?.call(pageWidth) ?? SizedBox(width: triggerWidth, height: viewPortHeight),
        );

        final triggerHeight = scrollTrigger.triggerHeight.call(viewPortHeight);
        final scrollAmount = scrollTrigger.scrollAmount.call(viewPortHeight);
        final topScrollTrigger = CursorNavigationTrigger(
          triggerDelay: scrollTrigger.triggerDelay,
          onTrigger: () => scrollController.animateTo(
            scrollController.offset - scrollAmount,
            duration: scrollTrigger.animationDuration,
            curve: scrollTrigger.animationCurve,
          ),
          child:
              components.topTriggerBuilder?.call(viewPortHeight) ?? SizedBox(height: triggerHeight, width: pageWidth),
        );

        final bottomScrollTrigger = CursorNavigationTrigger(
          triggerDelay: scrollTrigger.triggerDelay,
          onTrigger: () => scrollController.animateTo(
            scrollController.offset + scrollAmount,
            duration: scrollTrigger.animationDuration,
            curve: scrollTrigger.animationCurve,
          ),
          child: components.bottomTriggerBuilder?.call(viewPortHeight) ??
              SizedBox(height: triggerHeight, width: pageWidth),
        );

        return Stack(
          children: [
            PositionedDirectional(start: 0, end: 0, child: topScrollTrigger),
            PositionedDirectional(start: 0, end: 0, bottom: 0, child: bottomScrollTrigger),
            PositionedDirectional(start: 0, top: 0, bottom: 0, child: leftTrigger),
            PositionedDirectional(end: 0, top: 0, bottom: 0, child: rightTrigger),
          ],
        );
      },
    );
  }

  @override
  DateTime? calculateCursorDateTime(
    Offset offset, {
    Offset feedbackWidgetOffset = Offset.zero,
  }) {
    final localCursorPosition = calculateLocalCursorPosition(offset, scrollOffset: Offset(0, scrollController.offset));
    if (localCursorPosition == null) return null;

    // Calculate only the date of the cursor from the local cursor position.
    final cursorDateIndex = (localCursorPosition.dx / dayWidth).floor();
    if (cursorDateIndex < 0) return null;

    final date = Directionality.of(context) == TextDirection.ltr
        ? visibleDates.elementAtOrNull(cursorDateIndex)
        : visibleDates.elementAtOrNull(visibleDates.length - cursorDateIndex - 1);

    final cursorDate = date;
    if (cursorDate == null) return null;

    // Calculate the start of the day.
    final startOfDate = timeOfDayRange.start.toDateTime(cursorDate);

    // Calculate the duration to add to the startOfDate.
    final durationFromStart = localCursorPosition.dy ~/ heightPerMinute;
    final numberOfIntervals = (durationFromStart / snapIntervalMinutes).round();
    final duration = Duration(minutes: snapIntervalMinutes * numberOfIntervals);

    return startOfDate.add(duration);
  }

  /// Update the [CalendarEvent] based on the [Offset] delta.
  @override
  CalendarEvent<T>? rescheduleEvent(CalendarEvent<T> event, DateTime cursorDateTime) {
    DateTime start;

    if (timeOfDayRange.isAllDay) {
      start = cursorDateTime;
    } else {
      final startOfDate = timeOfDayRange.start.toDateTime(cursorDateTime);
      final endOfDate = timeOfDayRange.end.toDateTime(cursorDateTime);
      if (cursorDateTime.isBefore(startOfDate)) {
        start = startOfDate;
      } else if (cursorDateTime.add(event.duration).isAfter(endOfDate)) {
        start = endOfDate.subtract(event.duration);
      } else {
        start = cursorDateTime;
      }
    }

    // Calculate the new dateTimeRange for the event.
    final duration = event.dateTimeRangeAsUtc.duration;
    var end = start.add(duration);

    // Add now to the snap points.
    late final now = DateTime.now().asUtc;
    if (snapToTimeIndicator) addSnapPoint(now);

    // Find the index of the snap point that is within a duration of snapRange of the start.
    final startSnapPoint = findSnapPoint(start, snapRange);
    if (startSnapPoint != null && startSnapPoint.isBefore(end)) {
      start = startSnapPoint;
      end = start.add(duration);
    }

    // Find the index of the snap point that is within a duration of snapRange of the end.
    late final endSnapPoint = findSnapPoint(end, snapRange);
    final canUseEndSnapPoint = startSnapPoint == null && endSnapPoint != null && endSnapPoint.isAfter(start);
    if (canUseEndSnapPoint) {
      // Calculate the new end time.
      end = endSnapPoint;
      start = end.subtract(duration);
    }

    // Update the event with the new range.
    final newRange = DateTimeRange(start: start, end: end);
    final updatedEvent = event.copyWith(dateTimeRange: newRange.asLocal);

    // Remove now from the snap points.
    if (snapToTimeIndicator) removeSnapPoint(now);

    return updatedEvent;
  }

  /// Update the [CalendarEvent] based on the [direction] and [cursorDateTime] delta.
  @override
  CalendarEvent<T>? resizeEvent(CalendarEvent<T> event, ResizeDirection direction, DateTime cursorDateTime) {
    // Ignore vertical direction resizing.
    if (!direction.vertical) return null;

    // Add now to the snap points.
    late final now = DateTime.now().asUtc;
    if (snapToTimeIndicator) addSnapPoint(now);

    final cursorSnapPoint = findSnapPoint(cursorDateTime, snapRange) ?? cursorDateTime;

    // Remove now from the snap points.
    if (snapToTimeIndicator) removeSnapPoint(now);

    final dateTimeRange = switch (direction) {
      ResizeDirection.top => calculateDateTimeRangeFromStart(event.dateTimeRangeAsUtc, cursorSnapPoint),
      ResizeDirection.bottom => calculateDateTimeRangeFromEnd(event.dateTimeRangeAsUtc, cursorSnapPoint),
      _ => null
    };
    if (dateTimeRange == null) return null;

    return event.copyWith(dateTimeRange: dateTimeRange.asLocal);
  }

  @override
  CalendarEvent<T>? createEvent(DateTime cursorDateTime) {
    final event = super.createEvent(cursorDateTime);
    if (event == null) return null;

    // TODO: This might need to take `dateTimeRange` into account otherwise some new events might be created in undisplayed area's.
    var range = newEvent!.dateTimeRangeAsUtc;

    if (cursorDateTime.isAfter(range.start)) {
      range = DateTimeRange(start: range.start, end: cursorDateTime);
    } else if (cursorDateTime.isBefore(range.start)) {
      range = DateTimeRange(start: cursorDateTime, end: range.start);
    }

    return event.copyWith(dateTimeRange: range.asLocal);
  }
}
