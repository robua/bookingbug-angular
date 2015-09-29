angular.module('BBMember').directive 'bbWalletLogs', ($rootScope) ->

  link = (scope, element, attrs) ->
    $rootScope.bb ||= {}
    $rootScope.bb.api_url ||= scope.apiUrl
    $rootScope.bb.api_url ||= "http://www.bookingbug.com"

    getWalletLogsForWallet = () ->
      scope.getWalletLogs(scope.wallet)

    getWalletForMember = () ->
      scope.getWalletForMember(scope.member)
    
    scope.$watch 'member', (member) ->
      if member?
        getWalletForMember()

    scope.$watch 'wallet', (wallet) ->
      if wallet?
        getWalletLogsForWallet()

  {
    link: link
    controller: 'Wallet'
    templateUrl: 'wallet_logs.html'
    scope:
      member: '='
      wallet: '='
  }