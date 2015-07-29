angular.module('BBQueue').directive 'bbQueueServer', (BBModel,
    AdminCompanyService, PusherQueue, ModalForm) ->

  pusherListen = (scope) ->
    PusherQueue.subscribe(scope.company)
    PusherQueue.channel.bind 'notification', (data) =>
      scope.getQueuers(scope.server)

  controller = ($scope) ->
    $scope.getQueuers = () ->
      $scope.server.getQueuers()
    $scope.getQueuers = _.throttle($scope.getQueuers, 10000)

    $scope.newQueuerModal = () ->
      ModalForm.new
        company: $scope.company
        title: 'New Queuer'
        new_rel: 'new_queuer'
        post_rel: 'queuers'
        success: (queuer) ->
          $scope.server.queuers.push(queuer)

  link = (scope, element, attrs) ->
    if scope.company
      pusherListen(scope)
      scope.server.getQueuers()
    else
      AdminCompanyService.query(attrs).then (company) ->
        scope.company = company
        if scope.user.$has('person')
          scope.user.$get('person').then (person) ->
            scope.server = new BBModel.Admin.Person(person)
            scope.server.getQueuers()
            pusherListen(scope)

  {
    link: link
    controller: controller
  }

angular.module('BBQueue').directive 'bbQueueServerCustomer', () ->

  controller = ($scope) ->

    $scope.selected_queuers = []

    $scope.serveCustomer = () ->
      if $scope.selected_queuers.length > 0
        $scope.loading = true
        $scope.server.startServing($scope.selected_queuers).then () ->
          $scope.loading = false
          $scope.getQueuers()

    $scope.serveNext = () ->
      $scope.loading = true
      $scope.server.startServing().then () ->
        $scope.loading = false
        $scope.getQueuers()

    $scope.extendAppointment = (mins) ->
      $scope.loading = true
      $scope.server.serving.extendAppointment(mins).then () ->
        $scope.loading = false
        $scope.getQueuers()

    $scope.finishServing = () ->
      $scope.loading = true
      $scope.server.finishServing().then () ->
        $scope.loading = false
        $scope.getQueuers()

    $scope.loading = true
    if $scope.server
      $scope.server.setCurrentCustomer().then () ->
        $scope.loading = false

  {
    controller: controller
    templateUrl: 'queue_server_customer.html'
  }

