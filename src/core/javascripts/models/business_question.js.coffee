'use strict';

angular.module('BB.Models').factory "BusinessQuestionModel", ($q, $filter, BBModel, BaseModel) ->

  class BusinessQuestion extends BaseModel

    constructor: (data) ->
      super(data)
