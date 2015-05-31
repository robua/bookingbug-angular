'use strict';

# Breadcrumb Directive

# Example usage;
# <div bb-breadcrumb></div>
# <div bb-breadcrumb complex></div>

# initialise options example
# ng-init="setBasicRoute(['client','service_list'])"

angular.module('BB.Directives').directive 'bbBreadcrumb', (PathSvc) ->
  restrict: 'A'
  replace: true
  scope : true
  controller : 'Breadcrumbs'
  templateUrl : (element, attrs) ->
    if _.has attrs, 'complex'
    then PathSvc.directivePartial "breadcrumb_complex"
    else PathSvc.directivePartial "breadcrumb"

  link : (scope) ->
    return


angular.module('BB.Controllers').controller 'Breadcrumbs', ($scope) ->
  loadStep        = $scope.loadStep
  $scope.steps    = $scope.bb.steps
  $scope.allSteps = $scope.bb.allSteps

  # stop users from clicking back once the form is completed ###
  $scope.loadStep = (number) ->
    if !lastStep() && !currentStep(number) && !atDisablePoint()
      loadStep number


  lastStep = () ->
    return $scope.bb.current_step is $scope.bb.allSteps.length


  currentStep = (step) ->
    return step is $scope.bb.current_step


  atDisablePoint = () ->
    return false if !angular.isDefined($scope.bb.disableGoingBackAtStep)
    return $scope.bb.current_step >= $scope.bb.disableGoingBackAtStep


  $scope.isDisabledStep = (step) ->
    if lastStep() or currentStep(step.number) or !step.passed or atDisablePoint()
      return true
    else
      return false
