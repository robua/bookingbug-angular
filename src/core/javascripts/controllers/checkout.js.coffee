'use strict';


###**
* @ngdoc directive
* @name BB.Directives:bbCheckout
* @restrict AE
* @scope true
*
* @description
* Loads a list of checkouts for the currently in scope company
*
* <pre>
* restrict: 'AE'
* replace: true
* scope: true
* </pre>
*
* @param {hash}  bbCheckout   A hash of options
* @property {string} loadingTotal The loading total
* @property {string} skipThisStep The skip this step
* @property {string} decideNextPage The decide next page
* @property {boolean} checkoutSuccess The checkout success
* @property {string} setLoaded The set loaded
* @property {string} setLoadedAndShowError The set loaded and show error
* @property {boolean} checkoutFailed The checkout failed
####


angular.module('BB.Directives').directive 'bbCheckout', () ->
  restrict: 'AE'
  replace: true
  scope : true
  controller : 'Checkout'


angular.module('BB.Controllers').controller 'Checkout', ($scope, $rootScope, $attrs, BasketService, $q, $location, $window, $bbug, FormDataStoreService, $timeout) ->
  $scope.controller = "public.controllers.Checkout"
  $scope.notLoaded $scope

  $scope.options = $scope.$eval($attrs.bbCheckout) or {}

  # clear the form data store as we no longer need the data
  FormDataStoreService.destroy($scope)

  $rootScope.connection_started.then =>
    $scope.bb.basket.setClient($scope.client)
    $scope.bb.no_notifications = $scope.options.no_notifications if $scope.options.no_notifications
    $scope.loadingTotal = BasketService.checkout($scope.bb.company, $scope.bb.basket, {bb: $scope.bb})
    $scope.loadingTotal.then (total) =>
      $scope.total = total
   
      # if no payment is required, route to the next step unless instructed otherwise
      if !total.$has('new_payment')
        $scope.$emit("checkout:success", total)
        $scope.bb.total = $scope.total
        $scope.bb.payment_status = 'complete'
        if !$scope.options.disable_confirmation
          $scope.skipThisStep()
          $scope.decideNextPage()

      $scope.checkoutSuccess = true
      $scope.setLoaded $scope
      # currently just close the window and refresh the parent if we're in an admin popup
    , (err) ->
      $scope.setLoadedAndShowError($scope, err, 'Sorry, something went wrong')
      $scope.checkoutFailed = true
      $scope.$emit("checkout:fail", err)

  , (err) -> $scope.setLoadedAndShowError($scope, err, 'Sorry, something went wrong')

  # Deprecated - use window.print or $scope.printElement
  # Print booking details using print_purchase.html template
  $scope.print = () =>
    $window.open($scope.bb.partial_url+'print_purchase.html?id='+$scope.total.long_id,'_blank',
                'width=700,height=500,toolbar=0,menubar=0,location=0,status=1,scrollbars=1,resizable=1,left=0,top=0')
    return true

   ###**
  * @ngdoc method
  * @name printElement
  * @methodOf BB.Directives:bbCheckout
  * @description
  * Print by creating popup containing the contents of the specified element
  *
  * @param {integer} id The id of the specified element
  * @param {string} stylesheet The stylesheet of popup
  ###
  # Print by creating popup containing the contents of the specified element
  # TODO move print methods to a service
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
