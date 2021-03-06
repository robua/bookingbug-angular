'use strict'


###**
* @ngdoc directive
* @name BB.Directives:bbTimeSlots
* @restrict AE
* @scope true
*
* @description
*
* Loads a list of time slots for the currently in scope company
*
* <pre>
* restrict: 'AE'
* replace: true
* scope: true
* </pre>
*
* @property {array} booking_item The booking item 
* @property {date} start_date The start date
* @property {date} end_date The end date
* @property {array} slots The slots
* @property {object} validator The validator service - see {@link BB.Services:Validator validator Service}
* 
####


angular.module('BB.Directives').directive 'bbTimeSlots', () ->
  restrict: 'AE'
  replace: true
  scope : true
  controller : 'TimeSlots'
  link : (scope, element, attrs) ->
    if attrs.bbItem
      scope.booking_item = scope.$eval( attrs.bbItem )
    if attrs.bbShowAll
      scope.show_all = true
    return

angular.module('BB.Controllers').controller 'TimeSlots', ($scope,
    $rootScope, $q, $attrs, SlotService, FormDataStoreService, ValidatorService,
    PageControllerService, halClient, BBModel) ->

  $scope.controller = "public.controllers.SlotList"

  $scope.notLoaded $scope
  $rootScope.connection_started.then ->
    if $scope.bb.company
      $scope.init($scope.bb.company)
  , (err) ->
    $scope.setLoadedAndShowError($scope, err, 'Sorry, something went wrong')

  $scope.init = (company) ->
    $scope.booking_item ||= $scope.bb.current_item
    $scope.start_date = moment()
    $scope.end_date = moment().add(1, 'month')

    SlotService.query($scope.bb.company, {item: $scope.booking_item,  start_date:$scope.start_date.toISODate(), end_date:$scope.end_date.toISODate()}).then (slots) ->
      $scope.slots = slots
      $scope.setLoaded $scope
    , (err) ->
      $scope.setLoadedAndShowError($scope, err, 'Sorry, something went wrong')

  setItem = (slot) ->
    $scope.booking_item.setSlot(slot)

  ###**
  * @ngdoc method
  * @name selectItem
  * @methodOf BB.Directives:bbTimeSlots
  * @description
  * Select an item into the current booking journey and route on to the next page dpending on the current page control
  *
  * @param {object} slot The slot from list
  * @param {string=} route A specific route to load
  ###
  $scope.selectItem = (slot, route) ->
    if $scope.$parent.$has_page_control
      setItem(slot)
      false
    else
      setItem(slot)
      $scope.decideNextPage(route)
      true

