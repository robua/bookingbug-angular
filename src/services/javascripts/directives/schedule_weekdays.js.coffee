angular.module('BBAdminServices').directive 'scheduleWeekdays', (uiCalendarConfig, ScheduleRules) ->

  controller = ($scope, $attrs) ->

    $scope.calendarName = 'scheduleWeekdays'

    $scope.eventSources = [
      events: (start, end, timezone, callback) ->
        callback($scope.getEvents())
    ]

    $scope.getCalendarEvents = (start, end) ->
      events = uiCalendarConfig.calendars.scheduleWeekdays.fullCalendar('clientEvents',
        (e) ->
          (start.isAfter(e.start) || start.isSame(e.start)) &&
            (end.isBefore(e.end) || end.isSame(e.end)))

    options = $scope.$eval($attrs.scheduleWeekdays) or {}

    $scope.options =
      calendar:
        editable: false
        selectable: true
        defaultView: 'agendaSelectAcrossWeek'
        header:
          left: ''
          center: 'title'
          right: ''
        selectHelper: false
        eventOverlap: false
        views:
          agendaSelectAcrossWeek:
            duration:
              weeks: 1
            titleFormat: '[]'
            allDaySlot: false
            columnFormat: 'ddd'
            slotEventOverlap: false
            minTime: options.min_time || '00:00:00'
            maxTime: options.max_time || '24:00:00'
        select: (start, end, jsEvent, view) ->
          events = $scope.getCalendarEvents(start, end)
          if events.length > 0
            $scope.removeRange(start, end)
          else
            $scope.addRange(start, end)
        eventResizeStop: (event, jsEvent, ui, view) ->
          $scope.addRange(event.start, event.end)
        eventDrop: (event, delta, revertFunc, jsEvent, ui, view) ->
          if event.start.hasTime()
            orig =
              start: moment(event.start).subtract(delta)
              end: moment(event.end).subtract(delta)
            $scope.removeRange(orig.start, orig.end)
            $scope.addRange(event.start, event.end)
        eventClick: (event, jsEvent, view) ->
          $scope.removeRange(event.start, event.end)

    $scope.render = () ->
      uiCalendarConfig.calendars.scheduleWeekdays.fullCalendar('render')


  link = (scope, element, attrs, ngModel) ->

    scheduleRules = () ->
      new ScheduleRules(ngModel.$viewValue)

    scope.getEvents = () ->
      scheduleRules().toWeekdayEvents()

    scope.addRange = (start, end) ->
      ngModel.$setViewValue(scheduleRules().addWeekdayRange(start, end))
      ngModel.$render()

    scope.removeRange = (start, end) ->
      ngModel.$setViewValue(scheduleRules().removeWeekdayRange(start, end))
      ngModel.$render()

    ngModel.$render = () ->
      if uiCalendarConfig && uiCalendarConfig.calendars.scheduleWeekdays
        uiCalendarConfig.calendars.scheduleWeekdays.fullCalendar('refetchEvents')
        uiCalendarConfig.calendars.scheduleWeekdays.fullCalendar('unselect')

  {
    controller: controller
    link: link
    templateUrl: 'schedule_cal_main.html'
    require: 'ngModel'
    scope:
      render: '=?'
  }
