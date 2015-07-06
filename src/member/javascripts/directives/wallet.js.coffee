angular.module('BBMember').directive 'bbWallet', ($rootScope) ->

  link = (scope, element, attrs) ->
    $rootScope.bb ||= {}
    $rootScope.bb.api_url ||= scope.apiUrl
    $rootScope.bb.api_url ||= "http://www.bookingbug.com"

    getWalletForMember = () ->
      scope.getWalletForMember(scope.member)

    getWalletForMember()

  {
    link: link
    controller: 'Wallet'
    templateUrl: 'wallet.html'
    scope:
      apiUrl: '@'
      member: '='
  }