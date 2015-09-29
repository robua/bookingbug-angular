angular.module('BB').directive 'bbMemberLogin', ($log, $rootScope,
    $templateCache, $q, halClient, BBModel) ->

  controller = ($scope) ->

    $scope.login_form = {}

    $scope.submit = (form) ->
      form['role'] = 'member'
      $scope.company.$post('login', {}, form).then (login) ->
        if login.$has('members')
          login.$get('members').then (members) ->
            $rootScope.member = new BBModel.Client members[0]
            $scope.setClient($rootScope.member)
            $scope.decideNextPage()
        else if login.$has('member')
          login.$get('member').then (member) ->
            $rootScope.member = new BBModel.Client member
            $scope.setClient($rootScope.member)
            $scope.decideNextPage()
      , (err) ->
        $log.error(err)

  link = (scope, element, attrs) ->

    halClient.$get("#{scope.bb.api_url}/api/v1").then (root) ->
      root.$get("new_login").then (new_login) ->
        scope.form = new_login.form
        scope.schema = new_login.schema
      , (err) ->
        console.log 'err ', err
    , (err) ->
      console.log 'err ', err

  {
    restrict: 'A'
    link: link
    template: """
<form name="login_form" ng-submit="submit(login_form)" sf-schema="schema"
  sf-form="form" sf-model="login_form" sf-options="{feedback: false}"
  ng-if="schema && form"></form>
"""
    controller: controller
  }


