angular.module('BBQueue.Services').factory 'AdminQueueService', ($q, $window, halClient, BBModel) ->

  query: (prms) ->
      
    deferred = $q.defer()
    prms.company.$get('client_queues').then (collection) ->
      collection.$get('client_queues').then (client_queues) ->
        models = (new BBModel.Admin.ClientQueue(q) for q in client_queues)
        deferred.resolve(models)
      , (err) ->
        deferred.reject(err)
    , (err) ->
      deferred.reject(err)

    deferred.promise

