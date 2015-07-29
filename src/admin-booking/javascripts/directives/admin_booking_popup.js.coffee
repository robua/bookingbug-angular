angular.module('BBAdminBooking').directive 'bbAdminBookingPopup', (AdminBookingPopup) ->

  controller = ($scope) ->

    $scope.open = () ->
      AdminBookingPopup.open()

  link = (scope, element, attrs) ->
    element.bind 'click', () ->
      scope.open()

  {
    link: link
    controller: controller
  }
