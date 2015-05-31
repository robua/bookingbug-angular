'use strict';

# helpful functions about a company
angular.module('BB.Models').factory "CompanyModel", ($q, BBModel, BaseModel) ->

  class Company extends BaseModel

    constructor: (data) ->
      super(data)
      @test = 1

    getCompanyByRef: (ref) ->
      defer = $q.defer()
      @$get('companies').then (companies) ->
        company = _.find(companies, (c) -> c.reference == ref)
        if company
          defer.resolve(company)
        else
          defer.reject('No company for ref '+ref)
      , (err) ->
        console .log 'err ', err
        defer.reject(err)
      defer.promise

    findChildCompany: (id) ->
      return null if !@companies
      for c in @companies
        if c.id == parseInt(id)
          return c
        if c.ref && c.ref == String(id)
          return c
      # failed to find by id - maybe by name ?
      if typeof id == "string"
        name = id.replace(/[\s\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|'’!<>;:,.~`=+-@£&%"]/g, '').toLowerCase()  
        for c in @companies
          cname = c.name.replace(/[\s\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|'’!<>;:,.~`=+-@£&%"]/g, '').toLowerCase()
          if name == cname
            return c
      return null      

    getSettings: () ->
      def = $q.defer()
      if @settings
        def.resolve(@settings)
      else
        if @$has('settings')
          @$get('settings').then (set) =>
            @settings = new BBModel.CompanySettings(set)
            def.resolve(@settings)
        else
          def.reject("Company has no settings")
      return def.promise

      