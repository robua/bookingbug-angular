'use strict';


###**
* @ngdoc service
* @name BB.Models:BookableItem
*
* @description
* Representation of an BookableItem Object
*
* @property {string} name Property name display "-Waiting-"
* @property {string} ready The ready
* @property {string} promise The promise
* @property {string} item Bookable item
####


angular.module('BB.Models').factory "BookableItemModel", ($q, BBModel, BaseModel) ->

  class BookableItem extends BaseModel

    item: null

    promise: null
    

    constructor: (data) ->
      super
      @name = "-Waiting-"
      @ready = $q.defer()
      @promise = @_data.$get('item')
      @promise.then (val) =>
        if val.type == "person"
          @item = new BBModel.Person(val)
          if @item
            for n,m of @item._data
              if @item._data.hasOwnProperty(n) && typeof m != 'function'
                @[n] = m
            @ready.resolve()
          else
            @ready.resolve()
        else if val.type == "resource"
          @item = new BBModel.Resource(val)
          if @item
            for n,m of @item._data
              if @item._data.hasOwnProperty(n) && typeof m != 'function'
                @[n] = m
            @ready.resolve()
          else
            @ready.resolve()
        else if val.type == "service"
          @item = new BBModel.Service(val)
          if @item
            for n,m of @item._data
              if @item._data.hasOwnProperty(n) && typeof m != 'function'
                @[n] = m
            @ready.resolve()
          else
            @ready.resolve()

