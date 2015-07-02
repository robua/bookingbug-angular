
class window.Collection.Client extends window.Collection.Base


  checkItem: (item) ->
    super

angular.module('BB.Services').provider "ClientCollections", () ->
  $get: ->
    new  window.BaseCollections()