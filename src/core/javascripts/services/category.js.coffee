angular.module('BB.Services').factory "CategoryService", ($q, BBModel) ->
  query: (company) ->
    deferred = $q.defer()
    if !company.$has('categories')
      deferred.reject("No categories found")
    else
      company.$get('named_categories').then (resource) =>
        resource.$get('categories').then (items) =>
          categories = []
          for i, _i in items
            cat = new BBModel.Category(i)
            cat.order ||= _i
            categories.push(cat)
          deferred.resolve(categories)
      , (err) =>
        deferred.reject(err)

    deferred.promise
