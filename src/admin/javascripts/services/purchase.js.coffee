

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
    halClient.$put(uri, params).then (purchase) ->
      purchase = new BBModel.Purchase.Total(purchase)
      defer.resolve(purchase)
    , (err) ->
      defer.reject(err)
    defer.promise

