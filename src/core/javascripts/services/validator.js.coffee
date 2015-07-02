angular.module('BB.Services').factory 'ValidatorService', ($rootScope, AlertService, ErrorService, BBModel, $q, $bbug) ->

  # Use http://regex101.com/ to test patterns

  # UK postcode regex (strict)
  # http://regexlib.com/REDetails.aspx?regexp_id=260
  # uk_postcode_regex = /^([A-PR-UWYZ0-9][A-HK-Y0-9][AEHMNPRTVXY0-9]?[ABEHMNPRVWXY0-9]? {1,2}[0-9][ABD-HJLN-UW-Z]{2}|GIR 0AA)$/i
  uk_postcode_regex = /^(((([A-PR-UWYZ][0-9][0-9A-HJKS-UW]?)|([A-PR-UWYZ][A-HK-Y][0-9][0-9ABEHMNPRV-Y]?))\s{0,1}[0-9]([ABD-HJLNP-UW-Z]{2}))|(GIR\s{0,2}0AA))$/i

  # UK postcode regex (lenient) - this checks for a postcode like string
  # https://gist.github.com/simonwhitaker/5748487
  uk_postcode_regex_lenient = /^[A-Z]{1,2}[0-9][0-9A-Z]?\s*[0-9][A-Z]{2}$/i

  # number only regex
  number_only_regex = /^\d+$/

  # UK mobile number regex (strict)
  uk_mobile_regex_strict = /^((\+44\s?|0)7([45789]\d{2}|624)\s?\d{3}\s?\d{3})$/

  # mobile number regex (lenient)
  mobile_regex_lenient = /^(0|\+)([\d \(\)]{9,19})$/

  # UK landline regex (strict)
  uk_landline_regex_strict = /^(\(?(0|\+44)[1-9]{1}\d{1,4}?\)?\s?\d{3,4}\s?\d{3,4})$/

  # UK landline regex (lenient)
  uk_landline_regex_lenient = /^(0|\+)([\d \(\)]{9,19})$/

  # international number 
  international_number = /^(\+)([\d \(\)]{9,19})$/

  # alphanumeric
  alphanumeric = /^[a-zA-Z0-9]*$/

  geocode_result = null

  # letters and spaces
  alpha: /^[a-zA-Z\s]*$/

  us_phone_number: /(^[\d \(\)-]{9,16})$/

  # Strict email check that also checks for the top domain level too part 1 of 2.
  # email_pattern: /^[a-z0-9!#$%&'*+=?^_\/`{|}~.-]+@.[a-z0-9!#$%&'*+=?^_`{|}~.-]+[.]{1}[a-z0-9-]{2,20}$/i

  getUKPostcodePattern: () ->
    return uk_postcode_regex_lenient

  getNumberOnlyPattern: () ->
    return number_only_regex

  getAlphaNumbericPattern: () ->
    return alphanumeric

  getUKMobilePattern: (strict = false) ->
    return uk_mobile_regex_strict if strict
    return mobile_regex_lenient

  getMobilePattern: () ->
    return mobile_regex_lenient

  getUKLandlinePattern: (strict = false) ->
    return uk_landline_regex_strict if strict
    return uk_landline_regex_lenient

  getIntPhonePattern: () ->
    return international_number

  getGeocodeResult: () ->
    return geocode_result if geocode_result

  # Strict email check that also checks for the top domain level too part 2 of 2.
  # getEmailPatten: () ->
  #   return email_pattern

  validatePostcode: (form, prms) ->
    AlertService.clear()
    return false if !form || !form.postcode
    if form.$error.required
      AlertService.danger(ErrorService.getError('MISSING_POSTCODE'))
      return false
    else if form.$error.pattern
      AlertService.danger(ErrorService.getError('INVALID_POSTCODE'))
      return false
    else
      deferred = $q.defer()
      postcode = form.postcode.$viewValue
      req = {address : postcode}
      req.region = prms.region if prms.region
      req.componentRestrictions = {'postalCode': req.address}
      if prms.bounds
        sw = new google.maps.LatLng(prms.bounds.sw.x, prms.bounds.sw.y)
        ne = new google.maps.LatLng(prms.bounds.ne.x, prms.bounds.ne.y)
        req.bounds = new google.maps.LatLngBounds(sw, ne);
      geocoder = new google.maps.Geocoder()
      geocoder.geocode req, (results, status) ->
        if results.length == 1 && status == 'OK'
          geocode_result = results[0]
          deferred.resolve(true)
        else
          AlertService.danger(ErrorService.getError('INVALID_POSTCODE'))
          $rootScope.$apply()
          deferred.reject(false)
      deferred.promise


  validateForm: (form) ->
    return false if !form
    form.submitted = true
    if form.$invalid and form.raise_alerts and form.alert
      AlertService.danger(form.alert)
      return false
    else if form.$invalid and form.raise_alerts
      AlertService.danger(ErrorService.getError('FORM_INVALID')) 
      return false
    else if form.$invalid 
      return false
    else
      return true


  resetForm: (form) ->
    if form
      form.submitted = false
      form.$setPristine()


  resetForms: (forms) ->
    if forms && $bbug.isArray(forms)
      for form in forms
        form.submitted = false
        form.$setPristine()
