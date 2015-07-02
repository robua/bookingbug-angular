'use strict'

angular.module('BB.Directives').directive 'bbTotal', () ->
  restrict: 'AE'
  replace: true
  scope : true
  controller : 'Total'

angular.module('BB.Controllers').controller 'Total', ($scope,  $rootScope, $q, $location, $window, PurchaseService, QueryStringService) ->

  $scope.controller = "public.controllers.Total"
  $scope.notLoaded $scope

  $rootScope.connection_started.then =>
    $scope.bb.payment_status = null

    id = if $scope.bb.total then $scope.bb.total.long_id else QueryStringService('purchase_id')

    if id
      PurchaseService.query({url_root: $scope.bb.api_url, purchase_id: id}).then (total) ->
        $scope.total = total
        $scope.setLoaded $scope

  , (err) ->
    $scope.setLoadedAndShowError($scope, err, 'Sorry, something went wrong')

  $scope.print = () =>
    $window.open($scope.bb.partial_url+'print_purchase.html?id='+$scope.total.long_id,'_blank',
                'width=700,height=500,toolbar=0,menubar=0,location=0,status=1,scrollbars=1,resizable=1,left=0,top=0')
    return true

