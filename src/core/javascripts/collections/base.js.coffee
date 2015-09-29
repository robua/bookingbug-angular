

class window.Collection


class window.Collection.Base

  constructor: (res, items, params) ->
    @res = res
    @items = items
    @params = params
    @callbacks = []

    clean_params = {}
    for key,val of params
      if val?
        if val.id?
          clean_params[key+ "_id"] = val.id
        else
          clean_params[key] = val
    @jparams = JSON.stringify(clean_params) 
    if res
      for n,m of res 
        @[n] = m

  checkItem: (item) ->
    if !@matchesParams(item)
      @deleteItem(item)  #delete if it is in the collection at the moment
      return true    
    else
      for existingItem, index in @items
        if item.self == existingItem.self
          @items[index] = item
          for call in @callbacks
            call[1](item, "update")
          return true

    @items.push(item)    
    for call in @callbacks
      call[1](item, "add") 

  deleteItem: (item) ->
    len = @items.length
    @items = @items.filter (x) -> x.self != item.self
    if @items.length != len
      for call in @callbacks
        call[1](item, "delete")

  getItems: ->
    @items

  addCallback: (obj, fn) ->
    for call in @callbacks
      if call[0] == obj
        return
    @callbacks.push([obj, fn])

  matchesParams: (item) ->
    true


class window.BaseCollections

  constructor: () ->
    @collections = []

  count: () ->
    @collections.length

  add: (col) ->
    @collections.push(col)

  checkItems: (item) ->
   for col in @collections
     col.checkItem(item)  

  deleteItems: (item) ->
   for col in @collections
     col.deleteItem(item) 
 
  find: (prms) ->
    clean_params = {}
    for key,val of prms
      if val?
        if val.id?
          clean_params[key+ "_id"] = val.id
        else
          clean_params[key] = val
    jprms =  JSON.stringify(clean_params)    
    for col in @collections
      if jprms == col.jparams
        return col    
