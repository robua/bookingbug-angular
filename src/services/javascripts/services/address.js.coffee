angular.module('BBAdmin.Services').factory 'AdminAddressService',  ($q, BBModel) ->

  query: (params) ->
    company = params.company
    defer = $q.defer()
    company.$get('addresses').then (collection) ->
      collection.$get('addresses').then (addresss) ->
        models = (new BBModel.Admin.Address(s) for s in addresss)
        defer.resolve(models)
      , (err) ->
        defer.reject(err)
    , (err) ->
      defer.reject(err)
    defer.promise

