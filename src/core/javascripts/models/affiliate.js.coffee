'use strict';

# helpful functions about a company
angular.module('BB.Models').factory "AffiliateModel", ($q, BBModel, BaseModel) ->

  class Affiliate extends BaseModel

    constructor: (data) ->
      super(data)
      @test = 1

    getCompanyByRef: (ref) ->
      defer = $q.defer()
      @$get('companies', {reference: ref}).then (company) ->
        if company
          defer.resolve(new BBModel.Company(company))
        else
          defer.reject('No company for ref '+ref)
      , (err) ->
        console .log 'err ', err
        defer.reject(err)
      defer.promise
