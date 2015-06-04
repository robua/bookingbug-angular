'use strict';


angular.module('BB.Directives').directive 'bbCheckout', () ->
  restrict: 'AE'
  replace: true
  scope : true
  controller : 'Checkout'


angular.module('BB.Controllers').controller 'Checkout', ($scope, $rootScope, BasketService, $q, $location, $window, $bbug, FormDataStoreService, $timeout) ->
  $scope.controller = "public.controllers.Checkout"
  $scope.notLoaded $scope

  # clear the form data store as we no longer need the data
  FormDataStoreService.destroy($scope)

  $rootScope.connection_started.then =>
    $scope.bb.basket.setClient($scope.client)
    loading_total_def = $q.defer()
    
    $scope.loadingTotal = BasketService.checkout($scope.bb.company, $scope.bb.basket, {bb: $scope.bb})
    $scope.loadingTotal.then (total) =>
      $scope.total = total
   
      if total.$has('new_payment')
        $scope.checkStepTitle('Review')
      else
        $scope.checkStepTitle('Confirmed')
        $scope.$emit("processDone")
      $scope.checkoutSuccess = true
      $scope.setLoaded $scope
      # currently just close the window and refresh the parent if we're in an admin popup
    , (err) =>
      $scope.setLoaded $scope
      $scope.checkoutFailed = true

  , (err) -> $scope.setLoadedAndShowError($scope, err, 'Sorry, something went wrong')

  # Deprecated - use window.print or $scope.printElement
  # Print booking details using print_purchase.html template
  $scope.print = () =>
    $window.open($scope.bb.partial_url+'print_purchase.html?id='+$scope.total.long_id,'_blank',
                'width=700,height=500,toolbar=0,menubar=0,location=0,status=1,scrollbars=1,resizable=1,left=0,top=0')
    return true


  # Print by creating popup containing the contents of the specified element
  $scope.printElement = (id, stylesheet) ->
    data = $bbug('#'+ id).html()
    # window.open(URL,name,specs,replace)
    # IE8 fix: URL and name params are deliberately left as blank
    # http://stackoverflow.com/questions/710756/ie8-var-w-window-open-message-invalid-argument
    mywindow = $window.open('', '', 'height=600,width=800')

    $timeout () ->
      mywindow.document.write '<html><head><title>Booking Confirmation</title>'

      mywindow.document.write('<link rel="stylesheet" href="' + stylesheet + '" type="text/css" />') if stylesheet
      mywindow.document.write '</head><body>'
      mywindow.document.write data
      mywindow.document.write '</body></html>'
      #mywindow.document.close()

      $timeout () ->
        mywindow.document.close()
        # necessary for IE >= 10
        mywindow.focus()
        # necessary for IE >= 10
        mywindow.print()
        mywindow.close()
      , 100
    , 2000
