angular.module('BBAdminServices').factory 'AdminPersonService',  ($q, $window,
    $rootScope, halClient, SlotCollections, BBModel, LoginService, $log) ->

  query: (params) ->
    company = params.company
    defer = $q.defer()
    if company.$has('people')
      company.$get('people').then (collection) ->
        collection.$get('people').then (people) ->
          models = (new BBModel.Person(p) for p in people)
          defer.resolve(models)
        , (err) ->
          defer.reject(err)
      , (err) ->
        defer.reject(err)
    else
      $log.warn('company has no people link')
      defer.reject('company has no people link')
    defer.promise

  block: (company, person, data) ->
    prms = {id:  person.id, company_id: company.id}

    deferred = $q.defer()
    href = "/api/v1/admin/{company_id}/people/{id}/block"
    uri = new $window.UriTemplate.parse(href).expand(prms || {})

    halClient.$put(uri, {}, data).then  (slot) =>
      slot = new BBModel.Admin.Slot(slot)
      SlotCollections.checkItems(slot)
      deferred.resolve(slot)
    , (err) =>
      deferred.reject(err)

    deferred.promise

  signup: (user, data) ->
    defer = $q.defer()
    user.$get('company').then (company) ->
      params = {}
      company.$post('people', params, data).then (person) ->
        if person.$has('administrator')
          person.$get('administrator').then (user) ->
            LoginService.setLogin(user)
            defer.resolve(person)
        else
          defer.resolve(person)
      , (err) ->
        defer.reject(err)
      defer.promise

