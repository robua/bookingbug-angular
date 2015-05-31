angular.module('BB.Services').factory 'ModalForm', ($modal, $log) ->

  newForm = ($scope, $modalInstance, company, title, new_rel, post_rel,
      success, fail) ->

    $scope.loading = true
    $scope.title = title
    $scope.company = company
    if $scope.company.$has(new_rel)
      $scope.company.$get(new_rel).then (schema) ->
        $scope.form = _.reject schema.form, (x) -> x.type == 'submit'
        $scope.schema = schema.schema
        $scope.form_model = {}
        $scope.loading = false
    else
      $log.warn("company does not have '#{new_rel}' rel")

    $scope.submit = (form) ->
      $scope.$broadcast('schemaFormValidate')
      $scope.loading = true
      $scope.company.$post(post_rel, {}, $scope.form_model).then (model) ->
        $scope.loading = false
        $modalInstance.close(model)
        success(model) if success
      , (err) ->
        $scope.loading = false
        $modalInstance.close(err)
        $log.error 'Failed to create'
        fail(err) if fail

    $scope.cancel = (event) ->
      event.preventDefault()
      event.stopPropagation()
      $modalInstance.dismiss('cancel')

  editForm = ($scope, $modalInstance, model, title, success, fail) ->
    $scope.loading = true
    $scope.title = title
    $scope.model = model
    if $scope.model.$has('edit')
      $scope.model.$get('edit').then (schema) ->
        $scope.form = _.reject schema.form, (x) -> x.type == 'submit'
        $scope.schema = schema.schema
        $scope.form_model = $scope.model
        $scope.loading = false
    else
      $log.warn("model does not have 'edit' rel")

    $scope.submit = (form) ->
      $scope.$broadcast('schemaFormValidate')
      $scope.loading = true
      $scope.model.$put('self', {}, $scope.form_model).then (model) ->
        $scope.loading = false
        $modalInstance.close(model)
        success(model) if success
      , (err) ->
        $scope.loading = false
        $modalInstance.close(err)
        $log.error 'Failed to create'
        fail() if fail

    $scope.cancel = (event) ->
      event.preventDefault()
      event.stopPropagation()
      $modalInstance.dismiss('cancel')

  new: (config) ->
    templateUrl = config.templateUrl if config.templateUrl
    templateUrl ||= 'modal_form.html'
    $modal.open
      templateUrl: templateUrl
      controller: newForm
      size: config.size
      resolve:
        company: () -> config.company
        title: () -> config.title
        new_rel: () -> config.new_rel
        post_rel: () -> config.post_rel
        success: () -> config.success
        fail: () -> config.fail

  edit: (config) ->
    templateUrl = config.templateUrl if config.templateUrl
    templateUrl ||= 'modal_form.html'
    $modal.open
      templateUrl: templateUrl
      controller: editForm
      size: config.size
      resolve:
        model: () -> config.model
        title: () -> config.title
        success: () -> config.success
        fail: () -> config.fail

