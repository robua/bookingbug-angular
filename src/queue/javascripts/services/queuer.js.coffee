angular.module('BBQueue.Services').factory('QueuerService', ["$q", "$window", "halClient", "BBModel", ($q, UriTemplate, halClient, BBModel) ->

	query: (params) ->
		deferred = $q.defer()

		url = ""
		url = params.url if params.url
		href = url + "/api/v1/queuers/{id}"
		uri = new UriTemplate(href).fillFromObject(params || {})

		halClient.$get(uri, {}).then (found) =>
			deferred.resolve(found)

		deferred.promise

	removeFromQueue: (params) ->
		deferred = $q.defer()

		url = ""
		url = params.url if params.url
		href = url + "/api/v1/queuers/{id}"
		uri = new UriTemplate(href).fillFromObject(params || {})

		halClient.$del(uri).then (found) =>
			deferred.resolve(found)

		deferred.promise

])

