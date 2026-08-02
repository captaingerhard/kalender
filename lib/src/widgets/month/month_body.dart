import 'package:flutter/material.dart';
import 'package:kalender/kalender.dart';
import 'package:kalender/src/models/providers/calendar_provider.dart';
import 'package:kalender/src/widgets/drag_targets/multi_day_drag_target.dart';
import 'package:kalender/src/widgets/draggable/multi_day_draggable.dart';
import 'package:kalender/src/widgets/events_widgets/multi_day_events_widget.dart';

/// This widget is used to display a month body.
///
/// The month body's content:
///   - Static content [MonthGrid].
///   - Dynamic content such as the [PageView] which renders [MultiDayEventWidget], [MultiDayDragTarget], [MultiDayDraggable].
class MonthBody<T extends Object?> extends StatefulWidget {
  /// The [MultiDayBodyConfiguration] that will be used by the [MonthBody].
  final MultiDayHeaderConfiguration<T>? configuration;

  /// Creates a new [MonthBody].
  const MonthBody({super.key, this.configuration});

  @override
  State<MonthBody<T>> createState() => _MonthBodyState<T>();
}

class _MonthBodyState<T extends Object?> extends State<MonthBody<T>> {
  /// The distance a pointer must travel before the scroll axis of the current
  /// gesture is locked.
  static const _axisLockThreshold = 12.0;

  /// The axis the active gesture is locked to, or `null` while undetermined.
  /// Prevents the vertical scroll view and horizontal [PageView] from fighting
  /// over near-diagonal drags in the dynamic-height layout.
  Axis? _lockedAxis;

  int? _activePointer;
  Offset _pointerDownPosition = Offset.zero;

  void _handlePointerDown(PointerDownEvent event) {
    if (_activePointer != null) return;
    _activePointer = event.pointer;
    _pointerDownPosition = event.position;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointer || _lockedAxis != null) return;
    final delta = event.position - _pointerDownPosition;
    if (delta.distance < _axisLockThreshold) return;
    setState(() {
      _lockedAxis = delta.dx.abs() >= delta.dy.abs() ? Axis.horizontal : Axis.vertical;
    });
  }

  void _handlePointerUp(PointerUpEvent event) => _resetAxisLock(event.pointer);
  void _handlePointerCancel(PointerCancelEvent event) => _resetAxisLock(event.pointer);

  void _resetAxisLock(int pointer) {
    if (pointer != _activePointer) return;
    _activePointer = null;
    if (_lockedAxis != null) setState(() => _lockedAxis = null);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.provider<T>();
    final calendarController = context.calendarController<T>();

    assert(
      calendarController.viewController is MonthViewController<T>,
      'The CalendarController\'s $ViewController<$T> needs to be a $MonthViewController<$T>',
    );

    if (widget.configuration != null && widget.configuration is! MonthBodyConfiguration<T>) {
      debugPrint('Warning: The configuration provided to the $MonthBody is not a $MonthBodyConfiguration.');
    }

    final viewController = calendarController.viewController as MonthViewController<T>;
    final viewConfiguration = viewController.viewConfiguration;
    final bodyConfiguration = widget.configuration ?? MultiDayHeaderConfiguration();
    final pageNavigation = viewConfiguration.pageNavigationFunctions;
    final pageTriggerConfiguration = bodyConfiguration.pageTriggerConfiguration;
    final tileHeight = bodyConfiguration.tileHeight;

    // Resolve the dynamic-height options (only available on [MonthBodyConfiguration]).
    final monthBodyConfiguration = bodyConfiguration is MonthBodyConfiguration<T> ? bodyConfiguration : null;
    final dynamicRowHeight = monthBodyConfiguration?.dynamicRowHeight ?? false;
    final maxEventsBeforeOverlay = monthBodyConfiguration?.maxEventsBeforeOverlay;
    final minEventRows = monthBodyConfiguration?.minEventRows ?? 2;

    // Lock scrolling to a single axis per gesture so vertical scrolling and
    // horizontal month paging don't interfere with each other.
    final pagePhysics =
        _lockedAxis == Axis.vertical ? const NeverScrollableScrollPhysics() : monthBodyConfiguration?.pageScrollPhysics;
    final verticalPhysics = _lockedAxis == Axis.horizontal
        ? const NeverScrollableScrollPhysics()
        : (monthBodyConfiguration?.scrollPhysics ?? const ClampingScrollPhysics());

    final calendarComponents = provider.components;
    final styles = calendarComponents?.monthComponentStyles?.bodyStyles;
    final components = calendarComponents?.monthComponents?.bodyComponents ?? MonthBodyComponents<T>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final pageWidth = constraints.maxWidth;
        final pageHeight = constraints.maxHeight;

        // Calculate the width of a single day.
        final dayWidth = pageWidth / DateTime.daysPerWeek;

        final pageView = PageView.builder(
          controller: viewController.pageController,
          physics: pagePhysics,
          itemCount: pageNavigation.numberOfPages,
          onPageChanged: (index) {
            final visibleRange = pageNavigation.dateTimeRangeFromIndex(index);
            viewController.visibleDateTimeRange.value = visibleRange;
            context.callbacks<T>()?.onPageChanged?.call(visibleRange);
          },
          itemBuilder: (context, index) {
            final visibleRange = pageNavigation.dateTimeRangeFromIndex(index);
            final numberOfRows = pageNavigation.numberOfRowsForRange(visibleRange);

            // Builds the multi-day events widget shared by both layout modes.
            MultiDayEventWidget<T> eventsWidget(DateTimeRange visibleDateTimeRange, int? maxNumberOfRows) {
              return MultiDayEventWidget<T>(
                visibleDateTimeRange: visibleDateTimeRange,
                tileHeight: tileHeight,
                maxNumberOfRows: maxNumberOfRows,
                showAllEvents: true,
                generateMultiDayLayoutFrame: bodyConfiguration.generateMultiDayLayoutFrame,
                overlayBuilders: components.overlayBuilders ?? calendarComponents?.overlayBuilders,
                overlayStyles: styles?.overlayStyles ?? calendarComponents?.overlayStyles,
                eventPadding: bodyConfiguration.eventPadding,
              );
            }

            // Builds the header row with the day numbers for a week.
            List<Widget> weekDayHeaders(DateTimeRange visibleDateTimeRange) {
              return List.generate(7, (i) {
                final date = visibleDateTimeRange.start.addDays(i);
                final monthDayHeaderStyle = styles?.monthDayHeaderStyle;
                return components.monthDayHeaderBuilder.call(date, monthDayHeaderStyle);
              });
            }

            // Builds the optional day background layer for a week.
            Widget? weekDayBackgrounds(DateTimeRange visibleDateTimeRange) {
              if (components.dayBackgroundBuilder == null) return null;
              return Row(
                children: List.generate(7, (i) {
                  final date = visibleDateTimeRange.start.addDays(i);
                  final color = components.dayBackgroundBuilder!(date);
                  return Expanded(
                    child: color != null
                        ? ColoredBox(color: color, child: const SizedBox.expand())
                        : const SizedBox.expand(),
                  );
                }),
              );
            }

            MultiDayDragTarget<T> weekDragTarget(DateTimeRange visibleDateTimeRange) {
              return MultiDayDragTarget<T>(
                pageTriggerSetup: pageTriggerConfiguration,
                visibleDateTimeRange: visibleDateTimeRange,
                dayWidth: dayWidth,
                pageWidth: pageWidth,
                tileHeight: tileHeight,
                allowSingleDayEvents: true,
                leftPageTrigger: components.leftTriggerBuilder,
                rightPageTrigger: components.rightTriggerBuilder,
              );
            }

            if (dynamicRowHeight) {
              // Each week grows to fit its events and the whole body scrolls
              // vertically when the combined height exceeds the viewport.
              final weeks = List.generate(numberOfRows, (weekIndex) {
                final visibleDateTimeRange = DateTimeRange(
                  start: visibleRange.start.addDays(weekIndex * 7),
                  end: visibleRange.start.addDays((weekIndex * 7) + 7),
                );

                final dayBackgrounds = weekDayBackgrounds(visibleDateTimeRange);
                final minEventsHeight = minEventRows * tileHeight + bodyConfiguration.bottomPadding;

                return Stack(
                  children: [
                    Positioned.fill(child: _dynamicWeekGrid(context, styles?.monthGridStyle, isFirst: weekIndex == 0)),
                    if (dayBackgrounds != null) Positioned.fill(child: dayBackgrounds),
                    Positioned.fill(child: MultiDayDraggable<T>(visibleDateTimeRange: visibleDateTimeRange)),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: weekDayHeaders(visibleDateTimeRange),
                        ),
                        ConstrainedBox(
                          constraints: BoxConstraints(minHeight: minEventsHeight),
                          child: Padding(
                            padding: EdgeInsets.only(bottom: bodyConfiguration.bottomPadding),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: eventsWidget(visibleDateTimeRange, maxEventsBeforeOverlay),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Positioned.fill(child: weekDragTarget(visibleDateTimeRange)),
                  ],
                );
              });

              return SingleChildScrollView(
                physics: verticalPhysics,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: pageHeight),
                  child: Column(mainAxisSize: MainAxisSize.min, children: weeks),
                ),
              );
            }

            final weekHeight = pageHeight / numberOfRows;

            final multiDayEvents = List.generate(
              numberOfRows,
              (index) {
                final visibleDateTimeRange = DateTimeRange(
                  start: visibleRange.start.addDays(index * 7),
                  end: visibleRange.start.addDays((index * 7) + 7),
                );

                final multiDayDragTarget = weekDragTarget(visibleDateTimeRange);
                final draggable = MultiDayDraggable<T>(visibleDateTimeRange: visibleDateTimeRange);
                final dayBackgrounds = weekDayBackgrounds(visibleDateTimeRange);
                final dates = weekDayHeaders(visibleDateTimeRange);

                return Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (dayBackgrounds != null) Positioned.fill(child: dayBackgrounds),
                      Positioned.fill(child: draggable),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: weekHeight,
                        child: Column(
                          children: [
                            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: dates),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  // Subtract 1 to account for the extra widget at the bottom.
                                  final maxNumberOfVerticalEvents = (constraints.maxHeight / tileHeight).floor() - 1;
                                  return eventsWidget(visibleDateTimeRange, maxNumberOfVerticalEvents);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned.fill(child: multiDayDragTarget),
                    ],
                  ),
                );
              },
            );

            final monthGridStyle = styles?.monthGridStyle;
            final monthGrid = components.monthGridBuilder.call(monthGridStyle, numberOfRows);

            return SizedBox(
              width: pageWidth,
              height: pageHeight,
              child: Stack(
                children: [
                  Positioned.fill(child: monthGrid),
                  Positioned.fill(child: Column(children: multiDayEvents)),
                ],
              ),
            );
          },
        );

        // The axis lock is only needed when the body can scroll vertically.
        if (!dynamicRowHeight) return pageView;
        return Listener(
          onPointerDown: _handlePointerDown,
          onPointerMove: _handlePointerMove,
          onPointerUp: _handlePointerUp,
          onPointerCancel: _handlePointerCancel,
          child: pageView,
        );
      },
    );
  }

  /// Builds the grid lines for a single week when [MonthBodyConfiguration.dynamicRowHeight] is enabled.
  ///
  /// Unlike the [MonthGrid] used in the fixed-height layout, the grid is drawn
  /// per week so the horizontal lines always align with the (variable) week
  /// heights and scroll together with the content.
  Widget _dynamicWeekGrid(BuildContext context, MonthGridStyle? style, {required bool isFirst}) {
    final thickness = style?.thickness ?? 0;
    final color = style?.color ?? Theme.of(context).colorScheme.surfaceContainerHighest;

    return Column(
      children: [
        if (isFirst) Divider(height: thickness, thickness: thickness, color: color),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 0; i < 8; i++) VerticalDivider(width: thickness, thickness: thickness, color: color),
            ],
          ),
        ),
        Divider(height: thickness, thickness: thickness, color: color),
      ],
    );
  }
}
