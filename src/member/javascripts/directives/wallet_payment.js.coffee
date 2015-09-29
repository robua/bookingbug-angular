angular.module("BB.Directives").directive "bbWalletPayment", ($sce, $rootScope, $window, $location, SettingsService) ->

  getHost = (url) ->
    a = document.createElement('a')
    a.href = url
    a['protocol'] + '//' +a['host']

  sendLoadEvent = (element, origin, scope) ->
    referrer = $location.protocol() + "://" + $location.host()
    if $location.port()
      referrer += ":" + $location.port()
    
    custom_stylesheet = if scope.options.custom_stylesheet then scope.options.custom_stylesheet else null
    custom_partial_url = if scope.bb and scope.bb.custom_partial_url then scope.bb.custom_partial_url else null

    payload = JSON.stringify({
      'type': 'load',
      'message': referrer,
      'custom_partial_url': custom_partial_url,
      'custom_stylesheet' : custom_stylesheet,
      'scroll_offset'     : SettingsService.getScrollOffset()
    })
    element.find('iframe')[0].contentWindow.postMessage(payload, origin)

  link = (scope, element, attrs) ->
    scope.options = scope.$eval(attrs.bbWalletPayment) or {}
    scope.member ||= $rootScope.member if $rootScope.member
    scope.member ||= scope.options.member if scope.options.member
    scope.amount = scope.options.amount if scope.options.amount

    getWalletForMember = () ->
      scope.getWalletForMember(scope.member, {})

    scope.$watch 'member', (member) ->
      if member?
        getWalletForMember()
      if scope.amount
        getWalletForMember()

    scope.$watch 'wallet', (wallet) ->
      if wallet and wallet.$has('new_payment')
        scope.wallet_payment_url = $sce.trustAsResourceUrl(scope.wallet.$href("new_payment"))
        element.find('iframe').bind 'load', (event) =>
          url = scope.wallet_payment_url if scope.wallet_payment_url
          origin = getHost(url)
          sendLoadEvent(element, origin, scope)
          scope.$apply ->
            scope.callSetLoaded()

    $window.addEventListener 'message', (event) =>
      if angular.isObject(event.data)
        data = event.data
      else if not event.data.match(/iFrameSizer/)
        data = JSON.parse event.data
      scope.$apply =>
        if data
          switch data.type
            when "submitting"
              scope.callNotLoaded()
            when "error"
              scope.callSetLoaded()
              scope.error(data.message)
            when "wallet_payment_complete"
              scope.walletPaymentDone()
            when 'basket_wallet_payment_complete'
              scope.callSetLoaded()
              scope.basketWalletPaymentDone()
    , false


  {
    restrict: 'A'
    link: link
    controller: 'Wallet'
    scope: true
    replace: true
  }