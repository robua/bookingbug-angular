angular.module("BB.Services").factory "WalletService", ($q, BBModel) ->

  getWalletForMember: (member, params) ->
    deferred = $q.defer()
    if !member.$has("wallet")
      deferred.reject("Wallets are not turned on.")
    else
      member.$get("wallet", params).then (wallet) ->
        wallet = new BBModel.Member.Wallet(wallet)
        deferred.resolve(wallet)
      , (err) ->
        deferred.reject(err)
    deferred.promise

  getWalletLogs: (wallet) ->
    deferred = $q.defer() 
    if !wallet.$has('logs')
      deferred.reject("No Payments found")
    else
      wallet.$get('logs').then (resource) ->
        resource.$get('logs').then (logs) ->
          logs = (new BBModel.Member.WalletLog(log) for log in logs)
          deferred.resolve(logs)
      , (err) =>
        deferred.reject(err)

    deferred.promise

  updateWalletForMember: (member, params) ->
    deferred = $q.defer()
    if !member.$has("wallet")
      deferred.reject("Wallets are not turned on.")
    else
      member.$put("wallet", {}, params).then (wallet) ->
        wallet = new BBModel.Member.Wallet(wallet)
        deferred.resolve(wallet)
      , (err) ->
        deferred.reject(err)
    deferred.promise

  createWalletForMember: (member) ->
    deferred = $q.defer()
    params = {}
    if !member.$has("wallet")
      deferred.reject("Wallets are not turned on.")
    else
      member.$post("wallet", {}, params).then (wallet) ->
        wallet = new BBModel.Member.Wallet(wallet)
        deferred.resolve(wallet)
      , (err) ->
        deferred.reject(err)
    deferred.promise