# Filters
"use strict"

angular.module('BB.Services').factory 'FormDataStoreService',
($rootScope, $window, $log, $parse) ->

  registeredWidgetArr = []
  dataStore = {}
  toId = 0 # timeout id
  div = '___'

  # enabale this to see datastore log info
  log = ->
  #  $log.debug.apply(this, arguments)

  # displays datastore info. only handy for development purposes
  showInfo = ->
    log dataStore
    # log registeredWidgetArr

  # utility to set values on the scope if they are undefined. avoids issue if
  # value is false.
  setIfUndefined = (keyName, val) ->
    scope = this
    getter = $parse keyName

    if typeof getter(scope) is 'undefined'
      getter.assign(scope, val)


  # resets the scope values. when the clear method is called it removes the
  # values from the datastore but it doesn't reset the values on the scope,
  # which means the values on the scope are added back into the datastore on the
  # next digest. so we have to reset them as well.
  resetValuesOnScope = (scope, props) ->
    for prop in props
      prop = $parse prop
      setter = prop.assign;
      setter scope, null
    return


  # clear all form data stored in dataStore if scope is passed in. if datastore
  # key is passed in then just delete that instance. 'keepScopeValues' stops the
  # values on the scope object being reset. so the datastore is cleared but not
  # the scope. this is really only necessary when the destroy method is called.
  clear = (scope, keepScopeValues) ->
    if !scope
      throw new Error('Missing scope object. Cannot clear form data without scope')

    # check for datastore key first
    if _.isString scope
      data = dataStore[scope]
      if !keepScopeValues
        resetValuesOnScope data[0], data[1]
      delete dataStore[scope]
      return

    scope = getParentScope scope
    # destroy all data
    if scope and scope.bb
      widgetId = scope.bb.uid
      removeWidget scope

      for key, data of dataStore
        if key.indexOf(widgetId) isnt -1
          # remove any event handlers if the have been set in setListeners().
          if data[3]
            _.each data[3], (func)->
              # angular returns a function when setting listeners, which when
              # called removes the listener.
              if _.isFunction func
                func()
          # remove the stored data
          if !keepScopeValues
            resetValuesOnScope data[0], data[1]
          delete dataStore[key]
    return


  # called after digest loop finishes. loop through the properties on the scope
  # and store the values if they are registered
  storeFormData = ->
    log 'formDataStore ->', dataStore
    for key, step of dataStore
      log '\t', key
      scope = step[0] # scope object
      props = step[1] # array of key names
      ndata = step[2] # object containing stored values, matching names in props

      if not ndata
        ndata = step[2] = {}

      for prop in props
        val = ndata[prop]
        # destroy the data here
        if val is 'data:destroyed'
          ndata[prop] = null
        else
          val = angular.copy (scope.$eval prop)
          ndata[prop] = val
        log '\t\t', prop, val
        # log 1, step
      log '\n'
    return


  # put the stored values back onto the scope object.
  setValuesOnScope = (currentPage, scope) ->
    cpage = dataStore[currentPage]
    storedValues = cpage[2]
    log 'Decorating scope ->', currentPage, storedValues

    if _.isObject storedValues
      _.each _.keys(storedValues), (keyName) ->
        if typeof storedValues[keyName] isnt 'undefined' and storedValues[keyName] isnt 'data:destroyed'
          # parse the keyname as it might be stored as using dot notation i.e.
          # {"admin.person.age" : someval} needs to be parsed unless the value
          # will be stored on the scope as "admin.person.age" and not a nested
          # object as it should be
          getter = $parse keyName
          getter.assign(scope, storedValues[keyName])

    cpage[0] = scope
    log scope
    log '\n'
    return


  # returns the BBCtrl scope from the supplied scope by walking up the scope
  # chain looking for it's controller id
  getParentScope = (scope) ->
    while (scope)
      # find the controller's rootscope
      if scope.hasOwnProperty('cid') and scope.cid is 'BBCtrl'
        return scope
      scope = scope.$parent


  # the scope argument belongs to the controller which is requesting data to be
  # stored. we check if it's parent widget (BBCtrl) has been registered to store
  # data. BBCtrl is the root scope for all booking journeys.
  checkRegisteredWidgets = (scope) ->
    isRegistered = false
    scope = getParentScope scope

    for rscope in registeredWidgetArr
      if rscope is scope
        isRegistered = true
    return isRegistered


  # generates an array of listeners and normalises the properties to be stored
  # i.e. 'bb.stacked_items->change:storeLocation' becomes
  # ['bb.stacked_items'] ['change:storeLocation']
  checkForListeners = (propsArr) ->
    watchArr = []
    _.each propsArr, (propName, index) ->
      split = propName.split('->')
      if split.length is 2
        watchArr.push(split)
        propsArr[index] = split[0]

    return watchArr


  # creates the listeners for any items that require them and then destroy their
  # data if the eventhandler is called. i.e. registering the following
  # 'bb.stacked_items->change:storeLocation'
  # means the data on '$scope.bb.stack_items' will be stored unless the event
  # 'change:storeLocation', at which point the data will be cleared
  setListeners = (scope, listenerArr, currentPage) ->
    if listenerArr.length
      cpage = dataStore[currentPage]
      listenersArr = cpage[3] or []

      _.each listenerArr, (item, index) ->
        func = $rootScope.$on item[1], ->
          # because of the async nature of events we can't just null the data
          # here as it could be restored in the storeFormData() method, which
          # runs after the digest loop has finished. so we mark it as destroyed
          try cpage[2][item[0]] = 'data:destroyed'
          catch e then log(e)
        # store the registered listeners so we can remove when the widget is
        # destroyed
        listenersArr.push(func)
      # store the listeners along with the other widget information
      cpage[3] = listenersArr


  # uid is used along with the 'current_page' property and widget uid to create
  # an individual keyname to store the values. we do this as there can be
  # multiple widgets containing multiple controllers on a single page. the
  # 'propsArr' array contains a list of key names on the scope which are to  be
  # stored i.e. ['name', 'email', 'address1']
  init = (uid, scope, propsArr) ->
    if checkRegisteredWidgets scope
      currentPage = scope.bb.uid + div + scope.bb.current_page + div + uid
      currentPage = currentPage.toLowerCase()
      watchArr = checkForListeners propsArr
      # return a function which has the current page as a closure. the
      # controller which is initalising the form data can call this at any point
      # to clear the data for it's controller .i.e $scope.clearStoredData()
      scope.clearStoredData = do (currentPage) ->
        ->
          clear currentPage
          return

      if not currentPage
        throw new Error "Missing current step"

      # if the step exists return the values as the form has been there before.
      if dataStore[currentPage]
        setValuesOnScope currentPage, scope
        return

      log 'Controller registered ->', currentPage, scope, '\n\n'
      dataStore[currentPage] = [scope, propsArr]
      setListeners(scope, watchArr, currentPage)
      return



  # remove any registered scopes from the array when they are destroyed
  removeWidget = (scope) ->
    registeredWidgetArr = _.without registeredWidgetArr, scope
    return


  # the service will only store data for widgets which have registered
  # themselves with the store. the scope object should always be BBCtrl's scope
  # object which is always the root scope for all widgets
  register = (scope) ->
    registered = false
    # go up the scope chain to find the app's rootscope, which will be the scope
    # with the bbctrl property

    # step down a scope first - just in case this is on the same as the widget and iot's isloated! 
    if scope && scope.$$childHead
      scope = scope.$$childHead
      
    while !_.has(scope, 'cid')
      scope = scope.$parent

    return if !scope

    if scope.cid isnt 'BBCtrl'
      throw new Error("This directive can only be used with the BBCtrl")
    # check to make sure scope isn't already registered.
    _.each registeredWidgetArr, (stored) ->
      if scope is stored
        registered = true

    if !registered
      log 'Scope registered ->', scope
      scope.$on('destroy', removeWidget)
      registeredWidgetArr.push(scope)

  # when digest loop is triggered wait until after the last loop is run and then
  # store the values
  $rootScope.$watch ->
    $window.clearTimeout(toId)
    toId = setTimeout storeFormData, 300
    return

  $rootScope.$on 'save:formData', storeFormData
  $rootScope.$on 'clear:formData', clear

  return {
    init     : init
    destroy  : (scope) ->
      clear scope, true
    showInfo : showInfo
    register : register
    setIfUndefined : setIfUndefined
  }
