angular.module('BB.Services').factory 'SettingsService', () ->

  i18n = false

  enableInternationalizaton: () ->
    i18n = true

  isInternationalizatonEnabled: () ->
    return i18n