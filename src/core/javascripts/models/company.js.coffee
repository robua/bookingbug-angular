'use strict';

# helpful functions about a company
angular.module('BB.Models').factory "CompanyModel", ($q, BBModel, BaseModel, halClient, AppConfig, $sessionStorage) ->

  class Company extends BaseModel

    constructor: (data) ->
      super(data)
      # instantiate each child company as a hal resource
      # we'll set the @companies array to all companies - including grandchildren
      # and we'll have an array called child_companies that contains only direct ancesstors
      if @companies
        all_companies = []
        @child_companies = []
        for comp in @companies 
          c = new BBModel.Company(halClient.$parse(comp))
          @child_companies.push(c)
          if c.companies
            # if that company has it's own child companies
            for child in c.companies
              all_companies.push(child)
          else
            all_companies.push(c)
        @companies = all_companies


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

    pusherSubscribe: (callback, options = {}) =>
      if Pusher? && !@pusher?
        @pusher = new Pusher 'c8d8cea659cc46060608',
          encrypted: if options.hasOwnProperty('encrypted') then options.encrypted else true
          authEndpoint: @$link('pusher').href
          auth:
            headers:
              'App-Id' : AppConfig.appId
              'App-Key' : AppConfig.appKey
              'Auth-Token' : $sessionStorage.getItem('auth_token')
        channelName = "private-c#{@id}-w#{@numeric_widget_id}"
        unless @pusher.channel(channelName)?
          @pusher_channel = @pusher.subscribe(channelName)
          @pusher_channel.bind 'booking', callback
          @pusher_channel.bind 'cancellation', callback
          @pusher_channel.bind 'updating', callback

