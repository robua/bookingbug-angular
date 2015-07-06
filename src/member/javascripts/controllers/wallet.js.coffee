angular.module("BBMember").controller "Wallet", ($scope, $q, WalletService, $log) ->

  $scope.getWalletForMember = (member) ->
    defer = $q.defer()
    WalletService.getWalletForMember(member).then (wallet) ->
      $scope.wallet = wallet
      defer.resolve(wallet)
    , (err) ->
      $log.error err.data
    defer.promise

  $scope.getWalletLogs = (wallet) ->
    defer = $q.defer()
    WalletService.getWalletLogs(wallet).then (logs) ->
      $scope.logs = logs
      defer.resolve(logs)
    , (err) ->
    	$log.error err.data
    defer.promise

