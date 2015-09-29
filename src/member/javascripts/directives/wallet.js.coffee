angular.module('BBMember').directive 'bbWallet', ($rootScope) ->

  link = (scope, element, attrs) ->
    $rootScope.bb ||= {}
    $rootScope.bb.api_url ||= scope.apiUrl
    $rootScope.bb.api_url ||= "http://www.bookingbug.com"
    scope.member ||= $rootScope.member if $rootScope.member
    
    getWalletForMember = () ->
      scope.getWalletForMember(scope.member, {})

    scope.$watch 'member', (member) ->
      if member?
        getWalletForMember()
      if scope.amount
        getWalletForMember()

    scope.$on 'wallet_payment:success', (event, wallet) ->
      scope.wallet = wallet
      scope.payment_success = true
      scope.error_message = false
      scope.show_topup_box = false

    scope.$on 'wallet_payment:error', (event, error) ->
      scope.error_message = error
      scope.payment_success = false

    scope.$on 'wallet_payment:loading', (event) ->
      scope.loading = true

    scope.$on 'wallet_payment:finished_loading', (event) ->
      scope.loading = false

  {
    link: link
    controller: 'Wallet'
    templateUrl: 'wallet.html'
    scope:
      apiUrl: '@'
      member: '='
  }