angular.module('BBAdmin.Services').factory 'AdminClinicService',  ($q, BBModel, ClinicCollections, $window) ->

  query: (params) ->
    company = params.company
    defer = $q.defer()

    existing = ClinicCollections.find(params)
    if existing
      defer.resolve(existing)
    else      
      company.$get('clinics').then (collection) ->
        collection.$get('clinics').then (clinics) ->
          models = (new BBModel.Admin.Clinic(s) for s in clinics)
          clinics = new $window.Collection.Clinic(collection, models, params)
          ClinicCollections.add(clinics)
          defer.resolve(clinics)
        , (err) ->
          defer.reject(err)
      , (err) ->
        defer.reject(err)
    defer.promise

  create: (prms, clinic) ->
    company = prms.company
    deferred = $q.defer()
    company.$post('clinics', {}, clinic.getPostData()).then  (clinic) =>
      clinic = new BBModel.Admin.Clinic(clinic)
      ClinicCollections.checkItems(clinic)
      deferred.resolve(clinic)
    , (err) =>
      deferred.reject(err)

    deferred.promise

  delete: (clinic) ->
    deferred = $q.defer()
    clinic.$del('self').then  (clinic) =>
      clinic = new BBModel.Admin.Clinic(clinic)
      ClinicCollections.deleteItems(clinic)
      deferred.resolve(clinic)
    , (err) =>
      deferred.reject(err)

    deferred.promise

  update: (clinic) ->
    deferred = $q.defer()
    clinic.$put('self', {}, clinic.getPostData()).then (c) =>
      clinic = new BBModel.Admin.Clinic(c)
      ClinicCollections.checkItems(clinic)
      deferred.resolve(clinic)
    , (err) =>
      deferred.reject(err)

    deferred.promise
