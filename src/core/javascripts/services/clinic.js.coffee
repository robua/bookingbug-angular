angular.module('BB.Services').factory 'ClinicService',  ($q, BBModel, $window) ->

  query: (params) ->
    company = params.company
    defer = $q.defer()

    if params.id # reuqest for a single one
      company.$get('clinics', params).then (clinic) ->
        clinic = new BBModel.Clinic(clinic)
        defer.resolve(clinic)
      , (err) ->
        defer.reject(err)
    else
      existing = ClinicCollections.find(params)
      if existing
        defer.resolve(existing)
      else      
        company.$get('clinics', params).then (collection) ->
          collection.$get('clinics').then (clinics) ->
            clinics = (new BBModel.Clinic(s) for s in clinics)
            defer.resolve(clinics)
          , (err) ->
            defer.reject(err)
        , (err) ->
          defer.reject(err)
    defer.promise

