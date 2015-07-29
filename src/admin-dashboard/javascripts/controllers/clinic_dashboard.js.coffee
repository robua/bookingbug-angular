angular.module('BBAdminDashboard').controller 'bbClinicDashboardController', ($scope, $log,
    AdminServiceService, AdminResourceService, AdminPersonService, ModalForm, BBModel, $interval, $sessionStorage) ->

  $scope.loading = true

  $scope.getClinicSetup = () ->
    console.log "setup"
    params =
      company: $scope.company
    AdminServiceService.query(params).then (services) ->
      $scope.services = services
    , (err) ->
      $log.error err.data

    AdminResourceService.query(params).then (resources) ->
      $scope.resources = resources
    , (err) ->
      $log.error err.data

    AdminPersonService.query(params).then (people) ->
      $scope.people = people
    , (err) ->
      $log.error err.data
