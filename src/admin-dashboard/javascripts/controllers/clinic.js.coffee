angular.module('BBAdminDashboard').controller 'bbClinicController', ($scope, $log,
    AdminServiceService, AdminResourceService, AdminPersonService, ModalForm, BBModel, $interval, $sessionStorage) ->

  $scope.loading = true

  $scope.clinic ||= new BBModel.Admin.Clinic()

  $scope.getClinicItemSetup = () ->
    console.log "setup"