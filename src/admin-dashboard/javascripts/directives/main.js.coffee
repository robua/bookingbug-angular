



angular.module('BBAdminDashboard').directive 'bbIfLogin', ($modal, $log, $q,
  $rootScope, AdminCompanyService, $compile, $templateCache,
  ModalForm, BBModel) ->

  compile = () ->
    {
      pre: ( scope, element, attributes ) ->
        scope.notLoaded = (sc) ->
          null
        scope.setLoaded = (sc) ->
          null
        scope.setPageLoaded = () ->
          null

        $rootScope.start_deferred = $q.defer()
        $rootScope.connection_started  = $rootScope.start_deferred.promise
        @whenready = $q.defer()
        scope.loggedin = @whenready.promise
        AdminCompanyService.query(attributes).then (company) ->
          scope.company = company
          scope.bb ||= {}
          scope.bb.company = company
          @whenready.resolve()
          $rootScope.start_deferred.resolve()
      ,
      post: ( scope, element, attributes ) ->
    }

  link = (scope, element, attrs) ->
  {
    compile: compile
#    controller: 'bbQueuers'
    # templateUrl: 'queuer_table.html'
  }
