angular.module('BBQueue').controller 'bbQueues', ($scope, $log,
    AdminQueueService, ModalForm) ->

  $scope.loading = true

  $scope.getQueues = () ->
    params =
      company: $scope.company
    AdminQueueService.query(params).then (queues) ->
      $scope.queues = queues
      $scope.loading = false
    , (err) ->
      $log.error err.data
      $scope.loading = false


