angular.module('pascalprecht.translate').config ($translateProvider, $translatePartialLoaderProvider) ->

  $translatePartialLoaderProvider.addPart('default');
  $translateProvider
    .useLoader('$translatePartialLoader', {
      urlTemplate: '/languages/{part}/{lang}.json'
    })
    .determinePreferredLanguage () ->
      language = navigator.languages[0] or navigator.language or navigator.browserLanguage or navigator.systemLanguage or navigator.userLanguage or 'en'
      language.substr(0,2)
    .fallbackLanguage('en')
    .useCookieStorage()


angular.module('BB.Directives').directive 'bbTranslate', ($translate, $rootScope) ->
  restrict: 'AE'
  scope : false
  link: (scope, element, attrs) ->

    options = scope.$eval(attrs.bbTranslate) or {}
    console.log options

    scope.languages = [{name: 'en', key: 'EN'}, {name: 'de', key: 'DE'}, {name: 'fr', key: 'FR'}]

    $rootScope.connection_started.then ->
      scope.selected_language = _.findWhere(scope.languages, {name: $translate.storage().get($translate.storageKey())})
      moment.locale(scope.selected_language.name) if scope.selected_language

    scope.changeLanguage = (language) ->

      return if !language

      scope.selected_language = language
      moment.locale(language.name)
      if options.widget_lang
        $translate.use(language.name)
      else
        debugger
        $translate.use('default/' + language.name)
      # restart the widget 
      scope.clearBasketItem()
      scope.emptyBasket()
      scope.restart()
      

angular.module('BB.Directives').directive 'bbTimePeriod', ($translate) ->
  restrict: 'AE'
  scope : true
  link: (scope, element, attrs) ->

    scope.duration = scope.$eval attrs.bbTimePeriod

    return if !angular.isNumber scope.duration

    $translate(['HOUR', 'MIN', 'AND']).then (translations) ->
      hour_string = translations.HOUR
      min_string  = translations.MIN
      seperator   = translations.AND

      val = parseInt(scope.duration)
      if val < 60
        scope.duration = "#{val} #{min_string}s"
        return
      hours = parseInt(val / 60)
      mins = val % 60
      if mins == 0
        if hours == 1
          scope.duration = "1 #{hour_string}"
          return
        else
          scope.duration = "#{hours} #{hour_string}s"
          return
      else
        str = "#{hours} #{hour_string}"
        str += "s" if hours > 1
        if mins == 0
          scope.duration = str
          return
        else
          str += " #{seperator}" if seperator.length > 0
          str += " #{mins} #{min_string}s"
          scope.duration = str
          return
