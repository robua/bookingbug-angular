angular.module('BBAdmin.Services').factory 'AdminServiceService', ($q, BBModel, $log) ->

	query: (params) ->
		company = params.company
		defer = $q.defer()
		company.$get('services').then (collection) ->
			collection.$get('services').then (services) ->
				models = (new BBModel.Admin.Service(s) for s in services)
				defer.resolve(models)
			,	(err) ->
				defer.reject(err)
		,	(err) ->
			defer.reject(err)
		defer.promise