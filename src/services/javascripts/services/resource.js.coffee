angular.module('BBAdmin.Services').factory 'AdminResourceService',
($q, UriTemplate, halClient, SlotCollections, BBModel) ->

  query: (params) ->
    company = params.company
    defer = $q.defer()
    company.$get('resources').then (collection) ->
      collection.$get('resources').then (resources) ->
        models = (new BBModel.Admin.Resource(r) for r in resources)
        defer.resolve(models)
      , (err) ->
        defer.reject(err)
    , (err) ->
      defer.reject(err)
    defer.promise

  block: (company, resource, data) ->
    prms = {id:  resource.id, company_id: company.id}

    deferred = $q.defer()
    href = "/api/v1/admin/{company_id}/resource/{id}/block"
    uri = new UriTemplate(href).fillFromObject(prms || {})

    halClient.$put(uri, {}, data).then  (slot) =>
      slot = new BBModel.Admin.Slot(slot)
      SlotCollections.checkItems(slot)
      deferred.resolve(slot)
    , (err) =>
      deferred.reject(err)

    deferred.promise
