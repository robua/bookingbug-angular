'use strict';

angular.module('BB.Directives').directive 'bbTimeRangeStacked', () ->
  restrict: 'AE'
  replace: true
  scope : true
  controller : 'TimeRangeListStackedController',


angular.module('BB.Controllers').controller 'TimeRangeListStackedController', ($scope, $element, $attrs, $rootScope, $q, TimeService, AlertService, BBModel, FormDataStoreService, PersonService, PurchaseService, DateTimeUlititiesService) ->

  $scope.controller = "public.controllers.TimeRangeListStacked"
 
  FormDataStoreService.init 'TimeRangeListStacked', $scope, [
    'selected_slot'
    'original_start_date'
    'start_at_week_start'
  ]

  # show the loading icon
  $scope.notLoaded $scope
  $scope.available_times = 0

  $rootScope.connection_started.then ->

    # read initialisation attributes
    $scope.options = $scope.$eval($attrs.bbTimeRangeStacked) or {}

    if !$scope.time_range_length
      if $attrs.bbTimeRangeLength?
        $scope.time_range_length = $scope.$eval($attrs.bbTimeRangeLength)
      else if $scope.options and $scope.options.time_range_length
        $scope.time_range_length = $scope.options.time_range_length
      else
        $scope.time_range_length = 7

    if $attrs.bbDayOfWeek? or ($scope.options and $scope.options.day_of_week)
      $scope.day_of_week = if $attrs.bbDayOfWeek? then $scope.$eval($attrs.bbDayOfWeek) else $scope.options.day_of_week
 
    if $attrs.bbSelectedDay? or ($scope.options and $scope.options.selected_day)
      selected_day        = if $attrs.bbSelectedDay? then moment($scope.$eval($attrs.bbSelectedDay)) else moment($scope.options.selected_day)
      $scope.selected_day = selected_day if moment.isMoment(selected_day)

    # initialise the time range
    # last selected day is set (i.e, a user has already selected a date)
    if !$scope.start_date && $scope.last_selected_date
      if $scope.original_start_date 
        diff = $scope.last_selected_date.diff($scope.original_start_date, 'days')
        diff = diff % $scope.time_range_length
        diff = if diff is 0 then diff else diff + 1 
        start_date = $scope.last_selected_date.clone().subtract(diff, 'days')
        setTimeRange($scope.last_selected_date, start_date)
      else
        setTimeRange($scope.last_selected_date)
    # the current item already has a date
    else if $scope.bb.stacked_items[0].date
      setTimeRange($scope.bb.stacked_items[0].date.date)
    # selected day has been provided, use this to set the time
    else if $scope.selected_day
      $scope.original_start_date = $scope.original_start_date or moment($scope.selected_day)
      setTimeRange($scope.selected_day)
    # set the time range as today
    else
      $scope.start_at_week_start = true
      setTimeRange(moment())

    $scope.loadData()

  , (err) -> $scope.setLoadedAndShowError($scope, err, 'Sorry, something went wrong')


  setTimeRange = (selected_date, start_date) ->
    if start_date
      $scope.start_date = start_date
    else if $scope.day_of_week
      $scope.start_date = selected_date.clone().day($scope.day_of_week)
    else if $scope.start_at_week_start
      $scope.start_date = selected_date.clone().startOf('week')
    else
      $scope.start_date = selected_date.clone()

    $scope.selected_day = selected_date
    # convert selected day to JS date object for date picker, it needs
    # to be saved as a variable as functions cannot be passed into the
    # AngluarUI date picker
    $scope.selected_date = $scope.selected_day.toDate()
    
    isSubtractValid()


  $scope.add = (amount, type) ->
    $scope.selected_day = moment($scope.selected_date)
    switch type
      when 'days'
        setTimeRange($scope.selected_day.add(amount, 'days'))
      when 'weeks'
        $scope.start_date.add(amount, 'weeks')
        setTimeRange($scope.start_date)
    $scope.loadData()


  $scope.subtract = (amount, type) ->
    $scope.add(-amount, type)


  isSubtractValid = () ->
    $scope.is_subtract_valid = true

    diff = Math.ceil($scope.selected_day.diff(moment(), 'day', true))
    $scope.subtract_length = if diff < $scope.time_range_length then diff else $scope.time_range_length
    $scope.is_subtract_valid = false if diff <= 0

    if $scope.subtract_length > 1
      $scope.subtract_string = "Prev #{$scope.subtract_length} days"
    else if $scope.subtract_length is 1
      $scope.subtract_string = "Prev day"
    else
      $scope.subtract_string = "Prev"
 

  # called on datepicker date change
  $scope.selectedDateChanged = () ->
    setTimeRange(moment($scope.selected_date))
    $scope.selected_slot = null
    $scope.loadData()


  updateHideStatus = () ->
    for key, day of $scope.days
      $scope.days[key].hide = !day.date.isSame($scope.selected_day,'day')


  # calculate if the current earliest date is in the past - in which case we
  # might want to disable going backwards
  $scope.isPast = () ->
    return true if !$scope.start_date
    return moment().isAfter($scope.start_date)


  # check the status of the slot to see if it has been selected
  # NOTE: This is very costly to call from a view, please consider using ng-class
  # to access the status
  $scope.status = (day, slot) ->
    return if !slot

    status = slot.status()
    return status


  $scope.highlightSlot = (day, slot) ->

    if day and slot and slot.availability() > 0
      $scope.bb.clearStackedItemsDateTime()
      $scope.selected_slot.selected = false if $scope.selected_slot
      $scope.setLastSelectedDate(day.date)
      $scope.selected_slot = angular.copy(slot)
      $scope.selected_day  = day.date
      $scope.selected_date = day.date.toDate()

      # broadcast message to the accordian range groups
      $scope.$broadcast 'slotChanged', day, slot

      # set the date and time on the stacked items
      while slot
        for item in $scope.bb.stacked_items
          if item.service.self is slot.service.self and !item.date and !item.time
            item.setDate(day)
            item.setTime(slot)
            slot = slot.next
            break
   
      updateHideStatus()
      $rootScope.$broadcast "time:selected"


  # load the time data
  $scope.loadData = ->

    $scope.notLoaded $scope

    # if the selected date has already been loaded, there's no need to call the API
    if $scope.request and $scope.request.start.twix($scope.request.end).contains($scope.selected_day)
      updateHideStatus()
      $scope.setLoaded $scope
      return

    $scope.start_date = moment($scope.start_date)
    edate = moment($scope.start_date).add($scope.time_range_length, 'days')
    $scope.end_date = moment(edate).add(-1, 'days')

    $scope.request = {start: moment($scope.start_date), end: moment($scope.end_date)}

    pslots = []
    # group BasketItems's by their service id so that we only call the time data api once for each service
    grouped_items = _.groupBy $scope.bb.stacked_items, (item) -> return item.service.id
    grouped_items = _.toArray grouped_items

    for items in grouped_items
      pslots.push(TimeService.query({
        company: $scope.bb.company
        cItem: items[0]
        date: $scope.start_date
        end_date: $scope.end_date
        client: $scope.client
        available: 1
        #duration: duration
      }))

    $q.all(pslots).then (res) ->

      $scope.data_valid = true
      $scope.days = {}

      for items, _i in grouped_items
        slots = res[_i]
        $scope.data_valid = false if !slots || slots.length == 0

        for item in items
          # splice the selected times back into the result
          spliceExistingDateTimes(item, slots)

          item.slots = {}
          for own day, times of slots
            item.slots[day] = _.indexBy(times, 'time')

      if $scope.data_valid
        for k, v of res[0]
          $scope.days[k] = ({date: moment(k)})
        setEnabledSlots()
        updateHideStatus()
        $rootScope.$broadcast "TimeRangeListStacked:loadFinished"
      else
        # raise error

      $scope.setLoaded $scope

    , (err) -> $scope.setLoadedAndShowError($scope, err, 'Sorry, something went wrong')


  spliceExistingDateTimes = (stacked_item, slots) ->

    return if !stacked_item.datetime and !stacked_item.date 
    datetime = stacked_item.datetime or DateTimeUlititiesService.convertTimeSlotToMoment(stacked_item.date, stacked_item.time)
    if $scope.start_date <= datetime && $scope.end_date >= datetime
      time = DateTimeUlititiesService.convertMomentToTime(datetime)
      time_slot = _.findWhere(slots[datetime.toISODate()], {time: time})
      if !time_slot
        time_slot = stacked_item.time
        slots[datetime.toISODate()].splice(0, 0, time_slot)

      # ensure only the first time slot is marked as selected
      time_slot.selected = stacked_item.self is $scope.bb.stacked_items[0].self



  setEnabledSlots = () ->

    for day, day_data of $scope.days

      day_data.slots = {}

      if $scope.bb.stacked_items.length > 1
          
          for time, slot of $scope.bb.stacked_items[0].slots[day]

            slot = angular.copy(slot)

            isSlotValid = (slot) ->
              valid      = false
              time       = slot.time
              duration   = $scope.bb.stacked_items[0].service.duration
              next       = time + duration

              # now loop around the remaining items in the sequence looking for a slot
              for index in [1..$scope.bb.stacked_items.length-1]
                if !_.isEmpty($scope.bb.stacked_items[index].slots[day]) and $scope.bb.stacked_items[index].slots[day][next]
                  slot.next = angular.copy($scope.bb.stacked_items[index].slots[day][next])
                  slot = slot.next
                  next = next + $scope.bb.stacked_items[index].service.duration
                else
                  # invalid sequence permutation
                  return false

              return true

            # add the slot if it's valid and isn't already in the dataset
            if isSlotValid(slot)
              day_data.slots[slot.time] = slot #if !day_data.slots[slot.time]
      else

        for time, slot of $scope.bb.stacked_items[0].slots[day]
          day_data.slots[slot.time] = slot


  $scope.pretty_month_title = (month_format, year_format, seperator = '-') ->
    return if !$scope.start_date
    month_year_format = month_format + ' ' + year_format
    if $scope.start_date && $scope.end_date && $scope.end_date.isAfter($scope.start_date, 'month')
      start_date = $scope.start_date.format(month_format)
      start_date = $scope.start_date.format(month_year_format) if $scope.start_date.month() == 11
      return start_date + ' ' + seperator + ' ' + $scope.end_date.format(month_year_format)
    else
      return $scope.start_date.format(month_year_format)


  $scope.confirm = (route) ->

    # first check all of the stacked items
    for item in $scope.bb.stacked_items
      if !item.time
        AlertService.add("danger", { msg: "Select a time to continue your booking" })
        return false

    if $scope.bb.moving_booking? && $scope.bb.moving_booking.bookings?
      different = false
      for booking in $scope.bb.moving_booking.bookings
        found = false
        for item in $scope.bb.stacked_items
          if booking.getDateString() == item.date.string_date && booking.getTimeInMins() == item.time.time && booking.category_name == item.category_name
            found = true
        if !found
          different = true
          break
      if !different
        AlertService.add("danger", { msg: "Your treatments are already booked for this time." })
        return false

    # empty the current basket quickly
    $scope.bb.basket.clear()
    for item in $scope.bb.stacked_items
      $scope.bb.basket.addItem(item)

    if $scope.bb.moving_booking
      # if we're moving - confuirm everything in teh basket right now
      $scope.notLoaded $scope

      prom = PurchaseService.update({purchase: $scope.bb.moving_booking, bookings: $scope.bb.basket.items})

      prom.then  (purchase) ->
        purchase.getBookingsPromise().then (bookings) ->
          for booking in bookings
            # update bookings
            if $scope.bookings
              for oldb, _i in $scope.bookings
                if oldb.id == booking.id
                  $scope.bookings[_i] = booking
        $scope.setLoaded $scope
        $scope.bb.current_item.move_done = true
        $scope.decideNextPage()
      , (err) ->
        $scope.setLoaded $scope
        AlertService.add("danger", { msg: "Failed to move booking" })
      return

    $scope.notLoaded $scope
    $scope.updateBasket().then ->
      $scope.setLoaded $scope
      $scope.decideNextPage(route)
    , (err) -> $scope.setLoadedAndShowError($scope, err, 'Sorry, something went wrong')
