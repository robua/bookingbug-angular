angular.module('BBAdminBooking').factory 'AdminBookingPopup', ($modal, $timeout) ->

 open: (config) ->
   $modal.open
     controller: ($scope, $modalInstance, config) ->
       $scope.config = angular.extend
         company_id: $scope.company.id
         item_defaults:
           merge_resources: true
           merge_people: true
         clear_member: true
         template: 'main'
       , config
       $scope.cancel = () ->
         $modalInstance.dismiss('cancel')
     templateUrl: 'admin_booking_popup.html'
     scope: $scope
     resolve:
       config: () -> config