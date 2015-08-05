angular.module('BBAdminDashboard').directive 'bbResourceCalendar', (
    uiCalendarConfig, AdminCompanyService, AdminBookingService,
    AdminPersonService, $q, $sessionStorage, ModalForm, BBModel,
    AdminBookingPopup, $window, $bbug, ColorPalette, AppConfig, Dialog,
    $timeout, $compile, $templateCache) ->

  controller = ($scope, $attrs) ->

    $scope.eventSources = [
      events: (start, end, timezone, callback) ->
        $scope.loading = true
        $scope.getCompanyPromise().then (company) ->
          params =
            company: company
            start_date: start.format('YYYY-MM-DD')
            end_date: end.format('YYYY-MM-DD')
          AdminBookingService.query(params).then (bookings) ->
            $scope.loading = false
            b.resourceId = b.person_id for b in bookings
            callback(bookings)
    ]


    $scope.options = $scope.$eval $attrs.bbResourceCalendar
    $scope.options ||= {}

    height = if $scope.options.header_height
      $bbug($window).height() - $scope.options.header_height
    else
      800

    $scope.uiCalOptions =
      calendar:
        eventStartEditable: true
        eventDurationEditable: false
        height: height
        header:
          left: 'today,prev,next'
          center: 'title'
          right: 'timelineDay,agendaWeek,month'
        defaultView: 'timelineDay'
        views:
          agendaWeek:
            slotDuration: $scope.options.slotDuration || "00:05"
          month:
            eventLimit: 5
          timelineDay:
            slotDuration: $scope.options.slotDuration || "00:05"
            eventOverlap: false
            slotWidth: 44
        resourceLabelText: 'Staff'
        selectable: true
        resources: (callback) ->
          $scope.getPeople(callback)
        eventDrop: (event, delta, revertFunc) ->
          Dialog.confirm
            model: event
            body: "Are you sure you want to move this booking?"
            success: (model) =>
              $scope.updateBooking(event)
            fail: () ->
              revertFunc()
        eventClick: (event, jsEvent, view) ->
          $scope.editBooking(event)
        resourceRender: (resource, resourceTDs, dataTDs) ->
          for resourceTD in resourceTDs
            resourceTD.style.height = "44px"
            resourceTD.style.verticalAlign = "middle"
          dataTD.style.height = "44px" for dataTD in dataTDs
        eventRender: (event, element) ->
          service = _.findWhere($scope.services, {id: event.service_id})
          element.css('background-color', service.color)
          element.css('color', service.textColor)
          element.css('border-color', service.textColor)
        eventAfterRender: (event, elements, view) ->
          if view.type == "timelineDay"
            element.style.height = "27px" for element in elements
          elements.draggable()
        select: (start, end, jsEvent, view, resource) ->
          view.calendar.unselect()
          rid = null
          rid = resource.id if resource
          AdminBookingPopup.open
            item_defaults:
              date: start.format('YYYY-MM-DD')
              time: (start.hour() * 60 + start.minute())
              person: rid
        viewRender: (view, element) ->
          date = uiCalendarConfig.calendars.resourceCalendar.fullCalendar('getDate')
          $scope.currentDate = moment(date).format('YYYY-MM-DD')
        eventResize: (event, delta, revertFunc, jsEvent, ui, view) ->
          event.duration = event.end.diff(event.start, 'minutes')
          $scope.updateBooking(event)

    $scope.getPeople = (callback) ->
      $scope.loading = true
      $scope.getCompanyPromise().then (company) ->
        params = {company: company}
        AdminPersonService.query(params).then (people) ->
          $scope.loading = false
          $scope.people = _.sortBy people, 'name'
          p.title = p.name for p in $scope.people
          uiCalendarConfig.calendars.resourceCalendar.fullCalendar('refetchEvents')
          callback($scope.people)

    $scope.updateBooking = (booking) ->
      booking.person_id = booking.resourceId
      booking.$update().then (response) ->
        booking.resourceId = booking.person_id
        uiCalendarConfig.calendars.resourceCalendar.fullCalendar('updateEvent', booking)

    $scope.editBooking = (booking) ->
      ModalForm.edit
        templateUrl: 'edit_booking_modal_form.html'
        model: booking
        title: 'Edit Booking'
        success: (response) =>
          if response.is_cancelled
            uiCalendarConfig.calendars.resourceCalendar.fullCalendar('removeEvents', [response.id])
          else
            booking.resourceId = booking.person_id
            uiCalendarConfig.calendars.resourceCalendar.fullCalendar('updateEvent', booking)

    $scope.pusherSubscribe = () =>
      if $scope.company? && Pusher? && !$scope.pusher?
        $scope.pusher = new Pusher 'c8d8cea659cc46060608',
          authEndpoint: $scope.company.$link('pusher').href
          auth:
            headers:
              'App-Id' : AppConfig.appId
              'App-Key' : AppConfig.appKey
              'Auth-Token' : $sessionStorage.getItem('auth_token')
        channelName = "private-c#{$scope.company.id}-w#{$scope.company.numeric_widget_id}"
        if !$scope.pusher.channel(channelName)?
          $scope.pusher_channel = $scope.pusher.subscribe(channelName)
          pusherEvent = (res) =>
            if res.id?
              uiCalendarConfig.calendars.resourceCalendar.fullCalendar('refetchEvents')
          $scope.pusher_channel.bind 'booking', pusherEvent
          $scope.pusher_channel.bind 'cancellation', pusherEvent
          $scope.pusher_channel.bind 'updating', pusherEvent

    $scope.openDatePicker = ($event) ->
        $event.preventDefault()
        $event.stopPropagation()
        $scope.datePickerOpened = true

    $scope.updateDate = (date) ->
      if uiCalendarConfig.calendars.resourceCalendar
        uiCalendarConfig.calendars.resourceCalendar.fullCalendar('gotoDate', date)

    $scope.lazyUpdateDate = _.debounce($scope.updateDate, 400)

    $scope.datePickerOptions = {showButtonBar: false}

    $scope.$watch 'currentDate', (newDate, oldDate) ->
      $scope.lazyUpdateDate(newDate)


  link = (scope, element, attrs) ->

    scope.getCompanyPromise = () ->
      defer = $q.defer()
      if scope.company
        defer.resolve(scope.company)
      else
        AdminCompanyService.query(attrs).then (company) ->
          scope.company = company
          scope.pusherSubscribe()
          defer.resolve(scope.company)
      defer.promise

    scope.getCompanyPromise().then (company) ->
      company.$get('services').then (collection) ->
        collection.$get('services').then (services) ->
          scope.services = (new BBModel.Admin.Service(s) for s in services)
          ColorPalette.setColors(scope.services)

    $timeout () ->
      uiCalElement = angular.element(element.children()[1])
      toolbarElement = angular.element(uiCalElement.children()[0])
      toolbarLeftElement = angular.element(toolbarElement.children()[0])
      scope.currentDate = moment().format()
      datePickerElement = $compile($templateCache.get('calendar_date_picker.html'))(scope)
      toolbarLeftElement.append(datePickerElement)
    , 0

  {
    controller: controller
    link: link
    templateUrl: 'resource_calendar_main.html'
  }
