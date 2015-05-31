
angular.module('BB.Services').factory "ItemService", ($q, BBModel) ->
  query: (prms) ->
    deferred = $q.defer()
    if prms.cItem.service && prms.item != 'service'
      if !prms.cItem.service.$has('items')
        prms.cItem.service.$get('item').then (base_item) =>
          @build_items(base_item.$get('items'), prms, deferred)
      else
        @build_items(prms.cItem.service.$get('items'), prms, deferred)
    else if prms.cItem.resource && !prms.cItem.anyResource() && prms.item != 'resource'
      if !prms.cItem.resource.$has('items')
        prms.cItem.resource.$get('item').then (base_item) =>
          @build_items(base_item.$get('items'), prms, deferred)
      else
        @build_items(prms.cItem.resource.$get('items'), prms, deferred)
    
    else if prms.cItem.person && !prms.cItem.anyPerson() && prms.item != 'person'
      if !prms.cItem.person.$has('items')
        prms.cItem.person.$get('item').then (base_item) =>
          @build_items(base_item.$get('items'), prms, deferred)
      else
        @build_items(prms.cItem.person.$get('items'), prms, deferred)
    else
      deferred.reject("No service link found")
  
    deferred.promise

  build_items: (base_items, prms, deferred) ->
    wait_items = [base_items]
    if prms.wait
      wait_items.push(prms.wait)
    $q.all(wait_items).then (resources) =>
      resource = resources[0]  # the first one was my own data
      resource.$get('items').then (found) =>
        matching = []
        wlist = []
        for v in found
          if v.type == prms.item
            matching.push(new BBModel.BookableItem(v))
        $q.all((m.ready.promise for m in matching)).then () ->
          deferred.resolve(matching)

