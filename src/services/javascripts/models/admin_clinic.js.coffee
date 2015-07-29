'use strict'

angular.module('BB.Models').factory "Admin.ClinicModel", ($q, BBModel, BaseModel) ->

  class Admin_Clinic extends BaseModel

    constructor: (data) ->
      super(data)
      @setTimes()
      @setResourcesAndPeople()

    setResourcesAndPeople: () ->
      @resources = _.reduce(@resource_ids, (h, id) ->
        h[id] = true
        h
      , {})
      @people = _.reduce(@person_ids, (h, id) ->
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
    
    getPostData: () ->
      data = {}
      data.name = @name
      data.start_time = @start_time
      data.end_time = @end_time
      data.resource_ids = []
      for id, en of @resources
        data.resource_ids.push(id) if en
      data.person_ids = []
      for id, en of @people
        data.person_ids.push(id) if en
      console.log @address
      data.address_id = @address.id if @address
      data

    save: () ->
      @person_ids = _.compact(_.map(@people, (present, person_id) ->
        person_id if present
      ))
      @resource_ids = _.compact(_.map(@resources, (present, person_id) ->
        person_id if present
      ))
      @$put('self', {}, @).then (clinic) =>
        @updateModel(clinic)
        @setTimes()
        @setResourcesAndPeople()

