angular.module('BBQueue').directive 'bbAdminQueueTable', ($modal, $log,
  $rootScope, AdminQueueService, AdminCompanyService, $compile, $templateCache,
  ModalForm, BBModel) ->

  link = (scope, element, attrs) ->
    scope.fields ||= ['ticket_number', 'first_name', 'last_name', 'email']
    if scope.company
      scope.getQueuers()
    else
      AdminCompanyService.query(attrs).then (company) ->
        scope.company = company
        scope.getQueuers()

  {
    link: link
    controller: 'bbQueuers'
    templateUrl: 'queuer_table.html'
  }
