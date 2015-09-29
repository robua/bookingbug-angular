
'use strict';

angular.module('BB.Directives').directive 'bbMap', () ->
  restrict: 'AE'
  replace: true
  scope : true
  controller : 'MapCtrl'

angular.module('BB.Controllers').controller 'MapCtrl',
($scope, $element, $attrs, $rootScope, AlertService, ErrorService, FormDataStoreService, $q, $window, $timeout) ->

  $scope.controller = "public.controllers.MapCtrl"

  FormDataStoreService.init 'MapCtrl', $scope, [
    'address'
    'selectedStore'
    'search_prms'
  ]

  # init vars
  options = $scope.$eval($attrs.bbMap) or {}
  
  map_ready_def               = $q.defer()
  $scope.mapLoaded            = $q.defer()
  $scope.mapReady             = map_ready_def.promise
  $scope.map_init             = $scope.mapLoaded.promise
  $scope.numSearchResults     = options.num_search_results or 6
  $scope.range_limit          = options.range_limit or Infinity
  $scope.showAllMarkers       = false
  $scope.mapMarkers           = []
  $scope.shownMarkers         = $scope.shownMarkers or []
  $scope.numberedPin          ||= null
  $scope.defaultPin           ||= null
  $scope.hide_not_live_stores = false
  $scope.address              = $scope.$eval $attrs.bbAddress if !$scope.address && $attrs.bbAddress
  $scope.error_msg            = options.error_msg or "You need to select a store"
  $scope.notLoaded $scope
  
  # setup geolocation shim
  webshim.setOptions({'waitReady': false, 'loadStyles': false})
  webshim.polyfill("geolocation")

  # check if company is parent
  #if $scope.bb.company.$has('parent')
  $rootScope.connection_started.then ->

    $scope.setLoaded $scope if !$scope.selectedStore
    if $scope.bb.company.companies
      $rootScope.parent_id = $scope.bb.company.id
    else if $rootScope.parent_id
      $scope.initWidget({company_id:$rootScope.parent_id, first_page: $scope.bb.current_page, keep_basket:true})
      return
    else
      $scope.initWidget({company_id:$scope.bb.company.id, first_page: null})
      return

    $scope.companies = $scope.bb.company.companies
    if !$scope.companies or $scope.companies.length is 0
      $scope.companies = [$scope.bb.company]

    $scope.mapBounds = new google.maps.LatLngBounds()
    for comp in $scope.companies
      if comp.address and comp.address.lat and comp.address.long
        latlong = new google.maps.LatLng(comp.address.lat,comp.address.long)
        $scope.mapBounds.extend(latlong)

      $scope.mapOptions =  {
          center: $scope.mapBounds.getCenter(), 
          zoom: 6, 
          mapTypeId: google.maps.MapTypeId.ROADMAP,
        mapTypeControl:true, 
        mapTypeControlOptions: { 
            style: window.google.maps.MapTypeControlStyle.DROPDOWN_MENU 
        } 
      }

    if options and options.map_options
      for key, value of options.map_options
        $scope.mapOptions[key] = value

    map_ready_def.resolve(true)

  , (err) ->  $scope.setLoadedAndShowError($scope, err, 'Sorry, something went wrong')


  # load map and create the map markers. the map is hidden at this point
  $scope.map_init.then ->
    for comp in $scope.companies
      if comp.address and comp.address.lat and comp.address.long
        latlong = new google.maps.LatLng(comp.address.lat,comp.address.long)
        marker = new google.maps.Marker({
          map: $scope.myMap,
          position: latlong,
          visible: $scope.showAllMarkers,
          icon: $scope.defaultPin
        })
        marker.company = comp
        $scope.mapMarkers.push(marker) unless $scope.hide_not_live_stores && !comp.live

    $timeout ->
      $scope.myMap.fitBounds($scope.mapBounds)
      $scope.myMap.setZoom(15);
    checkDataStore()


  $scope.init = (options) ->
    if options
      $scope.hide_not_live_stores = options.hide_not_live_stores


  # if the user has clicked back to the map then display it.
  checkDataStore = ->
    if $scope.selectedStore
      $scope.notLoaded $scope
      if $scope.search_prms
        $scope.searchAddress $scope.search_prms
      else 
        $scope.geolocate()
      google.maps.event.addListenerOnce($scope.myMap, 'idle', ->
        _.each $scope.mapMarkers, (marker) ->
          if $scope.selectedStore.id is marker.company.id
            google.maps.event.trigger(marker, 'click');
      )


  # create title for the map selection step
  $scope.title = ->
    ci = $scope.bb.current_item
    if ci.category and ci.category.description
      p1 = ci.category.description
    else
      p1 = $scope.bb.company.extra.department

    return p1 + ' - ' + $scope.$eval('getCurrentStepTitle()')


  $scope.searchAddress = (prms) ->

    # if a reverse geocode has been performed and the address 
    # is no  different to one the entered, abort the search
    return false if $scope.reverse_geocode_address && $scope.reverse_geocode_address == $scope.address

    delete $scope.geocoder_result
    prms = {} if !prms
    $scope.search_prms = prms
    $scope.map_init.then () ->
      address = $scope.address
      address = prms.address if prms.address

      if address
        req = {address : address}
        req.region = prms.region if prms.region
        req.componentRestrictions = prms.componentRestrictions if prms.componentRestrictions

        if prms.bounds
          sw = new google.maps.LatLng(prms.bounds.sw.x, prms.bounds.sw.y)
          ne = new google.maps.LatLng(prms.bounds.ne.x, prms.bounds.ne.y)
          req.bounds = new google.maps.LatLngBounds(sw, ne)

        new google.maps.Geocoder().geocode req, (results, status) ->

          $scope.geocoder_result = results[0] if results.length > 0 and status is 'OK'

          if !$scope.geocoder_result or ($scope.geocoder_result and $scope.geocoder_result.partial_match)
            searchPlaces(req)
            return 
          else if $scope.geocoder_result
            searchSuccess($scope.geocoder_result)
          else
            searchFailed()
          $scope.setLoaded $scope

    $scope.setLoaded $scope


  searchPlaces = (prms) ->
    
    req = {
      query : prms.address
      types: ['shopping_mall', 'store', 'embassy']
    }

    req.bounds = prms.bounds if prms.bounds 

    service = new google.maps.places.PlacesService($scope.myMap)
    service.textSearch req, (results, status) ->
      if results.length > 0 and status is 'OK'      
        searchSuccess(results[0])
      else if $scope.geocoder_result
        searchSuccess($scope.geocoder_result)
      else
        searchFailed()


  searchSuccess = (result) ->
    AlertService.clear()
    $scope.search_failed = false
    $scope.loc           = result.geometry.location
    $scope.myMap.setCenter $scope.loc
    $scope.myMap.setZoom 15
    $scope.showClosestMarkers $scope.loc
    $rootScope.$broadcast "map:search_success"


  searchFailed = () ->
    $scope.search_failed = true
    AlertService.danger(ErrorService.getError('LOCATION_NOT_FOUND'))
    # need to call apply to update bindings as geocode callback is outside angular library
    $rootScope.$apply()


  $scope.validateAddress = (form) ->
    return false if !form
    if form.$error.required
      AlertService.clear()
      AlertService.danger(ErrorService.getError('MISSING_LOCATION'))
      return false
    else
      return true


  $scope.showClosestMarkers = (latlong) ->
    pi = Math.PI;
    R = 6371  #equatorial radius
    distances = []
    distances_kilometres = []

    lat1 = latlong.lat();
    lon1 = latlong.lng();

    for marker in $scope.mapMarkers
      lat2 = marker.position.lat()
      lon2 = marker.position.lng()

      chLat = lat2-lat1;
      chLon = lon2-lon1;

      dLat = chLat*(pi/180);
      dLon = chLon*(pi/180);

      rLat1 = lat1*(pi/180);
      rLat2 = lat2*(pi/180);

      a = Math.sin(dLat/2) * Math.sin(dLat/2) +
              Math.sin(dLon/2) * Math.sin(dLon/2) * Math.cos(rLat1) * Math.cos(rLat2);
      c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
      d = R * c;
      k = d
      # convert to miles
      d = d * 0.621371192

      if !$scope.showAllMarkers
        marker.setVisible(false)

      marker.distance = d
      marker.distance_kilometres = k
      distances.push marker if d < $scope.range_limit
      distances_kilometres.push marker if k < $scope.range_limit
      items = [distances, distances_kilometres]
      for item in items
        item.sort (a, b)->
          a.distance - b.distance
          a.distance_kilometres - b.distance_kilometres

    $scope.shownMarkers = distances.slice(0,$scope.numSearchResults)
    localBounds = new google.maps.LatLngBounds()
    localBounds.extend(latlong)
    index = 1

    for marker in $scope.shownMarkers
      if $scope.numberedPin
        iconPath = $window.sprintf($scope.numberedPin, index)
        marker.setIcon(iconPath)

      marker.setVisible(true)
      localBounds.extend(marker.position)
      index += 1

    google.maps.event.trigger($scope.myMap, 'resize')
    $scope.myMap.fitBounds(localBounds)


  $scope.openMarkerInfo = (marker) ->
    $scope.currentMarker = marker
    $scope.myInfoWindow.open($scope.myMap, marker)


  $scope.selectItem = (item, route) ->
    return if !$scope.$debounce(1000)

    if !item
      AlertService.warning({msg:$scope.error_msg})
      return

    $scope.notLoaded $scope

    # if the selected store changes, emit an event. the form data store uses
    # this to clear data, but it can be used to action anything.
    if $scope.selectedStore and $scope.selectedStore.id isnt item.id
      $scope.$emit 'change:storeLocation'

    $scope.selectedStore = item;
    $scope.initWidget({company_id:item.id, first_page: route})


  $scope.roundNumberUp = (num, places) ->
    Math.round(num * Math.pow(10, places)) / Math.pow(10, places);


  $scope.geolocate = () ->
    return false if !navigator.geolocation || ($scope.reverse_geocode_address && $scope.reverse_geocode_address == $scope.address)

    $scope.notLoaded $scope

    webshim.ready 'geolocation', ->
      # set timeout as 5 seconds and max age as 1 hour
      options = {timeout: 5000, maximumAge: 3600000}
      navigator.geolocation.getCurrentPosition(reverseGeocode, geolocateFail, options)


  geolocateFail = (error) ->
    switch error.code
      # if the geocode failed because the position was unavailable or the request timed out, raise an alert
      when 2, 3 
        $scope.setLoaded $scope
        AlertService.danger(ErrorService.getError('GEOLOCATION_ERROR'))
      else
        return $scope.setLoaded $scope


  reverseGeocode = (position) ->
    lat    = parseFloat(position.coords.latitude)
    long   = parseFloat(position.coords.longitude)
    latlng = new google.maps.LatLng(lat, long)

    new google.maps.Geocoder().geocode {'latLng': latlng}, (results, status) ->
      if results.length > 0 and status is 'OK'
        $scope.geocoder_result = results[0]

        for ac in $scope.geocoder_result.address_components 
          $scope.reverse_geocode_address = ac.long_name if ac.types.indexOf("route") >= 0  
          $scope.reverse_geocode_address += ', ' + ac.long_name if ac.types.indexOf("locality") >= 0
          $scope.address = $scope.reverse_geocode_address
        searchSuccess($scope.geocoder_result)
      $scope.setLoaded $scope

  $scope.increaseRange = () ->
    $scope.range_limit = Infinity
    $scope.searchAddress($scope.search_prms)


  # look for change in display size to determine if the map needs to be refreshed
  $scope.$watch 'display.xs', (new_value, old_value) =>
    if new_value != old_value && $scope.loc
      $scope.myInfoWindow.close()
      $scope.myMap.setCenter $scope.loc
      $scope.myMap.setZoom 15
      $scope.showClosestMarkers $scope.loc


  $rootScope.$on 'widget:restart', () ->
    $scope.loc = null
    $scope.reverse_geocode_address = null
    $scope.address = null