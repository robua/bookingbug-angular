angular.module('BBAdminServices').directive 'serviceTable', (AdminCompanyService,
    AdminServiceService, $modal, $log, ModalForm) ->

  controller = ($scope) ->
    $scope.fields = ['id', 'name']
    $scope.getServices = () ->
      params =
        company: $scope.company
      AdminServiceService.query(params).then (services) ->
        $scope.services = services

    $scope.newService = () ->
      ModalForm.new
        company: $scope.company
        title: 'New Service'
        new_rel: 'new_service'
        post_rel: 'services'
        success: (service) ->
          $scope.services.push(service)

    $scope.delete = (service) ->
      service.$del('self').then () ->
        $scope.services = _.reject $scope.services, service
      , (err) ->
        $log.error "Failed to delete service"

    $scope.edit = (service) ->
      ModalForm.edit
        model: service
        title: 'Edit Service'

  link = (scope, element, attrs) ->
    if scope.company
      scope.getServices()
    else
      AdminCompanyService.query(attrs).then (company) ->
        scope.company = company
        scope.getServices()

  {
    controller: controller
    link: link
    templateUrl: 'service_table_main.html'
  }
