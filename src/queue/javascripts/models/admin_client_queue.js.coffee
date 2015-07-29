'use strict'

angular.module('BB.Models').factory "Admin.ClientQueueModel", ($q, BBModel, BaseModel) ->

  class Admin_ClientQueue extends BaseModel