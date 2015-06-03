'use strict'

angular.module('BB.Directives').directive 'bbEvents', () ->
  restrict: 'AE'
  replace: true
  scope : true
  controller : 'EventList'

  link : (scope, element, attrs) ->
    scope.summary = attrs.summary?

    options = scope.$eval attrs.bbEvents or {}

    # set the mode
    # 0 = Event summary (gets year summary and loads events a day at a time)
    # 1 = Next 100 events (gets next 100 events)
    # 2 = Next 100 events and event summary (gets event summary, loads next 100 events, and gets more events if requested)
    scope.mode = if options and options.mode then options.mode else 0
    scope.mode = 0 if scope.summary
    return


angular.module('BB.Controllers').controller 'EventList', ($scope, $rootScope, EventService, EventChainService, $q, PageControllerService, FormDataStoreService, $filter, PaginationService) ->
  $scope.controller = "public.controllers.EventList"
  $scope.notLoaded $scope
  angular.extend(this, new PageControllerService($scope, $q))
  $scope.pick = {}
  $scope.start_date = moment()
  $scope.end_date = moment().add(1, 'year')
  $scope.filters = {}
  $scope.price_options = [0,1000,2500,5000]
  $scope.pagination = PaginationService.initialise({page_size: 10, max_size: 5})
  $scope.events = {}
  $scope.fully_booked = false

  FormDataStoreService.init 'EventList', $scope, [
    'selected_date',
    'event_group_id',
    'event_group_manually_set'
  ]
  
  $rootScope.connection_started.then ->
    if $scope.bb.company
      # if there's a default event, skip this step
      if $scope.bb.item_defaults.event
        $scope.skipThisStep()
        $scope.decideNextPage()
        return
      else if $scope.bb.company.$has('parent') && !$scope.bb.company.$has('company_questions')
        $scope.bb.company.getParentPromise().then (parent) ->
          $scope.company_parent = parent
          $scope.initialise()
        , (err) -> $scope.setLoadedAndShowError($scope, err, 'Sorry, something went wrong')
      else
        $scope.initialise()
      
  , (err) -> $scope.setLoadedAndShowError($scope, err, 'Sorry, something went wrong')
  

  $scope.initialise = () ->
    $scope.notLoaded $scope

    # has the event group been manually set (i.e. in the step before)
    $scope.event_group_manually_set = if !$scope.event_group_manually_set? and $scope.current_item.event_group? then true else false

    # clear event data unless in summary mode
    if $scope.current_item.event and $scope.mode != 0
      delete $scope.current_item.event
      delete $scope.current_item.event_chain
      delete $scope.current_item.event_group if !$scope.event_group_manually_set
      delete $scope.current_item.tickets

    promises = []

    # company question promise
    if $scope.bb.company.$has('company_questions')
      promises.push($scope.bb.company.getCompanyQuestionsPromise())
    else if $scope.company_parent? && $scope.company_parent.$has('company_questions')
      promises.push($scope.company_parent.getCompanyQuestionsPromise())
    else
      promises.push($q.when([]))
      $scope.has_company_questions = false

    # event group promise
    if !$scope.current_item.event_group
      promises.push($scope.bb.company.getEventGroupsPromise())
    else
      promises.push($q.when([]))

    # event summary promise
    if $scope.mode is 0 or $scope.mode is 2
      promises.push($scope.loadEventSummary())
    else
      promises.push($q.when([]))

    # event data promise
    if $scope.mode is 1 or $scope.mode is 2
      promises.push($scope.loadEventData()) 
    else
      promises.push($q.when([]))

    $q.all(promises).then (result) ->
      company_questions = result[0]
      event_groups      = result[1]
      event_summary     = result[2]
      event_data        = result[3]

      $scope.has_company_questions = company_questions? && company_questions.length > 0
      buildDynamicFilters(company_questions) if company_questions
      $scope.event_groups = _.indexBy(event_groups, 'id') if event_groups
      $scope.setLoaded $scope

    , (err) -> $scope.setLoadedAndShowError($scope, err, 'Sorry, something went wrong')


  $scope.loadEventSummary = () ->
    deferred = $q.defer()
    current_event = $scope.current_item.event

    comp = $scope.bb.company 
    params = {item: $scope.bb.current_item, start_date:$scope.start_date.toISODate(), end_date:$scope.end_date.toISODate()}
    params.event_chain_id = $scope.bb.item_defaults.event_chain if $scope.bb.item_defaults.event_chain

    EventService.summary(comp, params).then (items) ->

      if items and items.length > 0

        item_dates = []
        for item in items
          d = moment(item)
          item_dates.push({
            date   : d, 
            idate  : parseInt(d.format("YYYYDDDD")), 
            count  : 1, 
            spaces : 1,
          })

        $scope.item_dates = item_dates.sort (a,b) -> (a.idate - b.idate) 

        # TODO clear the selected date if the event group has changed (but only when event group has been explicity set)
        # if $scope.current_item? and $scope.current_item.event_group?
        #   if $scope.current_item.event_group.id != $scope.event_group_id
        #     $scope.showDay($scope.item_dates[0].date)
        #   $scope.event_group_id = $scope.current_item.event_group.id
        
        # if the selected date is within range of the dates loaded, show it, else show the first day loaded
        if $scope.mode is 0
          if ($scope.selected_date and ($scope.selected_date.isAfter($scope.item_dates[0].date) or $scope.selected_date.isSame($scope.item_dates[0].date)) and ($scope.selected_date.isBefore($scope.item_dates[$scope.item_dates.length-1].date) || $scope.selected_date.isSame($scope.item_dates[$scope.item_dates.length-1].date)))
            $scope.showDay($scope.selected_date)
          else
            $scope.showDay($scope.item_dates[0].date)

      deferred.resolve($scope.item_dates)

    , (err) -> deferred.reject()
    return deferred.promise
 


  $scope.loadEventChainData = (comp) ->
    deferred = $q.defer()

    if $scope.bb.item_defaults.event_chain
      deferred.resolve([])
    else
      $scope.notLoaded $scope
      comp ||= $scope.bb.company 

      params = {item: $scope.bb.current_item, start_date:$scope.start_date.toISODate(), end_date:$scope.end_date.toISODate()}

      EventChainService.query(comp, params).then (events) ->
        $scope.setLoaded $scope
        deferred.resolve($scope.items)
      , (err) ->  deferred.reject()

    return deferred.promise
    

  $scope.loadEventData = (comp) ->
    deferred = $q.defer()

    current_event = $scope.current_item.event

    $scope.notLoaded $scope
    comp ||= $scope.bb.company 

    params = {item: $scope.bb.current_item, start_date:$scope.start_date.toISODate(), end_date:$scope.end_date.toISODate()}
    params.event_chain_id = $scope.bb.item_defaults.event_chain if $scope.bb.item_defaults.event_chain


    chains = $scope.loadEventChainData(comp)

    EventService.query(comp, params).then (events) ->

      events = _.groupBy events, (event) -> event.date.toISODate()
      for key, value of events
        $scope.events[key] = value

      $scope.items = _.flatten(_.toArray($scope.events))
      
      chains.then () ->
        # get more event details
        for item in $scope.items
          item.prepEvent()
          # check if the current item already has the same event selected
          if $scope.mode is 0 and current_event and current_event.self == item.self 
            item.select() 
            $scope.event = item

        # only build item_dates if we're in 'next 100 event' mode
        if $scope.mode is 1
          item_dates = {}
          if items.length > 0
            for item in items
              item.getDuration()
              idate = parseInt(item.date.format("YYYYDDDD"))
              item.idate = idate
              if !item_dates[idate]
                item_dates[idate] = {date:item.date, idate: idate, count:0, spaces:0}
              item_dates[idate].count  += 1
              item_dates[idate].spaces += item.num_spaces
            $scope.item_dates = []
            for x,y of item_dates
              $scope.item_dates.push(y)
            $scope.item_dates = $scope.item_dates.sort (a,b) -> (a.idate - b.idate)
          else
            idate = parseInt($scope.start_date.format("YYYYDDDD"))
            $scope.item_dates = [{date:$scope.start_date, idate: idate, count:0, spaces:0}]

          # TODO clear the selected date if the event group has changed
          # if $scope.current_item? && $scope.current_item.event_group?
          #   if $scope.current_item.event_group.id != $scope.event_group_id
          #     $scope.showDay($scope.item_dates[0].date)
          #   $scope.event_group_id = $scope.current_item.event_group.id
          # if ($scope.selected_date && ($scope.selected_date.isAfter($scope.item_dates[0].date) || $scope.selected_date.isSame($scope.item_dates[0].date)) && ($scope.selected_date.isBefore($scope.item_dates[$scope.item_dates.length-1].date) || $scope.selected_date.isSame($scope.item_dates[$scope.item_dates.length-1].date)))
          #   $scope.showDay($scope.selected_date)
          # else
          #   $scope.showDay($scope.item_dates[0].date)

        # determine if all events are fully booked
        isFullyBooked()

        $scope.filtered_items = $scope.items

        # run the filters to ensure any default filters get applied
        $scope.filterChanged()

        # update the paging
        PaginationService.update($scope.pagination, $scope.filtered_items.length)

        $scope.setLoaded $scope
        deferred.resolve($scope.items)
      , (err) ->  deferred.reject()
    , (err) ->  deferred.reject()
    return deferred.promise


  isFullyBooked = () ->
    full_events = []
    for item in $scope.items
      full_events.push(item) if item.num_spaces == item.spaces_booked
    $scope.fully_booked = true if full_events.length == $scope.items.length


  $scope.showDay = (day) ->
    return if !day or (day and !day.data)

    $scope.selected_day.selected = false if $scope.selected_day

    date = day.date
    # unselect the event if it's not on the day being selected
    delete $scope.event if $scope.event and !$scope.selected_date.isSame(date, 'day')

    if $scope.mode is 0
      new_date = date
      $scope.start_date = moment(date)
      $scope.end_date = moment(date)
      $scope.loadEventData()
    else
      new_date = date if !date.isSame($scope.selected_date, 'day')

    if new_date
      $scope.selected_date = new_date
      $scope.filters.date  = new_date.toDate()
      $scope.selected_day = day
      $scope.selected_day.selected = true
    else
      delete $scope.selected_date
      delete $scope.filters.date

    $scope.filterChanged()

   
  $scope.$watch 'pick.date', (new_val, old_val) =>
    if new_val
      $scope.start_date = moment(new_val)
      $scope.end_date = moment(new_val)
      $scope.loadEventData()


  $scope.selectItem = (item, route) =>
    return false unless (item.getSpacesLeft() <= 0 && $scope.bb.company.settings.has_waitlists) || item.hasSpace()
    $scope.notLoaded $scope
    if $scope.$parent.$has_page_control
      $scope.event.unselect() if $scope.event
      $scope.event = item
      $scope.event.select()
      $scope.setLoaded $scope
      return false
    else
      $scope.bb.current_item.setEvent(item)
      $scope.bb.current_item.ready = false
      $q.all($scope.bb.current_item.promises).then () ->
        $scope.decideNextPage(route)
      , (err) ->  $scope.setLoadedAndShowError($scope, err, 'Sorry, something went wrong')
      return true


  $scope.setReady = () ->
    return false if !$scope.event 
    $scope.bb.current_item.setEvent($scope.event)
    return true


  $scope.filterEvents = (item) ->
    result = (item.date.isSame(moment($scope.filters.date), 'day') or !$scope.filters.date?) and
      (($scope.filters.event_group and item.service_id == $scope.filters.event_group.id) or !$scope.filters.event_group?) and 
      (($scope.filters.price? and (item.price_range.from <= $scope.filters.price)) or !$scope.filters.price?) and
      (($scope.filters.hide_sold_out_events and item.getSpacesLeft() != 0) or !$scope.filters.hide_sold_out_events) and
      filterEventsWithDynamicFilters(item)
    return result


  filterEventsWithDynamicFilters = (item) ->

    return true if !$scope.has_company_questions or !$scope.dynamic_filters

    result = true

    for type in $scope.dynamic_filters.question_types
      if type is 'check'
        for dynamic_filter in $scope.dynamic_filters['check']
          name = dynamic_filter.name.parameterise('_')
          filter = false
          if item.chain and item.chain.extra[name]
            for i in item.chain.extra[name]
              filter = ($scope.dynamic_filters.values[dynamic_filter.name] and i is $scope.dynamic_filters.values[dynamic_filter.name].name) or !$scope.dynamic_filters.values[dynamic_filter.name]?
              break if filter
          result = result and filter
      else
        for dynamic_filter in $scope.dynamic_filters[type]
          name = dynamic_filter.name.parameterise('_')
          filter = ($scope.dynamic_filters.values[dynamic_filter.name] and item.chain.extra[name] is $scope.dynamic_filters.values[dynamic_filter.name].name) or !$scope.dynamic_filters.values[dynamic_filter.name]?
          result = result and filter
    return result


  $scope.filterDateChanged = () ->
    $scope.filterChanged()
    $scope.showDay(moment($scope.filters.date))


  $scope.resetFilters = () ->
    $scope.filters = {}
    $scope.dynamic_filters.values = {} if $scope.has_company_questions
    $scope.filterChanged()


  # builds dynamic filters using company questions
  buildDynamicFilters = (questions) ->
    $scope.dynamic_filters                = _.groupBy(questions, 'question_type')
    $scope.dynamic_filters.question_types = _.uniq(_.pluck(questions, 'question_type'))
    $scope.dynamic_filters.values         = {}


  # TODO build price filter by determiniug price range, if range is large enough, display price filter
  # buildPriceFilter = () ->
  #   for item in items 


  sort = () ->
   # TODO allow sorting by price/date (default)


  $scope.filterChanged = () ->
    if $scope.items
      $scope.filtered_items = $filter('filter')($scope.items, $scope.filterEvents)
      $scope.pagination.num_items = $scope.filtered_items.length
      $scope.filter_active = $scope.filtered_items.length != $scope.items.length
      PaginationService.update($scope.pagination, $scope.filtered_items.length)


  $scope.pageChanged = () ->
    PaginationService.update($scope.pagination, $scope.filtered_items.length)
    $rootScope.$broadcast "page:changed"


  $scope.$on 'month_picker:month_changed', (event, month, last_month_shown) ->
    return if !$scope.items or $scope.mode is 0
    last_event = _.last($scope.items).date
    # if the last event is in the same month as the last one shown, get more events
    if last_month_shown.start_date.isSame(last_event, 'month')
      $scope.start_date = last_month_shown.start_date
      $scope.loadEventData()
