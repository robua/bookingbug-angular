'use strict'

angular.module('BB.Models').factory "Admin.ScheduleModel", ($q, BBModel, BaseModel) ->

  class Admin_Schedule extends BaseModel

    constructor: (data) ->
      super(data)


    getPostData: () ->
      data = {}
      data.id = @id
      data.rules = @rules
      data.name = @name
      data.company_id = @company_id
      data.duration = @duration
      data
    