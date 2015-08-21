angular.module('BBAdmin.Services').factory 'AdminServiceService',  ($q,
    $rootScope, halClient, BBModel, UriTemplate) ->

  query: (prms) ->
    if prms.company
      prms.company_id = prms.company.id
    url = ""
    url = $rootScope.bb.api_url if $rootScope.bb.api_url
    href = url + "/api/v1/admin/{company_id}/services"

    uri = new UriTemplate(href).fillFromObject(prms || {})
    deferred = $q.defer()
    halClient.$get(uri, {}).then  (resource) =>
      if !resource.$has('services')
        deferred.reject("No services found")
      else
        resource.$get('services').then (items) =>
          services = []
          for i in items
            services.push(new BBModel.Service(i))
          deferred.resolve(services)
        , (err) =>
          deferred.reject(err)

        deferred.promise