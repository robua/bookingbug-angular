angular.module('BBAdmin.Services').factory 'AdminScheduleService',  ($q, BBModel) ->

  query: (params) ->
    company = params.company
    defer = $q.defer()
    company.$get('schedules').then (collection) ->
      collection.$get('schedules').then (schedules) ->
        models = (new BBModel.Admin.Schedule(s) for s in schedules)
        defer.resolve(models)
      , (err) ->
        defer.reject(err)
    , (err) ->
      defer.reject(err)
    defer.promise


  delete: (schedule) ->
    deferred = $q.defer()
    schedule.$del('self').then  (schedule) =>
      schedule = new BBModel.Admin.Schedule(schedule)
      deferred.resolve(schedule)
    , (err) =>
      deferred.reject(err)

    deferred.promise

  update: (schedule) ->
    deferred = $q.defer()
    schedule.$put('self', {}, schedule.getPostData()).then (c) =>
      schedule = new BBModel.Admin.Schedule(c)
      deferred.resolve(schedule)
    , (err) =>
      deferred.reject(err)
