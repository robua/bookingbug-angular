'use strict'

angular.module('BB.Directives').directive 'bbDeals', () ->
  restrict: 'AE'
  replace: true
  scope : true
  controller : 'DealList'

angular.module('BB.Controllers').controller 'DealList', ($scope, $rootScope, DealService, $q, BBModel, AlertService, FormDataStoreService, ValidatorService, $modal) ->

  $scope.controller = "public.controllers.DealList"
  FormDataStoreService.init 'TimeRangeList', $scope, [ 'deals' ]

  $rootScope.connection_started.then ->
    init()
  , (err) ->  $scope.setLoadedAndShowError($scope, err, 'Sorry, something went wrong')

  init = () ->
    $scope.notLoaded $scope
    if !$scope.deals
      deal_promise = DealService.query($scope.bb.company)
      deal_promise.then (deals) ->
        $scope.deals = deals
        $scope.setLoaded $scope


  $scope.selectDeal = (deal) ->
    iitem = new (BBModel.BasketItem)(null, $scope.bb)
    iitem.setDefaults $scope.bb.item_defaults
    iitem.setDeal deal
    if !$scope.bb.company_settings.no_recipient
      modalInstance = $modal.open
        templateUrl: $scope.getPartial('_add_recipient')
        scope: $scope
        controller: ModalInstanceCtrl
        resolve:
          item: ->
            iitem

      modalInstance.result.then (item) ->
        $scope.notLoaded $scope
        $scope.setBasketItem item
        $scope.addItemToBasket().then ->
          $scope.setLoaded $scope
        , (err) ->
          $scope.setLoadedAndShowError $scope, err, 'Sorry, something went wrong'
    else
      $scope.notLoaded $scope
      $scope.setBasketItem iitem
      $scope.addItemToBasket().then ->
        $scope.setLoaded $scope
      , (err) ->
        $scope.setLoadedAndShowError $scope, err, 'Sorry, something went wrong'

  ModalInstanceCtrl = ($scope, $modalInstance, item, ValidatorService) ->
    $scope.controller = 'ModalInstanceCtrl'
    $scope.item = item
    $scope.recipient = false

    $scope.addToBasket = (form) ->
      if !ValidatorService.validateForm(form)
        return
      $modalInstance.close($scope.item)

    $scope.cancel = ->
      $modalInstance.dismiss 'cancel'

  $scope.purchaseDeals = ->
    if $scope.bb.basket.items and $scope.bb.basket.items.length > 0
      $scope.decideNextPage()
    else
      AlertService.add('danger', msg: 'You need to select at least one Gift Certificate to continue')

  $scope.setReady = ->
    if $scope.bb.basket.items and $scope.bb.basket.items.length > 0
      true
    else
      AlertService.add('danger', msg: 'You need to select at least one Gift Certificate to continue')