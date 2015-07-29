angular.module('BB.Services').factory 'Dialog', ($modal, $log) ->

  controller = ($scope, $modalInstance, model, title, success, fail, body) ->

    $scope.body = body

    $scope.ok = () ->
      $modalInstance.close(model)

    $scope.cancel = () ->
      event.preventDefault()
      event.stopPropagation()
      $modalInstance.dismiss('cancel')

    $modalInstance.result.then () ->
      success(model) if success
    , () ->
      fail() if fail

  confirm: (config) ->
    templateUrl = config.templateUrl if config.templateUrl
    templateUrl ||= 'dialog.html'
    $modal.open
      templateUrl: templateUrl
      controller: controller
      size: config.size || 'sm'
      resolve:
        model: () -> config.model
        title: () -> config.title
        success: () -> config.success
        fail: () -> config.fail
        body: () -> config.body

