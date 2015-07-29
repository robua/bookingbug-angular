angular.module('BBQueue').controller 'bbQueuers', ($scope, $log,
    AdminQueuerService, ModalForm, $interval) ->

  $scope.loading = true

  $scope.getQueuers = () ->
    params =
      company: $scope.company
    AdminQueuerService.query(params).then (queuers) ->
      $scope.queuers = queuers
      $scope.waiting_queuers = []
      for queuer in queuers
        queuer.remaining()
        $scope.waiting_queuers.push(queuer) if queuer.position > 0

      $scope.loading = false
    , (err) ->
      $log.error err.data
      $scope.loading = false

  $scope.newQueuerModal = () ->
    ModalForm.new
      company: $scope.company
      title: 'New Queuer'
      new_rel: 'new_queuer'
      post_rel: 'queuers'
      success: (queuer) ->
        $scope.queuers.push(queuer)

  
    # this is used to retrigger a scope check that will update service time
  $interval(->
    if $scope.queuers
      for queuer in $scope.queuers
        queuer.remaining()
  , 5000)
