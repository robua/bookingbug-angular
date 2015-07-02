'use strict';

adminbookingapp = angular.module('BBAdminBooking', [
  'BB',
  'BBAdmin.Services',
  'trNgGrid'
])

angular.module('BBAdminBooking').config ($logProvider) ->
  $logProvider.debugEnabled(true)

angular.module('BBAdminBooking.Directives', [])

angular.module('BBAdminBooking.Services', [
  'ngResource',
  'ngSanitize'
  'ngLocalData'
])

angular.module('BBAdminBooking.Controllers', [
  'ngLocalData',
  'ngSanitize'
])

adminbookingapp.run ($rootScope, $log, DebugUtilsService, FormDataStoreService, $bbug, $document, $sessionStorage, AppConfig, AdminLoginService) ->

  AdminLoginService.checkLogin().then () ->
    if $rootScope.user && $rootScope.user.company_id
      $rootScope.bb ||= {}
      $rootScope.bb.company_id = $rootScope.user.company_id
