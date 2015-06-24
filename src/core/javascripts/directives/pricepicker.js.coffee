angular.module('BB.Directives').directive 'pricepicker', ()->

  controller = ($scope) ->

    $scope.$watch 'price', (price) ->
      $scope.updateModel(price) if price?
        

  link = (scope, element, attrs, ngModel) ->

    ngModel.$render = () ->
      if ngModel.$viewValue
        scope.price = ngModel.$viewValue

    scope.updateModel = (value) ->
      ngModel.$setViewValue(value)


  require: 'ngModel'
  link: link
  controller: controller
  scope: {
    currency: '@'
  }
  template: """
<span>{{0 | currency: currency | limitTo: 1}}</span>
<input type="number" ng-model="price" class="form-control" step="0.01">
"""

