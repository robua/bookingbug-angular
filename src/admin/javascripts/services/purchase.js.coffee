

angular.module('BBAdmin.Services').factory 'AdminPurchaseService',  ($q, halClient, BBModel) ->

  query: (params) ->
    defer = $q.defer()
    uri = params.url_root+"/api/v1/admin/purchases/"+params.purchase_id
    halClient.$get(uri, params).then (purchase) ->
      purchase = new BBModel.Purchase.Total(purchase)
      defer.resolve(purchase)
    , (err) ->
      defer.reject(err)
    defer.promise


  markAsPaid: (params) ->
    defer = $q.defer()

    if !params.purchase or !params.url_root
      defer.reject("invalid request")
      return defer.promise

    if params.company
      company_id = params.company.id
      
    uri = params.url_root+"/api/v1/admin/#{company_id}/purchases/#{params.purchase.id}/pay"

    data = {}
    data.company_id = params.company.id if params.company
    data.notify_admin = params.notify_admin if params.notify_admin
    data.payment_status = params.payment_status  if params.payment_status
    data.amount = params.amount if params.amount
    data.notes = params.notes if params.notes
    data.transaction_id = params.transaction_id if params.transaction_id
    data.notify = params.notify if params.notify
    data.payment_type = params.payment_type if params.payment_type

    halClient.$put(uri, params, data).then (purchase) ->
      purchase = new BBModel.Purchase.Total(purchase)
      defer.resolve(purchase)
    , (err) ->
      defer.reject(err)
    defer.promise

