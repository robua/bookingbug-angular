'use strict'

queueapp = angular.module('BBQueue', [
  'BB',
  'BBAdmin.Services',
  'BBAdmin.Directives',
  'BBQueue.Services',
  'BBQueue.Directives',
  'BBQueue.Controllers',
  'trNgGrid',
  'ngDragDrop',
  'pusher-angular'
])

angular.module('BBQueue.Directives', [
  'timer'
])

angular.module('BBQueue.Controllers', [])

angular.module('BBQueue.Services', [
  'ngResource',
  'ngSanitize',
  'ngLocalData'
])


angular.module('BBQueueMockE2E', ['BBQueue', 'BBAdminMockE2E'])


queueapp.run ($rootScope, $log, DebugUtilsService, FormDataStoreService, $bbug, $document, $sessionStorage, AppConfig, AdminLoginService) ->

  # AdminLoginService.checkLogin()
  # if $rootScope.user && $rootScope.user.company_id
  #   $rootScope.bb ||= {}
  #   $rootScope.bb.company_id = $rootScope.user.company_id
