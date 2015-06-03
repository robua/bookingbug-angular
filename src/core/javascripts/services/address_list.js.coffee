angular.module('BB.Services').factory "AddressListService", ($q, $window, halClient, UriTemplate) ->
 query: (prms) ->

    deferred = $q.defer()
    href = "/api/v1/company/{company_id}/addresses/{post_code}"
    uri = new UriTemplate(href).fillFromObject({company_id: prms.company.id, post_code: prms.post_code })
    halClient.$get(uri, {}).then (addressList) ->
      deferred.resolve(addressList)
    , (err) =>
      deferred.reject(err)
    deferred.promise

 getAddress: (prms) ->
   deferred = $q.defer()
   href = "/api/v1/company/{company_id}/addresses/address/{id}"
   uri = new UriTemplate(href).fillFromObject({company_id: prms.company.id, id: prms.id})
   halClient.$get(uri, {}).then (customerAddress) ->
     deferred.resolve(customerAddress)
   , (err) =>
     deferred.reject(err)
   deferred.promise
