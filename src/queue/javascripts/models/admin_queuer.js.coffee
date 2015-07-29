'use strict'

angular.module('BB.Models').factory "Admin.QueuerModel", ($q, BBModel, BaseModel) ->

  class Admin_Queuer extends BaseModel

    constructor: (data) ->
      super(data)
      @start = moment.parseZone(@start)
      @due = moment.parseZone(@due)
      @end = moment(@start).add(@duration, 'minutes')


    remaining: () ->
      d = @due.diff(moment.utc(), 'seconds')
      @remaining_signed = Math.abs(d);
      @remaining_unsigned = d


    startServing: (person) ->
      defer = $q.defer()
      if @$has('start_serving')
        person.$flush('self')
        @$post('start_serving', {person_id: person.id}).then  (q) =>
          person.$get('self').then (p) -> person.updateModel(p)
          @updateModel(q)
          defer.resolve(@)
        , (err) =>
          defer.reject(err)
      else
        defer.reject('start_serving link not available')
      defer.promise

    finishServing: () ->
      defer = $q.defer()
      if @$has('finish_serving')
        @$post('finish_serving').then  (q) =>
          @updateModel(q)
          defer.resolve(@)
        , (err) =>
          defer.reject(err)
      else
        defer.reject('finish_serving link not available')
      defer.promise

    extendAppointment: (minutes) ->
      defer = $q.defer()
      if @end.isBefore(moment())
        d = moment.duration(moment().diff(@start))
        new_duration = d.as('minutes') + minutes
      else
        new_duration = @duration + minutes
      @$put('self', {}, {duration: new_duration}).then (q) =>
        @updateModel(q)
        @end = moment(@start).add(@duration, 'minutes')
        defer.resolve(@)
      , (err) ->
        defer.reject(err)
      defer.promise

