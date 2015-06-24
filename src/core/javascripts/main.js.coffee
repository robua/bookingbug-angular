'use strict'

app = angular.module('BB', [
  'BB.Controllers',
  'BB.Filters',
  'BB.Models',
  'BB.Services',
  'BB.Directives',

  'ngStorage',
  'angular-hal',
  'ui.bootstrap',
  'ngSanitize',
  'ui.map',
  'ui.router.util', 
  'ngLocalData',
  'ngAnimate',
  'angular-data.DSCacheFactory', # newer version of jmdobry angular cache'
  'angularFileUpload',
  'schemaForm',
  'ngStorage',
  'ui-rangeSlider',
  'uiGmapgoogle-maps',
  'angular.filter',
  'ngCookies',
  'slick',
  'angulartics',
  'angulartics.google.analytics',
  'pascalprecht.translate',
  'vcRecaptcha'
]);


# use this to inject application wide settings around the app
app.value('AppConfig', {})

if (window.use_no_conflict)
  window.bbjq = $.noConflict()
  app.value '$bbug', jQuery.noConflict(true)
else
  app.value '$bbug', jQuery

app.constant('UriTemplate', window.UriTemplate)

app.config ($locationProvider, $httpProvider, $provide, ie8HttpBackendProvider) ->
  $httpProvider.defaults.headers.common =
    'App-Id': 'f6b16c23',
    'App-Key': 'f0bc4f65f4fbfe7b4b3b7264b655f5eb'

  $locationProvider.html5Mode(false).hashPrefix('!')

  int = (str) ->
    parseInt(str, 10)

  lowercase = (string) ->
    if angular.isString(string) then string.toLowerCase() else string

  msie = int((/msie (\d+)/.exec(lowercase(navigator.userAgent)) || [])[1])
  if (isNaN(msie))
    msie = int((/trident\/.*; rv:(\d+)/.exec(lowercase(navigator.userAgent)) || [])[1])
  if msie && msie < 10
    $provide.provider({$httpBackend: ie8HttpBackendProvider})


app.run ($rootScope, $log, DebugUtilsService, FormDataStoreService, $bbug, $document, $sessionStorage, AppConfig) ->
  # add methods to the rootscope if they are applicable to whole app
  $rootScope.$log = $log
  $rootScope.$setIfUndefined = FormDataStoreService.setIfUndefined

  $rootScope.bb ||= {}
  $rootScope.bb.api_url = $sessionStorage.getItem("host")

  # add bits of IE8 support
  if ($bbug.support.opacity == false)
    document.createElement('header')
    document.createElement('nav')
    document.createElement('section')
    document.createElement('footer')



angular.module('BB.Services', [
  'ngResource',
  'ngSanitize',
  'ngLocalData'
])

angular.module('BB.Controllers', [
  'ngLocalData',
  'ngSanitize'
])

angular.module('BB.Directives', [])
angular.module('BB.Filters', [])
angular.module('BB.Models', [])

window.bookingbug =
  logout: (options) ->
    options ||= {}
    options.reload = true unless options.reload == false
    logout_opts =
      app_id: 'f6b16c23'
      app_key: 'f0bc4f65f4fbfe7b4b3b7264b655f5eb'
    logout_opts.root = options.root if options.root
    angular.injector(['BB.Services', 'BB.Models', 'ng'])
           .get('LoginService').logout(logout_opts)
    window.location.reload() if options.reload

