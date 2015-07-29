


angular.module('BBAdminDashboard').directive 'bbClinicDashboard', ($modal, $log,
  $rootScope, $compile, $templateCache, ModalForm, BBModel) ->

  link = (scope, element, attrs) ->
    scope.loggedin.then () ->
      scope.getClinicSetup()

  {
    link: link
    controller: 'bbClinicDashboardController'
  }


angular.module('BBAdminDashboard').directive 'bbClinicCal', ($modal, $log,
  $rootScope, $compile, $templateCache, ModalForm, BBModel) ->

  link = (scope, element, attrs) ->
    scope.loggedin.then () ->
      scope.getClinicCalSetup()

  {
    link: link
    controller: 'bbClinicCalController'
  }


angular.module('BBAdminDashboard').directive 'bbClinic', ($modal, $log,
  $rootScope, $compile, $templateCache, ModalForm, BBModel) ->

  link = (scope, element, attrs) ->
    scope.loggedin.then () ->
      scope.getClinicItemSetup()

  {
    link: link
    controller: 'bbClinicController'
  }
