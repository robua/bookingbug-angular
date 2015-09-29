angular.module('BB.Services').factory 'ErrorService', (SettingsService) ->

  alerts = [
    {
      key: 'GENERIC',
      type: 'error',
      title: '',
      persist: true,
      msg: "Sorry, it appears that something went wrong. Please try again or call the business you're booking with if the problem persists."
    },
    {
      key: 'LOCATION_NOT_FOUND',
      type: 'warning', 
      title: '', 
      persist: true,
      msg: "Sorry, we don't recognise that location"
    },
    {
      key: 'MISSING_LOCATION',
      type: 'warning', 
      title: '',
      persist: true,
      msg: 'Please enter your location'
    },
    {
      key: 'MISSING_POSTCODE',
      type: 'warning',
      title: '',
      persist: true,
      msg: 'Please enter a postcode'
    },
    {
      key: 'INVALID_POSTCODE',
      type: 'warning', 
      title: '',
      persist: true,
      msg: 'Please enter a valid postcode'
      },
    {
      key: 'ITEM_NO_LONGER_AVAILABLE', 
      type: 'error',       
      title: '',
      persist: true,
      msg: 'Sorry. The item you were trying to book is no longer available. Please try again.'
    },
    {
      key: 'FORM_INVALID',
      type: 'warning',
      title: '', 
      persist: true,
      msg: 'Please complete all required fields'
    },
    {
      key: 'GEOLOCATION_ERROR',
      type: 'error', 
      title: '',
      persist: true,
      msg: 'Sorry, we could not determine your location. Please try searching instead.'
    },
    {
      key: 'EMPTY_BASKET_FOR_CHECKOUT', 
      type: 'warning',
      title: '',
      persist: true,
      msg: 'There are no items in the basket to proceed to checkout.'
    },
    {
      key: 'MAXIMUM_TICKETS',
      type: 'warning', 
      title: '',
      persist: true,
      msg: 'Unfortunately, the maximum number of tickets per person has been reached.'
    },
    {
      key: 'TIME_SLOT_NOT_SELECTED',
      type: 'warning', 
      title: '',
      persist: true,
      msg: 'You need to select a time slot'
    },
    {
      key: 'APPT_AT_SAME_TIME',
      type: 'warning', 
      title: '',
      persist: true,
      msg: 'Your appointment is already booked for this time'
    },
    {
      key: 'REQ_TIME_NOT_AVAIL',
      type: 'warning',
      title: '',
      persist: true,
      msg: 'The requested time slot is not available. Please choose a different time.'
    }
  ]

  getError: (key) ->
    error = _.findWhere(alerts, {key: key})
    error.persist = true
    translate = SettingsService.isInternationalizatonEnabled()
    # if i18n enabled, return the translation key
    if error and translate
      return {msg: "ERROR.#{key}"}
    # else return the error object
    else if error and !translate
      return error
    # if no error with key given found, return generic error
    else if translate
      return {msg: 'GENERIC'}
    else
      return alerts[0]


  getAlert: (key) ->
    alert = _.findWhere(alerts, {key: key})
    translate = SettingsService.isInternationalizatonEnabled()
    # if i18n enabled, return the translation key
    if alert and translate
      return {msg: "ALERT.#{key}"}
    else if alert and !translate
      return alert
    else
      return null
