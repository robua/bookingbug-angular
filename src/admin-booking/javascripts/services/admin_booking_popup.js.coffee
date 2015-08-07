angular.module('BBAdminBooking').factory 'AdminBookingPopup', ($modal, $timeout) ->

  open: (config) ->
    $modal.open
      size: if config then config.size else 'lg'
      controller: ($scope, $modalInstance, config) ->
        if $scope.bb && $scope.bb.current_item 
          delete $scope.bb.current_item
        $scope.config = angular.extend
          clear_member: true
          template: 'main'
        , config
        $scope.config.company_id ||= $scope.company.id if $scope.company
        $scope.config.item_defaults = angular.extend 
          merge_resources: true
          merge_people: false
        , config.item_defaults
        console.log $scope.config
        $scope.cancel = () ->
          $modalInstance.dismiss('cancel')
      templateUrl: 'admin_booking_popup.html'
      resolve:
        config: () -> config
