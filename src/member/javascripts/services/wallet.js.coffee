angular.module("BB.Services").factory "WalletService", ($q, BBModel) ->

  getWalletForMember: (member) ->
    deferred = $q.defer()
    if !member.$has("wallet")
      deferred.reject("Member does not have an active wallet.")
    else
      member.$get("wallet").then (wallet) ->
        new BBModel.Member.Wallet(wallet)
        deferred.resolve(wallet)
      , (err) ->
        deferred.reject(err)
    deferred.promise

  getWalletLogs: (wallet) ->
    deferred = $q.defer()
    if !wallet.$has('logs')
      deferred.reject("This Wallet doesnt have any history")
    else
      wallet.$get('logs').then (logs) ->
        $scope.logs = for log in logs
          new BBModel.Member.WalletLog(log) 
        deferred.resolve(logs)
      , (err) ->
      	deferred.reject(err)
    deferred.promise