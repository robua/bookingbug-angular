angular.module('BBAdminBooking').directive 'bbAdminBooking', (AdminCompanyService,
  $log, $compile, $q, PathSvc, $templateCache, $http) ->

  getTemplate = (template) ->
    partial = if template then template else 'main'
    fromTemplateCache = $templateCache.get(partial)
    if fromTemplateCache
      fromTemplateCache
    else
      src = PathSvc.directivePartial(partial).$$unwrapTrustedValue()
      $http.get(src, {cache: $templateCache}).then (response) ->
        response.data

  renderTemplate = (scope, element, design_mode, template) ->
    $q.when(getTemplate(template)).then (template) ->
      element.html(template).show()
      element.append('<style widget_css scoped></style>') if design_mode
      $compile(element.contents())(scope)

  link = (scope, element, attrs) ->
    config = scope.$eval attrs.bbAdminBooking
    config ||= {}
    config.admin = true
    unless attrs.companyId
      if config.company_id
        attrs.companyId = config.company_id
      else if scope.company
        attrs.companyId = scope.company.id
    if attrs.companyId
      AdminCompanyService.query(attrs).then (company) ->
        scope.company = company
        # TODO persist admin comp with param (config.admin?) or scope check
        scope.initWidget(config)
        renderTemplate(scope, element, config.design_mode, config.template)

  {
    link: link
    controller: 'BBCtrl'
  }
