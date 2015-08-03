'use strict';

angular.module('BB.Directives').directive 'bbServices', () ->
  restrict: 'AE'
  replace: true
  scope : true
  controller : 'ServiceList'

angular.module('BB.Controllers').controller 'ServiceList',($scope, $rootScope, $q, $attrs, $modal, $sce, ItemService, FormDataStoreService, ValidatorService, PageControllerService, halClient, AlertService, ErrorService, $filter, CategoryService) ->

  $scope.controller = "public.controllers.ServiceList"

  FormDataStoreService.init 'ServiceList', $scope, [
    'service'
  ]

  $scope.notLoaded $scope

  angular.extend(this, new PageControllerService($scope, $q))

  $scope.validator = ValidatorService

  $scope.filters = {category_name: null, service_name: null, price: { min: 0, max: 100}, custom_array_value: null}
  $scope.show_custom_array = false

  $scope.options = $scope.$eval($attrs.bbServices) or {}

  $scope.booking_item = $scope.$eval($attrs.bbItem) if $attrs.bbItem
  $scope.show_all = true if $attrs.bbShowAll or $scope.options.show_all 
  $scope.allowSinglePick = true if $scope.options.allow_single_pick
  $scope.price_options = {min: 0, max: 100}

  $rootScope.connection_started.then () =>
    if $scope.bb.company
      $scope.init($scope.bb.company)
  , (err) -> $scope.setLoadedAndShowError($scope, err, 'Sorry, something went wrong')


  $scope.init = (comp) ->
    $scope.booking_item ||= $scope.bb.current_item

    if $scope.bb.company.$has('named_categories')
      CategoryService.query($scope.bb.company).then (items) =>
        $scope.all_categories = items
      , (err) ->  $scope.all_categories = []
    else
      $scope.all_categories = []

    # check any curretn service is valid for the current company
    if $scope.service && $scope.service.company_id != $scope.bb.company.id
      $scope.service = null

    ppromise = comp.getServicesPromise()
    @skipped = false
    ppromise.then (items) =>
      # not all service lists need filtering. check for attribute first
      filterItems = if $attrs.filterServices is 'false' then false else true

      if filterItems
        if $scope.booking_item.service_ref && !$scope.show_all
          items = items.filter (x) -> x.api_ref is $scope.booking_item.service_ref
        else if $scope.booking_item.category && !$scope.show_all
          # if we've selected a category for the current item - limit the list
          # of services to ones that are relevant
          items = items.filter (x) -> x.$has('category') && x.$href('category') is $scope.booking_item.category.self

      # filter out event groups unless explicity requested
      if !$scope.options.show_event_groups
        items = items.filter (x) -> !x.is_event_group 

      # if there's only one service and single pick hasn't been enabled, 
      # automatically select the service.
      if (items.length is 1 && !$scope.allowSinglePick)
        if !$scope.selectItem(items[0], $scope.nextRoute )
          setServiceItem items
        else if !@skipped
          $scope.skipThisStep()
          @skipped = true          
      else
        setServiceItem items

      # if there's a default - pick it and move on
      if $scope.booking_item.defaultService()
        for item in items
          if item.self == $scope.booking_item.defaultService().self or (item.name is $scope.booking_item.defaultService().name and !item.deleted)
            $scope.selectItem(item, $scope.nextRoute)

      # if there's one selected - just select it
      if $scope.booking_item.service
        for item in items
          item.selected = false
          if item.self is $scope.booking_item.service.self
            $scope.service = item
            item.selected = true
            $scope.booking_item.setService($scope.service)

      $scope.setLoaded $scope

      if $scope.booking_item.service || !(($scope.booking_item.person && !$scope.booking_item.anyPerson()) || ($scope.booking_item.resource && !$scope.booking_item.anyResource()))
        # the "bookable services" are the service unless we've pre-selected something!
        $scope.bookable_services = $scope.items
    , (err) -> $scope.setLoadedAndShowError($scope, err, 'Sorry, something went wrong')

    if ($scope.booking_item.person && !$scope.booking_item.anyPerson()) ||
       ($scope.booking_item.resource && !$scope.booking_item.anyResource())

      # if we've already picked a service or a resource - get a more limited service selection
      ItemService.query({company: $scope.bb.company, cItem: $scope.booking_item, wait: ppromise, item: 'service'}).then (items) =>
        if $scope.booking_item.service_ref
          items = items.filter (x) -> x.api_ref == $scope.booking_item.service_ref
        if $scope.booking_item.group
          items = items.filter (x) -> !x.group_id || x.group_id == $scope.booking_item.group
        services = (i.item for i in items when i.item?)
        
        $scope.bookable_services = services
        $scope.bookable_items = items
        
        if services.length is 1 and !$scope.allowSinglePick
          if !$scope.selectItem(services[0], $scope.nextRoute )
            setServiceItem services
          else if !@skipped
            $scope.skipThisStep()
            @skipped = true  
        else
          setServiceItem items
        
        $scope.setLoaded($scope)
      , (err) ->  
        $scope.setLoadedAndShowError($scope, err, 'Sorry, something went wrong')
  
  # set the service item so the correct item is displayed in the dropdown menu.
  # without doing this the menu will default to 'please select'
  setServiceItem = (items) ->
    $scope.items = items
    $scope.filtered_items = $scope.items
    if $scope.service
        _.each items, (item) ->
          if item.id is $scope.service.id
            $scope.service = item

  $scope.selectItem = (item, route) =>
    if $scope.routed
      return true

    if $scope.$parent.$has_page_control
      $scope.service = item
      return false
    else if item.is_event_group
      $scope.booking_item.setEventGroup(item)
      $scope.decideNextPage(route)
      $scope.routed = true
    else
      $scope.booking_item.setService(item)
      $scope.decideNextPage(route)
      $scope.routed = true
      return true

  $scope.$watch 'service', (newval, oldval) =>
    if $scope.service && $scope.booking_item
      if !$scope.booking_item.service or $scope.booking_item.service.self isnt $scope.service.self
        # only set and broadcast if it's changed
        $scope.booking_item.setService($scope.service)
        $scope.broadcastItemUpdate()


  $scope.setReady = () =>
    if $scope.service
      $scope.booking_item.setService($scope.service)
      return true
    else if $scope.bb.stacked_items and $scope.bb.stacked_items.length > 0
      return true
    else
      return false

  $scope.errorModal = () ->
    error_modal = $modal.open
      templateUrl: $scope.getPartial('_error_modal')
      controller: ($scope, $modalInstance) ->
        $scope.message = ErrorService.getError('GENERIC').msg
        $scope.ok = () ->
          $modalInstance.close()

  $scope.filterFunction = (service) ->
    if !service
      return false
    $scope.service_array = [] 
    $scope.custom_array = (match)->
      if !match
        return false
      if $scope.options.custom_filter
        match = match.toLowerCase()
        for item in service.extra[$scope.options.custom_filter]
          item = item.toLowerCase()
          if item is match
            $scope.show_custom_array = true
            return true 
        return false
    $scope.service_name_include = (match) ->
      if !match
        return false
      if match 
        match = match.toLowerCase()
        item = service.name.toLowerCase()
        if item.includes(match)
          return true
        else
          false
    return (!$scope.filters.category_name or service.category_id is $scope.filters.category_name.id) and
      (!$scope.filters.service_name or $scope.service_name_include($scope.filters.service_name)) and
      (!$scope.filters.custom_array_value or $scope.custom_array($scope.filters.custom_array_value)) and
      (!service.price or (service.price >= $scope.filters.price.min * 100 and service.price <= $scope.filters.price.max * 100 ))

  $scope.resetFilters = () ->
    if $scope.options.clear_results
      $scope.show_custom_array = false
    $scope.filters.category_name = null
    $scope.filters.service_name = null
    $scope.filters.price.min = 0
    $scope.filters.price.max = 100
    $scope.filters.custom_array_value = null
    $scope.filterChanged()

  $scope.filterChanged = () ->
    $scope.filtered_items = $filter('filter')($scope.items, $scope.filterFunction);



