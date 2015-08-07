'use strict'

angular.module('BB.Models').factory "Admin.BookingModel", ($q, BBModel, BaseModel, BookingCollections) ->

  class Admin_Booking extends BaseModel

    constructor: (data) ->
      super
      @datetime = moment(@datetime)
      @start = @datetime
      @end = @datetime.clone().add(@duration, 'minutes')
      @title = @full_describe
      @time = @start.hour()* 60 + @start.minute()
      @allDay = false
      if @status == 3
        @className = "status_blocked"
      else if @status == 4
        @className = "status_booked"

    getPostData: () ->
      data = {}
      data.date = @start.format("YYYY-MM-DD")
      data.time = @start.hour() * 60 + @start.minute()
      data.duration = @duration
      data.id = @id
      data.person_id = @person_id
      if @questions
        data.questions = (q.getPostData() for q in @questions)
      data
      
    hasStatus: (status) ->
      @multi_status[status]?

    statusTime: (status) ->
      if @multi_status[status]
        moment(@multi_status[status])
      else
        null

    sinceStatus: (status) ->
      s = @statusTime(status)
      return 0 if !s
      return Math.floor((moment().unix() - s.unix()) / 60)

    sinceStart: (options) ->
      start = @datetime.unix()
      if !options
        return Math.floor((moment().unix() - start) / 60)
      if options.later
        s = @statusTime(options.later).unix()
        if s > start
          return Math.floor((moment().unix() - s) / 60)
      if options.earlier
        s = @statusTime(options.earlier).unix()
        if s < start
          return Math.floor((moment().unix() - s) / 60)
      return Math.floor((moment().unix() - start) / 60)



    $update: (data) ->
      data ||= @getPostData()
      @$put('self', {}, data).then (res) =>
        @constructor(res) 
        BookingCollections.checkItems(@)
 