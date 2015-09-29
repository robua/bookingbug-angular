

class window.Collection.Clinic extends window.Collection.Base


  checkItem: (item) ->
    super


  matchesParams: (item) ->
    if @params.start_time
      @start_time ||= moment(@params.start_time)
      return false if @start_time.isAfter(item.start_time)
    if @params.end_time
      @end_date ||= moment(@params.end_time)
      return false if @end_time.isBefore(item.end_time)
    return true


angular.module('BBAdmin.Services').provider "ClinicCollections", () ->
  $get: ->
    new  window.BaseCollections()




