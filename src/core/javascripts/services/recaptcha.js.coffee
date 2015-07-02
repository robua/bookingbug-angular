angular.module("BB.Services").factory "RecaptchaService", ($q, halClient, UriTemplate) ->

  validateResponse: (params) ->
    deferred = $q.defer()
    href = params.api_url + "/api/v1/recaptcha"
    uri = new UriTemplate(href)
    prms = {}
    prms.response = params.response
    halClient.$post(uri, {}, prms).then (response) ->
      deferred.resolve(response)
    , (err) ->
      deferred.reject(err)
    deferred.promise

