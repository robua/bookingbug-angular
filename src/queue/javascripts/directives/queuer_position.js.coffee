'use strict';

angular.module('BBQueue.Directives').directive 'bbQueuerPosition', () ->

	restrict: 'AE'
	replace: true
	controller: 'QueuerPosition'
	templateUrl: 'queuer_position.html'
	scope:
		id: '='
		apiUrl: '@'
