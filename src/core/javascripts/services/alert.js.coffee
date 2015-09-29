angular.module('BB.Services').factory 'AlertService', ($rootScope, ErrorService, $timeout) ->

  $rootScope.alerts = []

  titleLookup = (type, title) ->
    return title if title
    switch type
      when "error", "danger"
        title = "Error"
      else
        title = null
    title

  alertService =
    add: (type, {title, msg, persist}) ->
      persist = true if !persist?
      $rootScope.alerts = []
      alert = 
        type: type
        title: titleLookup(type, title)
        msg: msg
        close: -> alertService.closeAlert(this)
      $rootScope.alerts.push(alert)
      if !persist
        $timeout ->
          $rootScope.alerts.splice($rootScope.alerts.indexOf(alert), 1)
        , 3000
      $rootScope.$broadcast "alert:raised"


    closeAlert: (alert) ->
      @closeAlertIdx $rootScope.alerts.indexOf(alert)

    closeAlertIdx: (index) ->
      $rootScope.alerts.splice index, 1

    clear: ->
      $rootScope.alerts = []

    error: (alert) ->
      return if !alert
      @add('error', {title: alert.title, msg: alert.msg, persist: alert.persist})

    danger: (alert) ->
      return if !alert
      @add('danger', {title: alert.title, msg: alert.msg, persist: alert.persist})

    info: (alert) ->
      return if !alert
      @add('info', {title: alert.title, msg: alert.msg, persist: alert.persist})

    warning: (alert) ->
      return if !alert
      @add('warning', {title: alert.title, msg: alert.msg, persist: alert.persist})

    raise: (alert) ->
     return if !alert
     @add(alert.type, {title: alert.title, msg: alert.msg, persist: alert.persist})