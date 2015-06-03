angular.module('BB.Directives').directive 'paymentButton', ($compile, $sce,
    $http, $templateCache, $q, $log) ->

  getTemplate = (type, scope) ->
    switch type
      when 'button_form'
        getButtonFormTemplate(scope)
      when 'page'
        """<a ng-click="decideNextPage()">{{label}}</a>"""
      when 'location'
        """<a href='{{payment_link}}'>{{label}}</a>"""
      else ""

  getButtonFormTemplate = (scope) ->
    src = $sce.parseAsResourceUrl("'"+scope.payment_link+"'")()
    $http.get(src, {}).then (response) ->
      return response.data

  setClassAndValue = (scope, element, attributes) ->
    switch scope.link_type
      when 'button_form'
        inputs = element.find("input")
        main_tag = (i for i in inputs when $(i).attr('type') == 'submit')[0]
        $(main_tag).attr('value', attributes.value) if attributes.value
      when 'page', 'location'
        main_tag = element.find("a")[0]
    if attributes.class
      for c in attributes.class.split(" ")
        $(main_tag).addClass(c)
        $(element).removeClass(c)

  linker = (scope, element, attributes) ->
    scope.$watch 'total', () ->
      scope.bb.payment_status = "pending"
      scope.bb.total = scope.total
      scope.link_type = scope.total.$link('new_payment').type
      scope.label = attributes.value || "Make Payment"
      scope.payment_link = scope.total.$href('new_payment')
      url = scope.total.$href('new_payment')
      $q.when(getTemplate(scope.link_type, scope)).then (template) ->
        element.html(template).show()
        $compile(element.contents())(scope)
        setClassAndValue(scope, element, attributes)
      , (err) ->
        $log.warn err.data
        element.remove()

  return {
    restrict: 'EA'
    replace: true
    scope: {
      total: '='
      bb: '='
      decideNextPage: '='
    }
    link: linker
  }

angular.module('BB.Directives').directive 'bbPaypalExpressButton', ($compile, $sce, $http, $templateCache, $q, $log, $window, UriTemplate) ->

  linker = (scope, element, attributes) ->
    total = scope.total
    paypalOptions = scope.paypalOptions
    scope.href = new UriTemplate(total.$link('paypal_express').href).fillFromObject(paypalOptions)

    scope.showLoader = () ->
      scope.notLoaded scope if scope.notLoaded

  return {
    restrict: 'EA'
    replace: true
    template: """
      <a ng-href="{{href}}" ng-click="showLoader()">Pay</a>
    """
    scope: {
      total: '='
      bb: '='
      decideNextPage: '='
      paypalOptions: '=bbPaypalExpressButton'
      notLoaded: '='
    }
    link: linker
  }

