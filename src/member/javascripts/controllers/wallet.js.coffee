angular.module("BBMember").controller "Wallet", ($scope, $q, WalletService, $log, $modal, $rootScope) ->
  
  $scope.company_id = $scope.member.company_id if $scope.member
  $scope.show_wallet_logs = false
  $scope.loading = true
  $scope.error_message = false
  $scope.payment_success = false


  $scope.toggleWalletPaymentLogs = () ->
    if $scope.show_wallet_logs 
      $scope.show_wallet_logs = false
    else
      $scope.show_wallet_logs = true

  $scope.showTopUpBox = () ->
    if $scope.amount
      true
    else 
      $scope.show_topup_box

  $scope.getWalletForMember = (member, params) ->
    $scope.loading = true
    WalletService.getWalletForMember(member, params).then (wallet) ->
      $scope.loading = false
      $scope.wallet = wallet
      $scope.wallet
    , (err) ->
      $scope.loading = false
      $log.error err.data

  $scope.getWalletLogs = (wallet) ->
    $scope.loading = true
    WalletService.getWalletLogs($scope.wallet).then (logs) ->
      $scope.loading = false
      $scope.logs = logs
    , (err) ->
      $scope.loading = false
      $log.error err.data

  $scope.createWalletForMember = (member) ->
    $scope.loading = true
    WalletService.createWalletForMember(member).then (wallet) ->
      $scope.loading = false
      $scope.wallet = wallet
    , (err) ->
      $scope.loading = false
      $log.error err.data

  
  $scope.updateWallet = (member, amount) ->
    $scope.loading = true
    $scope.payment_success = false
    $scope.error_message = false
    if member and amount
      params = {amount: amount}
      params.wallet_id = $scope.wallet.id if $scope.wallet
      params.total_id = $scope.total.id if $scope.total
      param.deposit = $scope.deposit if $scope.deposit
      params.basket_total_price = $scope.basket.total_price if $scope.basket
      WalletService.updateWalletForMember(member, params).then (wallet) ->
        $scope.loading = false
        $scope.wallet = wallet
      , (err) ->
        $scope.loading = false
        $log.error err.data

  $scope.activateWallet = (member) ->
    $scope.loading = true
    if member
      params = {status: 1}
      params.wallet_id = $scope.wallet.id if $scope.wallet
      WalletService.updateWalletForMember(member, params).then (wallet) ->
        $scope.loading = false
        $scope.wallet = wallet
      , (err) ->
        $scope.loading = false
        $log.error err.date

  $scope.deactivateWallet = (member) ->
    $scope.loading = true
    if member
      params = {status: 0}
      params.wallet_id = $scope.wallet.id if $scope.wallet
      WalletService.updateWalletForMember(member, params).then (wallet) ->
        $scope.loading = false
        $scope.wallet = wallet
      , (err) ->
        $scope.loading = false
        $log.error err.date
  
  $scope.callNotLoaded = () =>
    $scope.loading = true
    $scope.$emit('wallet_payment:loading')

  $scope.callSetLoaded = () =>
    $scope.loading = false
    $scope.$emit('wallet_payment:finished_loading')

  $scope.walletPaymentDone = () ->
    params = {no_cache: true}
    $scope.getWalletForMember($scope.member, params).then (wallet) ->
      $scope.$emit("wallet_payment:success", wallet)

  $scope.basketWalletPaymentDone = () ->
    $scope.decideNextPage('checkout')

  $scope.error = (message) ->
    $scope.error_message = "Payment Failure: " + message
    $log.warn("Payment Failure: " + message)
    $scope.$emit("wallet_payment:error", $scope.error_message)


  