'use strict'

angular.module('BB.Models').factory "ClinicModel", ($q, BBModel, BaseModel) ->

  class Clinic extends BaseModel

    constructor: (data) ->
      super(data)
      @setTimes()
      @setResourcesAndPeople()
      @settings ||= {}
 
    setResourcesAndPeople: () ->
      @resources = _.reduce(@resource_ids, (h, id) ->
        h[id] = true
        h
      , {})
      @people = _.reduce(@person_ids, (h, id) ->
        h[id] = true
        h
      , {})
      @services = _.reduce(@service_ids, (h, id) ->
        h[id] = true
        h
      , {})
      @uncovered = !@person_ids || @person_ids.length == 0
      if @uncovered
        @className = "clinic_uncovered" 
      else
        @className = "clinic_covered" 



    setTimes: () ->
      if @start_time
        @start_time = moment(@start_time)
        @start = @start_time
      if @end_time
        @end_time = moment(@end_time)
        @end = @end_time
      @title = @name