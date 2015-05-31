'use strict';

angular.module('BB.Directives').directive 'bbTimes', () ->
  restrict: 'AE'
  replace: true
  scope : true
  controller : 'TimeList'

angular.module('BB.Controllers').controller 'TimeList', ($attrs, $element, $scope,  $rootScope, $q, TimeService, AlertService, BBModel) ->
  $scope.controller = "public.controllers.TimeList"
  $scope.notLoaded $scope

  $scope.data_source = $scope.bb.current_item if !$scope.data_source
  $scope.options = $scope.$eval($attrs.bbTimes) or {}

  $rootScope.connection_started.then =>
    $scope.loadDay()
  , (err) ->  $scope.setLoadedAndShowError($scope, err, 'Sorry, something went wrong')


  # set a date
  $scope.setDate = (date) =>
    day = new BBModel.Day({date: date, spaces: 1})
    $scope.setDay(day)


  # set based on a day model
  $scope.setDay = (dayItem) =>
    $scope.selected_day  = dayItem
    $scope.selected_date = dayItem.date


  $scope.setDataSource = (source) =>
    $scope.data_source = source


  $scope.setItemLinkSource = (source) =>
    $scope.item_link_source = source


  $scope.$on 'dateChanged', (event, newdate) =>
    $scope.setDate(newdate)
    $scope.loadDay()


  # when the current item is updated, reload the time data
  $scope.$on "currentItemUpdate", (event) ->
    $scope.loadDay()


  # format data source date
  # This method is deprecated, use datetime filter instead, e.g. moment() | datetime:'dd/mm/yy'
  $scope.format_date = (fmt) =>
    if $scope.data_source.date
      return $scope.data_source.date.date.format(fmt)


  $scope.selectSlot = (slot, route) =>
    if slot && slot.availability() > 0
      # if this time cal was also for a specific item source (i.e.a person or resoure- make sure we've selected it)
      if $scope.item_link_source
        $scope.data_source.setItem($scope.item_link_source)
      if $scope.selected_day
        $scope.setLastSelectedDate($scope.selected_day.date)
        $scope.data_source.setDate($scope.selected_day)
      $scope.data_source.setTime(slot)
      if $scope.$parent.$has_page_control
        return
      else
        if $scope.data_source.ready
          $scope.addItemToBasket().then () =>
            $scope.decideNextPage(route)
        else
          $scope.decideNextPage(route)


  $scope.highlightSlot = (slot) =>
    if slot && slot.availability() > 0
      if $scope.selected_day
        $scope.setLastSelectedDate($scope.selected_day.date)
        $scope.data_source.setDate($scope.selected_day)
      $scope.data_source.setTime(slot)
      # tell any accordian groups to update
      $scope.$broadcast 'slotChanged'


  # check the status of the slot to see if it has been selected
  $scope.status = (slot) ->
    return if !slot
    status = slot.status()
    return status


  # add unit of time to the selected day
  # deprecated, use bbDate directive instead
  $scope.add = (type, amount) =>
    newdate = moment($scope.data_source.date.date).add(amount, type)
    $scope.data_source.setDate(new BBModel.Day({date: newdate.format(), spaces: 0}))
    $scope.setLastSelectedDate(newdate)
    $scope.loadDay()
    $scope.$broadcast('dateChanged', newdate)


  # subtract unit of time to the selected day
  # deprecated, use bbDate directive instead
  $scope.subtract = (type, amount) =>
    $scope.add(type, -amount)


  $scope.loadDay = () =>

    if $scope.data_source && $scope.data_source.days_link  || $scope.item_link_source
      if !$scope.selected_date && $scope.data_source && $scope.data_source.date
        $scope.selected_date = $scope.data_source.date.date

      if !$scope.selected_date
        $scope.setLoaded $scope
        return

      $scope.notLoaded $scope
      pslots = TimeService.query({company: $scope.bb.company, cItem: $scope.data_source, item_link: $scope.item_link_source, date: $scope.selected_date, client: $scope.client, available: 1 })
      
      pslots.finally =>
        $scope.setLoaded $scope
      pslots.then (data) =>

        $scope.slots = data
        $scope.$broadcast('slotsUpdated')
        # padding is used to ensure that a list of time slots is always padded out with a certain of values, if it's a partial set of results
        if $scope.add_padding && data.length > 0
          dtimes = {}
          for s in data
            dtimes[s.time] = 1

          for pad, v in $scope.add_padding
            if (!dtimes[pad])
              data.splice(v, 0, new BBModel.TimeSlot({time: pad, avail: 0}, data[0].service))
        
        if ($scope.data_source.requested_time || $scope.data_source.time) && $scope.selected_date.isSame($scope.data_source.date.date)
          found_time = false
          for t in data
            if (t.time == $scope.data_source.requested_time)
              $scope.data_source.requestedTimeUnavailable()
              $scope.selectSlot(t)
              found_time = true
            if ($scope.data_source.time && t.time == $scope.data_source.time.time )
              $scope.data_source.setTime(t)
              found_time = true
          if !found_time
            # if we didn't find the time - give up and do force it's selecttion
            $scope.data_source.requestedTimeUnavailable() if !$scope.options.persist_requested_time
            $scope.time_not_found = true
            AlertService.add("danger", { msg: "Sorry, your requested time slot is not available. Please choose a different time." })
      , (err) ->  $scope.setLoadedAndShowError($scope, err, 'Sorry, something went wrong')

    else
      $scope.setLoaded $scope


  $scope.padTimes = (times) =>
    $scope.add_padding = times


  $scope.setReady = () =>
    if !$scope.data_source.time
      AlertService.clear()
      AlertService.add("danger", { msg: "You need to select a time slot" })
      return false
    else
      if $scope.data_source.ready
        return $scope.addItemToBasket()
      else
        return true



angular.module('BB.Directives').directive 'bbAccordianGroup', () ->
  restrict: 'AE'
  scope : true
  controller : 'AccordianGroup'


angular.module('BB.Controllers').controller 'AccordianGroup', ($scope,  $rootScope, $q) ->
  $scope.accordian_slots             = []
  $scope.is_open                     = false
  $scope.has_availability            = false
  $scope.is_selected                 = false
  $scope.collaspe_when_time_selected = true
  $scope.start_time                  = 0
  $scope.end_time                    = 0

  $scope.init = (start_time, end_time, options) =>

    $scope.start_time = start_time
    $scope.end_time   = end_time
    $scope.collaspe_when_time_selected = if options && !options.collaspe_when_time_selected then false else true

    for slot in $scope.slots
      $scope.accordian_slots.push(slot) if slot.time >= start_time && slot.time < end_time

    updateAvailability()


  updateAvailability = () =>
    $scope.has_availability = false

    if $scope.accordian_slots

      $scope.has_availability = hasAvailability()

      # does the BasketItem's selected time reside in the accordian group?
      item = $scope.data_source
      if item.time && item.time.time >= $scope.start_time && item.time.time < $scope.end_time && (item.date && item.date.date.isSame($scope.selected_day.date, 'day'))
        $scope.is_selected = true
        $scope.is_open = true unless $scope.collaspe_when_time_selected
      else
        $scope.is_selected = false
        $scope.is_open = false


  hasAvailability = () =>
    return false if !$scope.accordian_slots
    for slot in $scope.accordian_slots
      return true if slot.availability() > 0
    return false


  $scope.$on 'slotChanged', (event) =>
    updateAvailability()


  $scope.$on 'slotsUpdated', (event) =>
    $scope.accordian_slots = []
    for slot in $scope.slots
      $scope.accordian_slots.push(slot) if slot.time >= $scope.start_time && slot.time < $scope.end_time
    updateAvailability()
