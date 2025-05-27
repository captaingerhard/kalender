This Flutter package offers a Calendar Widget featuring a Day, MultiDay and Month views. Moreover, it empowers you to tailor the visual and behavioral aspects of the calendar.

## Web Demo

Try it out [here](https://werner-scholtz.github.io/kalender/)

## Features

* **Views:** Day, Multi-day and Month.
* **Reschedule:** Drag and Drop events. 
* **Resize:** Resize events on desktop and mobile.
* **Controllers:** Manage your calendar with these controllers. [find out more](#controllers)
* **Behavior:** Choose how you want to handle interaction with the calendar. [find out more](#behavior)
* **Appearance:** Customize the default components or provide custom builders. [find out more](#general-components)
* **Event layout:** Use a provided layout strategy or create a custom one. [find out more](#event-layout)

## Roadmap

### Features

* **Directionality:** Right to Left directionality.
* **Views:** FreeScroll calender view.

### Examples

* **Event layout:** Examples of how to leverage this to achieve specific layouts.
* **Repeating Events:** Repeating events that only have to be added once.

## Basic Usage

A minimal example to get you started:

```dart
final eventsController = DefaultEventsController();
final calendarController = CalendarController();
final tileComponents = TileComponents(
  tileBuilder: (event) => Container(color: Colors.green),
);

/// Add a [CalendarEvent] to the [EventsController].
void addEvents() {
  eventsController.addEvent(CalendarEvent(
    dateTimeRange: DateTimeRange(start: now, end: now.add(const Duration(hours: 1))),
    data: "Event 1",
  ));
}

Widget build(BuildContext context) {  
  return CalendarView(
    eventsController: eventsController,
    calendarController: calendarController,
    viewConfiguration: MultiDayViewConfiguration.singleDay(),
    callbacks: CalendarCallbacks(
      onEventTapped: (event, renderBox) => controller.selectEvent(event),
      onEventCreate: (event) => event.copyWith(data: "Some data"),
      onEventCreated: (event) => eventsController.addEvent(event),
    ),
    header: CalendarHeader(
      multiDayTileComponents: tileComponents,
    ),
    body: CalendarBody(
      multiDayTileComponents: tileComponents,
      monthTileComponents: tileComponents,
    ),
  );
}
```

## Views

The calendar widget supports three main views:

- **MultiDayView:** Displays one or more days with time on the vertical axis, ideal for detailed scheduling.
- **MonthView:** Shows an entire month at a glance, with days arranged horizontally.
- **ScheduleView:** Presents events in a continuous, scrollable list, focusing on upcoming or grouped events rather than a grid.

> **Note:** The ScheduleView can be configured to be either continuous (infinite scroll) or paginated, depending on your application's requirements.

Each view is designed for different use cases and can be configured to match your application's needs.

These views can be configured with [ViewConfiguration](https://github.com/werner-scholtz/kalender/blob/5407e6af18df4e356abab12a0425221e1fe56fa9/lib/src/models/view_configurations/view_configuration.dart#L11) objects.
- The MultiDayView is configured with the [MultiDayViewConfiguration](https://github.com/werner-scholtz/kalender/blob/5407e6af18df4e356abab12a0425221e1fe56fa9/lib/src/models/view_configurations/multi_day_view_configuration.dart#L19).
- The MonthView is configured with the [MonthViewConfiguration](https://github.com/werner-scholtz/kalender/blob/5407e6af18df4e356abab12a0425221e1fe56fa9/lib/src/models/view_configurations/month_view_configuration.dart#L6).
- The Schedule view is configured with the [ScheduleViewConfiguration](TODO add link)

### MultiDayViewConfiguration
The `MultiDayViewConfiguration` has constructors for generic use cases such as:

- [MultiDayViewConfiguration.singleDay()](https://github.com/werner-scholtz/kalender/blob/5407e6af18df4e356abab12a0425221e1fe56fa9/lib/src/models/view_configurations/multi_day_view_configuration.dart#L36)

<img src="https://github.com/werner-scholtz/kalender/blob/main/readme_assets/day_view.png?raw=true" width="25%"/> 

- [MultiDayViewConfiguration.week()](https://github.com/werner-scholtz/kalender/blob/5407e6af18df4e356abab12a0425221e1fe56fa9/lib/src/models/view_configurations/multi_day_view_configuration.dart#L53)

<img src="https://github.com/werner-scholtz/kalender/blob/main/readme_assets/week_view.png?raw=true" width="25%"/> 

- [MultiDayViewConfiguration.custom()](https://github.com/werner-scholtz/kalender/blob/5407e6af18df4e356abab12a0425221e1fe56fa9/lib/src/models/view_configurations/multi_day_view_configuration.dart#L87)

<img src="https://github.com/werner-scholtz/kalender/blob/main/readme_assets/custom_view.png?raw=true" width="25%"/> 

### MonthViewConfiguration
The `MonthViewConfiguration` currently only has one constructor.

- [MonthViewConfiguration.singleMonth()](https://github.com/werner-scholtz/kalender/blob/5407e6af18df4e356abab12a0425221e1fe56fa9/lib/src/models/view_configurations/month_view_configuration.dart#L19C26-L19C37)

<img src="https://github.com/werner-scholtz/kalender/blob/main/readme_assets/month_view.png?raw=true" width="25%"/> 

### ScheduleViewConfiguration
The `ScheduleViewConfiguration` has two constructors:
- [ScheduleViewConfiguration.continuous](TODO: add link)
TODO: add image

- [ScheduleViewConfiguration.paginated](TODO: add link)
TODO: add image

## Controllers

The two controllers EventsController and CalendarController do what their names imply:

### EventsController

The [EventsController](https://github.com/werner-scholtz/kalender/blob/d79a8ea7fa1474a9085cb835e25a89ed9b7872a5/lib/src/models/controllers/events_controller.dart#L8) manages and exposes events to calendar widgets.
It has a few functions to manipulate events:
- `addEvent` Add a new event.
- `addEvents` Add multiple new events.
- `removeEvent` Remove a event.
- `removeEvents` Removes a list of events.
- `removeWhere` Remove events where they match a test case.
- `updateEvent` Updates an event.
- `byId` Returns an event with the given id if it exists.
- `clearEvents` Clear all the stored events.
- `eventsFromDateTimeRange` Returns events that occur during the given dateTimeRange.

### CalendarController

The [CalendarController](https://github.com/werner-scholtz/kalender/blob/d79a8ea7fa1474a9085cb835e25a89ed9b7872a5/lib/src/models/controllers/calendar_controller.dart#L15) allows you to manage a single calendar widget. 

It exposes details about what the widget is displaying.

- `visibleDateTimeRange`: A `ValueNotifier` containing the `DateTimeRange` that is currently visible.
- `visibleEvents`: A `ValueNotifier` that contains the `CalendarEvent`s that are currently visible. 
- `selectedEvent`: A `ValueNotifier` that contains the selected `CalendarEvent`.

> The `selectedEvent` is the event that currently has focus within the calendar widget. This results in the [TileComponents.dropTargetTile](https://github.com/werner-scholtz/kalender/blob/4506024937ae4e0d500bf169d297cb3f20604e92/lib/src/models/components/tile_components.dart#L27) being rendered on top of the selected event's widget, on mobile if a event is selected it wil render the resize handles as well.

This controller has a few functions for navigating the calendar widget:

- `jumpToPage`: Jump to a specific page.
- `jumpToDate`: Jump to a specific date.
- `animateToNextPage`: Animate to the next page.
- `animateToPreviousPage`: Animate to the previous page.
- `animateToDate`: Animate to the given date.
- `animateToDateTime`: Animate to the given date time.
- `animateToEvent` Animate to the given event.

> The `CalendarController` uses a [ViewController](https://github.com/werner-scholtz/kalender/blob/d79a8ea7fa1474a9085cb835e25a89ed9b7872a5/lib/src/models/controllers/view_controller.dart#L8) internally, which provides navigation and state management for a specific calendar view type (MultiDay, Month, or Schedule).  
>
> There are specialized implementations of `ViewController` for each view:
> - [MultiDayViewController](https://github.com/werner-scholtz/kalender/blob/d79a8ea7fa1474a9085cb835e25a89ed9b7872a5/lib/src/models/controllers/view_controller.dart#L70)
> - [MonthViewController](https://github.com/werner-scholtz/kalender/blob/d79a8ea7fa1474a9085cb835e25a89ed9b7872a5/lib/src/models/controllers/view_controller.dart#L243)
> - [ScheduleViewController](https://github.com/werner-scholtz/kalender/blob/d79a8ea7fa1474a9085cb835e25a89ed9b7872a5/lib/src/models/controllers/view_controller.dart#L349)
>
> Each of these controllers works with a corresponding [ViewConfiguration](https://github.com/werner-scholtz/kalender/blob/d79a8ea7fa1474a9085cb835e25a89ed9b7872a5/lib/src/models/view_configurations/view_configuration.dart#L11) (such as `MultiDayViewConfiguration`, `MonthViewConfiguration`, or `ScheduleViewConfiguration`) to handle view-specific logic and behaviors.


## Behavior

### Callbacks

The calendar has a few useful callback functions, which can change how interactions with the calendar widget is handled.

<details>
  <summary>CalendarCallbacks details</summary>

  ```dart
  CalendarCallbacks(
    // Called when an event is tapped.
    onEventTapped: (event, renderBox) {},

    // Called when an event is about to be created.
    onEventCreate: (event) {
      // This allows you to modify the event before it is created.
      return event.copyWith(data: data);
    }
    
    // Called when a new event has been created.
    onEventCreated: (event) {
      // Add the event to the eventsController.
      eventsController.addEvent(event);
    },

    // Called before a event is changed.
    onEventChange: (event) {}

    // Called when a event has been changed (rescheduled / resized)
    onEventChanged: (event, updatedEvent) {
      // Do something with the updated event.
      // ex. Update it in your database/long term storage.
    },

    // Called when a page is changed.
    //
    // Alternatively you can listen to the [CalendarController.visibleDateTimeRange] for updates.
    onPageChanged: (visibleDateTimeRange) {},

    /// Called when a user taps on the calendar (Multiday body).
    onTapped(date) {},

    /// Called when a user taps on the calendar (Multiday header / Month body).
    onMultiDayTapped(dateRange) {},
  )
  ```
  </summary>
</details>


### Header and Body

The `CalendarHeader` and `CalendarBody` both take configuration object's for the different `ViewConfigurations`.
Some behaviors that can be customized:
- Page/Scroll navigation when rescheduling events.
- Page/Scroll physics.
- Event layout strategy.

The `CalendarHeader` and `CalendarBody` also take a `CalendarInteraction` ValueNotifier, which allows you to change how the user is allowed to interact with the calendar.
- allowResizing
- allowRescheduling
- allowEventCreation
- createEventGesture

The `CalendarBody` takes a `CalendarSnapping` ValueNotifier that allows you to customize how snapping works for Day/Multiday views.
- snapIntervalMinutes
- snapToTimeIndicator
- snapToOtherEvents
- snapRange
- eventSnapStrategy

Examples:
<details>
  <summary>MultiDayHeaderConfiguration</summary>

  ```dart
  CalendarHeader(
    multiDayHeaderConfiguration: MultiDayHeaderConfiguration(
      // Whether to show event tiles, useful if you want to display the header but not the tiles.
      showTiles: true,
      // The height of the tiles.
      tileHeight: 24,
      // Multi day event layout.
      generateMultiDayLayoutFrame: defaultMultiDayFrameGenerator,
      // Maximum number of vertical events.
      maximumNumberOfVerticalEvents: null,
      // The padding used around events.
      eventPadding: EdgeInserts.zero,
      // The configuration for triggering page navigation.
      pageTriggerConfiguration: PageTriggerConfiguration(),
      // The configuration for triggering scroll navigation.
      scrollTriggerConfiguration: ScrollTriggerConfiguration(),
    ),
    interaction: ValueNotifier(
      CalendarInteraction(
        // Allow events to be resized.
        allowResizing: true,
        // Allow events to be rescheduled.
        allowRescheduling: true,
        // Allow events to be created.
        allowEventCreation: true,
      ),
    ),
  );
  ```
  </summary>
</details>

<details>
  <summary>MultiDayBodyConfiguration</summary>

  ```dart
  CalendarBody(
    multiDayBodyConfiguration: MultiDayBodyConfiguration(
      // Whether to show events that are longer than 1 day.
      showMultiDayEvents: true,
      // The padding between events and the edge of the day.
      horizontalPadding: EdgeInsets.only(left: 0, right: 4),
      // The minimum height of a tile.
      minimumTileHeight: 24.0,
      // The configuration for triggering page navigation.
      pageTriggerConfiguration: PageTriggerConfiguration(),
      // The configuration for triggering scroll navigation.
      scrollTriggerConfiguration: ScrollTriggerConfiguration(),
      // The layout strategy used by the body to layout events.
      eventLayoutStrategy: overlapLayoutStrategy,
      // The physics used by the scrollable body.
      scrollPhysics: BouncingScrollPhysics(),
      // The physics used by the page view.
      pageScrollPhysics: BouncingScrollPhysics(),
    ),
    interaction: ValueNotifier(
      CalendarInteraction(
        // Allow events to be resized.
        allowResizing: true,
        // Allow events to be rescheduled.
        allowRescheduling: true,
        // Allow events to be created.
        allowEventCreation: true,
      ),
    ),
    snapping: ValueNotifier(
      CalendarSnapping(
        snapIntervalMinutes: 15,
        // Whether to snap to the time indicator.
        snapToTimeIndicator: true,
        // Whether to snap to other events.
        snapToOtherEvents: true,
        // The range in which events will be snapped,
        // ex. 15 minutes: A event will snap to other events that are within 15 minutes from it.
        snapRange: Duration(minutes: 5),
        // The strategy used to snap events to specific intervals.
        eventSnapStrategy: defaultSnapStrategy,
      ),
    ),
  );
  ```
  </summary>
</details>

<details>
  <summary>MonthBodyConfiguration</summary>

  ```dart
  CalendarBody(
    monthBodyConfiguration: MonthBodyConfiguration(
      // Whether to show event tiles, useful if you want to display the header but not the tiles.
      showTiles: true,
      // The height of the tiles.
      tileHeight: 24,
      // Multi day frame generator.
      generateMultiDayLayoutFrame: defaultMultiDayFrameGenerator,
      // The padding used around events.
      eventPadding: EdgeInserts.zero,
      // The layout strategy used to layout events.
      eventLayoutStrategy: defaultMultiDayLayoutStrategy,
      // The configuration for triggering page navigation.
      pageTriggerConfiguration: PageTriggerConfiguration(),
      // The configuration for triggering scroll navigation.
      scrollTriggerConfiguration: ScrollTriggerConfiguration(),
    ),
    interaction: ValueNotifier(
      CalendarInteraction(
        // Allow events to be resized.
        allowResizing: true,
        // Allow events to be rescheduled.
        allowRescheduling: true,
        // Allow events to be created.
        allowEventCreation: true,
      ),
    ),
  );
  ```
  </summary>
</details>

<details>
  <summary>ScheduleViewConfiguration</summary>

  ```dart
  CalendarBody(
    scheduleBodyConfiguration: ScheduleBodyConfiguration(
      // Behavior of empty days in the schedule body.
      emptyDay: EmptyDayBehavior.hide,
      // The configuration for triggering page navigation.
      pageTriggerConfiguration: PageTriggerConfiguration(),
      // The configuration for triggering scroll navigation.
      scrollTriggerConfiguration: ScrollTriggerConfiguration(),
      // The physics used by the scrollable body.
      scrollPhysics: BouncingScrollPhysics(),
      // The physics used by the page view. (for paginated views)
      pageScrollPhysics: BouncingScrollPhysics(),
    ),
    interaction: ValueNotifier(
      CalendarInteraction(
        // Allow events to be resized.
        allowResizing: true,
        // Allow events to be rescheduled.
        allowRescheduling: true,
        // Allow events to be created.
        allowEventCreation: true,
      ),
    ),
  );
  ```
  </summary>
</details>

### Zoom Example

It is possible to zoom the calendar in/out.
The [`demo`](https://github.com/werner-scholtz/kalender/tree/main/examples/demo) example shows how this can be accomplished with the [CalendarZoomDetector](https://github.com/werner-scholtz/kalender/blob/main/examples/demo/lib/widgets/zoom.dart)


## Customizing the look

There are a few ways to customize the look of the calendar:
- [Tile Components](#tile-components) allows you change the look of events rendered in the calendar.
// TODO: mention schedule tile components.

General Components:
- [Multi-day Components](#month-components) allows you to change the look of the day and multi-day views.
- [Month Components](#tile-components) allows you to change the look of the month view.

### Tile Components

The `TileComponents` object is used to customize the look of the tiles displayed in the calendar.
The `CalendarBody` and `CalendarHeader` have a `TileComponents` object that can be customized.

<details>
  <summary>TileComponents details</summary>

  ```dart
  TileComponents(
    // The default builder for stationary event tiles.
    tileBuilder: (event) => Container(),

    // The builder for the stationary event tile. (When it is being dragged)
    tileWhenDraggingBuilder: (event) => Container(),

    // The builder for the feedback tile, follows the cursor/finger. (When it is being dragged)
    feedbackTileBuilder: (event, dropTargetWidgetSize) => Container(),

    // The builder for the drop target event tile.
    dropTargetTile: (event) => Container(),

    // The dragAnchorStrategy used by the [feedbackTileBuilder].
    dragAnchorStrategy: childDragAnchorStrategy,

    // A widget that allows you to customize where the resize handles are placed vertically.
    // Your widget should extend the `ResizeHandlePositionerWidget`
    verticalHandlePositioner: (startResizeHandle, endResizeHandle, showStart, showEnd) => ResizeHandlePositionerWidget() , 

    // The vertical resize handle.
    verticalResizeHandle: Container(),

    // A widget that allows you to customize where the resize handles are placed horizontally.
    // Your widget should extend the `ResizeHandlePositionerWidget`
    horizontalHandlePositioner: (startResizeHandle, endResizeHandle, showStart, showEnd) => ResizeHandlePositionerWidget() ,

    // The horizontal resize handle.
    horizontalResizeHandle: Container(),
  )
  ```
  </summary>
</details>

/// TODO: Add schedule components.



### General Components

The CalendarView takes a components object.

> For every type of `ViewConfiguration` there are `Header` and `Body` components which can be customized.

By default the calendar uses default components which can be customized with `ComponentStyles`, you have the option to override these components by supplying a builder to the `Components` object.

#### Default Component Styles

> You can style the default components by passing the CalendarView `CalendarComponents` object that contains a [`MonthComponentStyles`](https://github.com/werner-scholtz/kalender/blob/main/lib/src/models/components/month_styles.dart) and/or [`MultiDayComponentStyles`](https://github.com/werner-scholtz/kalender/blob/main/lib/src/models/components/multi_day_styles.dart).

#### Custom Components

<details>
  <summary>MonthComponents</summary>

  ```dart
  CalendarView(
    components: CalendarComponents(
      monthComponents: MonthComponents(
        headerComponents: MonthHeaderComponents(
          // Custom day header builder.
          weekDayHeaderBuilder: (date, style) => SizedBox(),
        ),
        bodyComponents: MonthBodyComponents(
          // Custom grid builder.
          monthGridBuilder: (style) => SizedBox(),

          // Custom left trigger. (Must constrain the width)
          leftTriggerBuilder: (pageWidth) => SizedBox(),

          // Custom right trigger. (Must constrain the width)
          rightTriggerBuilder: (pageWidth) => SizedBox(),

          // Custom overlay builders.
          overlayBuilders: OverlayBuilders(
            // multiDayOverlayBuilder: , 
            // multiDayOverlayPortalBuilder: , 
            multiDayPortalOverlayButtonBuilder:(portalController, numberOfHiddenRows, style) => SizedBox(),
          ),
        ),
      ),
    ),
  );
  ```
  </summary>
</details>


<details>
  <summary>MultiDayComponents</summary>

  ```dart
  CalendarView(
    components: CalendarComponents(
      multiDayComponents: MultiDayComponents(
        headerComponents: MultiDayHeaderComponents(
          // Custom Day Header builder.
          dayHeaderBuilder: (date, style) => CustomWidget(),

          // Custom Week Number builder.
          weekNumberBuilder: (visibleDateTimeRange, style) => CustomWidget(),

          // Custom left trigger. (Must constrain the width)
          leftTriggerBuilder: (pageWidth) => SizedBox(width: pageWidth / 20),

          // Custom right trigger. (Must constrain the width)
          rightTriggerBuilder: (pageWidth) => SizedBox(width: pageWidth / 20),

          // Custom overlay builders.
          overlayBuilders: OverlayBuilders(
            // multiDayOverlayBuilder: , 
            // multiDayOverlayPortalBuilder: , 
            multiDayPortalOverlayButtonBuilder:(portalController, numberOfHiddenRows, style) => SizedBox(),
          ),
        ),
        bodyComponents: MultiDayBodyComponents(
          // Custom Hour Line builder.
          hourLines: (heightPerMinute, timeOfDayRange, style) => CustomWidget(),

          // Custom time line builder.
          timeline: (heightPerMinute, timeOfDayRange, style) => CustomWidget(),

          // Custom day separator builder.
          daySeparator: (style) => CustomWidget(),

          // Custom event indicator builder.
          timeIndicator: (timeOfDayRange, heightPerMinute, timelineWidth, style) => CustomWidget(),

          // Left trigger. (Must constrain the width)
          leftTriggerBuilder: (pageHeight) => SizedBox(width: pageHeight / 20),

          // Right trigger. (Must constrain the width)
          rightTriggerBuilder: (pageHeight) => SizedBox(width: pageHeight / 20),

          // Top trigger. (Must constrain the height)
          topTriggerBuilder: (viewPortHeight) => SizedBox(height: viewPortHeight / 20),

          // Bottom trigger. (Must constrain the height)
          bottomTriggerBuilder: (viewPortHeight) => SizedBox(height: viewPortHeight / 20),
        ),
      ),
    ),
  );
  ```
  </summary>
</details>


### Event layout

#### Vertical layout
The packages makes use of [CustomMultiChildLayout](https://api.flutter.dev/flutter/widgets/CustomMultiChildLayout-class.html) to layout event tiles.
The `CustomMultiChildLayout` uses a [MultiChildLayoutDelegate](https://api.flutter.dev/flutter/rendering/MultiChildLayoutDelegate-class.html) to determine the positions of tiles.

The package provides some default layoutStrategies, [overlapLayoutStrategy](https://github.com/werner-scholtz/kalender/blob/d79a8ea7fa1474a9085cb835e25a89ed9b7872a5/lib/src/layout_delegates/event_layout_delegate.dart#L26) and [sideBySideLayoutStrategy](https://github.com/werner-scholtz/kalender/blob/d79a8ea7fa1474a9085cb835e25a89ed9b7872a5/lib/src/layout_delegates/event_layout_delegate.dart#L41) for day/multi-day views.
You can create your own layoutStrategy, using the two provided strategies as a reference might be useful.

#### Horizontal layout

TODO: add docs about layout frames etc.