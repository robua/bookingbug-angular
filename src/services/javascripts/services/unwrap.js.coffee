
angular.module('BBAdminServices').factory "BB.Service.schedule", ($q, BBModel) ->
  unwrap: (resource) ->
    return new BBModel.Admin.Schedule(resource)




angular.module('BBAdminServices').factory "BB.Service.person", ($q, BBModel) ->
  unwrap: (resource) ->
    return new BBModel.Admin.Person(resource)


angular.module('BBAdminServices').factory "BB.Service.people", ($q, BBModel) ->
  promise: true
  unwrap: (resource) ->
    deferred = $q.defer()
    resource.$get('people').then (items) =>
      models = []
      for i in items
        models.push(new BBModel.Admin.Person(i))
      deferred.resolve(models)
    , (err) =>
      deferred.reject(err)

    deferred.promise


angular.module('BBAdminServices').factory "BB.Service.resource", ($q, BBModel) ->
  unwrap: (resource) ->
    return new BBModel.Admin.Resource(resource)


angular.module('BBAdminServices').factory "BB.Service.resources", ($q, BBModel) ->
  promise: true
  unwrap: (resource) ->
    deferred = $q.defer()
    resource.$get('resources').then (items) =>
      models = []
      for i in items
        models.push(new BBModel.Admin.Resource(i))
      deferred.resolve(models)
    , (err) =>
      deferred.reject(err)

    deferred.promise



angular.module('BBAdminServices').factory "BB.Service.service", ($q, BBModel) ->
  unwrap: (resource) ->
    return new BBModel.Admin.Service(resource)


angular.module('BBAdminServices').factory "BB.Service.services", ($q, BBModel) ->
  promise: true
  unwrap: (resource) ->
    deferred = $q.defer()
    resource.$get('services').then (items) =>
      models = []
      for i in items
        models.push(new BBModel.Admin.Service(i))
      deferred.resolve(models)
    , (err) =>
      deferred.reject(err)

    deferred.promise
