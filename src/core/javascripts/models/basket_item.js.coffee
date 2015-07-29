
'use strict';

angular.module('BB.Models').factory "BasketItemModel",
($q, $window, BBModel, BookableItemModel, BaseModel, $bbug) ->

  # A class that defines an item in a shopping basket
  # This could represent a time based service, a ticket for an event or class, or any other purchasable item

  class BasketItem extends BaseModel

    constructor: (data, bb) ->
      super(data)
      @ready = false
      @days_link =  null
      @book_link =  null
      @parts_links = {}
      @settings or= {}
      @has_questions = false

      if bb
        @reserve_without_questions = bb.reserve_without_questions        

      # if we were given an id then the item is ready - we need to fake a few items
      if @time
        @time = new BBModel.TimeSlot({time: @time, event_id: @event_id, selected: true, avail: 1, price: @price })
      if @date
        @date = new BBModel.Day({date: @date, spaces: 1})
      if @datetime
        @date = new BBModel.Day({date: @datetime.toISODate(), spaces: 1})
        t =  @datetime.hour() * 60 +  @datetime.minute()
        @time = new BBModel.TimeSlot({time: t, event_id: @event_id, selected: true, avail: 1, price: @price })

      if @id
        @reserve_ready = true # if it has an id - it must be held - so therefore it must already be 'reservable'
        # keep a note of a possibly held item - we might change this item - but we should know waht was possibly already selected
        @held = {time: @time, date: @date, event_id: @event_id }


      @promises = []

      if data

        if data.$has("answers")
          data.$get("answers").then (answers) =>
            data.questions = []
            for a in answers
              data.questions.push({id: a.question_id, answer: a.value})

        if data.$has('company')
          comp = data.$get('company')
          @promises.push(comp)
          comp.then (comp) =>
            c = new BBModel.Company(comp)
            @promises.push(c.getSettings())
            @setCompany(c)

        if data.$has('service')
          serv = data.$get('service')
          @promises.push(serv)
          serv.then (serv) =>
            if serv.$has('category')
              prom = serv.$get('category')
              @promises.push(prom)
              prom.then (cat) =>
                @setCategory(new BBModel.Category(cat))
            @setService(new BBModel.Service(serv), data.questions)
            @setDuration(@duration) if @duration
            @checkReady()
            if @time
              @time.service = @service # the time slot sometimes wants to know thing about the service

        if data.$has('event_group')
          serv = data.$get('event_group')
          @promises.push(serv)
          serv.then (serv) =>
            if serv.$has('category')
              prom = serv.$get('category')
              @promises.push(prom)
              prom.then (cat) =>
                @setCategory(new BBModel.Category(cat))

            @setEventGroup(new BBModel.EventGroup(serv))
            if @time
              @time.service = @event_group # the time slot sometimes wants to know thing about the service

        if data.$has('event_chain')
          chain = data.$get('event_chain')
          @promises.push(chain)
          chain.then (serv) =>
            @setEventChain(new BBModel.EventChain(serv), data.questions)


        if data.$has('resource')
          res = data.$get('resource')
          @promises.push(res)
          res.then (res) =>
            @setResource(new BBModel.Resource(res), false)
        if data.$has('person')
          per = data.$get('person')
          @promises.push(per)
          per.then (per) =>
            @setPerson(new BBModel.Person(per), false)
        if data.$has('event')
          data.$get('event').then (event) =>
            @setEvent(new BBModel.Event(event))

        if data.settings
          @settings = $bbug.extend(true, {}, data.settings)

        if data.attachment_id
          @attachment_id = data.attachment_id

        if data.$has('product')
          data.$get('product').then (product) =>
            @setProduct(product)

        if data.$has('deal')
          data.$get('deal').then (deal) =>
            @setDeal(new BBModel.Deal(deal))


    # bookable slot based functions
    setDefaults: (defaults) ->
      if defaults.settings
        @settings = defaults.settings
      if defaults.company
        @setCompany(defaults.company)
      if defaults.merge_resources
        @setResource(null)
      if defaults.merge_people
        @setPerson(null)
      if defaults.resource
        @setResource(defaults.resource)
      if defaults.person
        @setPerson(defaults.person)
      if defaults.service
        @setService(defaults.service)
      if defaults.category
        @setCategory(defaults.category)
      if defaults.time
        @requested_time = parseInt(defaults.time)
      if defaults.date
        @requested_date = moment(defaults.date)
      if defaults.service_ref
        @service_ref = defaults.service_ref
      if defaults.group
        @group = defaults.group
      if defaults.private_note
        @private_note = defaults.private_note
      if defaults.event_group
        @setEventGroup(defaults.event_group)
      if defaults.event
        @setEvent(defaults.event)
      @defaults = defaults


    storeDefaults: (defaults) ->
      @defaults = defaults


    defaultService: () ->
      return null if !@defaults
      return @defaults.service
      # @defaults = defaults

    # if it turned out that a requested date or time was unavailablem, we'll have to clear it
    requestedTimeUnavailable: ->
      delete @requested_time
      delete @requested_date

    setSlot: (slot) ->

      @date = new BBModel.Day({date: slot.datetime.toISODate(), spaces: 1})
      t =  slot.datetime.hour() * 60 +  slot.datetime.minute()
      @time = new BBModel.TimeSlot({time: t, avail: 1, price: @price })
      @available_slot = slot.id


    setCompany: (company) ->
      @company = company
      @parts_links.company = @company.$href('self')
      @item_details.currency_code = @company.currency_code if @item_details

    clearExistingItem: () ->
      if @$has('self') &&  @event_id
        prom = @$del('self')
        @promises.push(prom)
        prom.then () ->

      delete @earliest_time
      delete @event_id  # when changing the service - we ahve to clear any pre-set event


    setItem: (item) ->
      return if !item
      if item.type == "person"
        @setPerson(item)
      else if item.type == "service"
        @setService(item)
      else if item.type == "resource"
        @setResource(item)


    setService: (serv, default_questions = null) ->
      # if there was previously a service - reset the item details - i.e. the asnwers to questions
      if @service
        if @service.self && serv.self && @service.self == serv.self # return if it's the same service
          # make sure we reset the fact that we are using this service
          if @service.$has('book')
            @book_link = @service
          if serv.$has('days')
            @days_link = serv
          if serv.$has('book')
            @book_link = serv
          return
        # if it's a different service
        @item_details = null
        @clearExistingItem()

      if @service && serv && @service.self && serv.self
        if (@service.self != serv.self) && serv.durations && serv.durations.length > 1
          @duration = null
          @listed_duration = null

      @service = serv
      if serv && (serv instanceof BookableItemModel)
        @service = serv.item


      @parts_links.service = @service.$href('self')
      if @service.$has('book')
        @book_link = @service
      if serv.$has('days')
        @days_link = serv
      if serv.$has('book')
        @book_link = serv

      if @service.$has('questions')
        @has_questions = true

        # we have a questions link - but are there actaully any questions ?
        prom = @service.$get('questions')
        @promises.push(prom)
        prom.then (details) =>
          details.currency_code = @company.currency_code if @company
          @item_details = new BBModel.ItemDetails(details)
          @has_questions = @item_details.hasQuestions
          if default_questions
            @item_details.setAnswers(default_questions)
            @setAskedQuestions()  # make sure the item knows the questions were all answered
        , (err) =>
          @has_questions = false

      else
        @has_questions = false

      # select the first and only duration if this service only has one option

      if @service && @service.durations && @service.durations.length == 1
        @setDuration(@service.durations[0])
        @listed_duration = @service.durations[0]
      # check if the service has a listed duration (this is used for calculating the end time for display)
      if @service && @service.listed_durations && @service.listed_durations.length == 1
        @listed_duration = @service.listed_durations[0]

      if @service.$has('category')
        # we have a category?
        prom = @service.getCategoryPromise()
        if prom
          @promises.push(prom)

    setEventGroup: (event_group) ->
      if @event_group
        if @event_group.self && event_group.self && @event_group.self == event_group.self # return if it's the same event_chain
          return

      @event_group = event_group
      @parts_links.event_group =  @event_group.$href('self').replace('event_group','service')

      if @event_group.$has('category')
        # we have a category?
        prom = @event_group.getCategoryPromise()
        if prom
          @promises.push(prom)

    setEventChain: (event_chain, default_questions = null) ->
      if @event_chain
        if @event_chain.self && event_chain.self && @event_chain.self == event_chain.self # return if it's the same event_chain
          return
      @event_chain = event_chain
      @base_price = parseFloat(event_chain.price)
      if @price != @base_price
        @setPrice(@price)
      else
        @setPrice(@base_price)
      if @event_chain.isSingleBooking()
        # if you can only book one ticket - just use that
        @tickets = {name: "Admittance", max: 1, type: "normal", price: @base_price}
        @tickets.pre_paid_booking_id = @pre_paid_booking_id
        @tickets.qty = @num_book if @num_book


      if @event_chain.$has('questions')
        @has_questions = true

        # we have a questions link - but are there actaully any questions ?
        prom = @event_chain.$get('questions')
        @promises.push(prom)
        prom.then (details) =>
          @item_details = new BBModel.ItemDetails(details)
          @has_questions = @item_details.hasQuestions
          if default_questions
            @item_details.setAnswers(default_questions)
            @setAskedQuestions()  # make sure the item knows the questions were all answered
        , (err) =>
          @has_questions = false
      else
        @has_questions = false

    setEvent: (event) ->

      @event.unselect() if @event
      @event = event
      @event.select()
      @event_chain_id = event.event_chain_id
      @setDate({date: event.date})
      @setTime(event.time)
      @setDuration(event.duration)
      @book_link = event if event.$has('book')
      prom = @event.getChain()
      @promises.push(prom)
      prom.then (chain) =>
        @setEventChain(chain)
      prom = @event.getGroup()
      @promises.push(prom)
      prom.then (group) =>
        @setEventGroup(group)
      @num_book = event.qty
      if @event.getSpacesLeft() <= 0 && !@company.settings
        @status = 8 if @company.getSettings().has_waitlists
      else if @event.getSpacesLeft() <= 0 && @company.settings && @company.settings.has_waitlists 
        @status = 8

 


    # if someone sets a category - we may then later restrict the service list by category
    setCategory: (cat) ->
      @category = cat

    setPerson: (per, set_selected = true) ->
      if set_selected && @earliest_time
        delete @earliest_time

      if !per
        @person = true
        @settings.person = -1 if set_selected
        @parts_links.person = null
        @setService(@service) if @service
        @setResource(@resource, false) if @resource && !@anyResource()
        if @event_id
          delete @event_id  # when changing the person - we ahve to clear any pre-set event
          @setResource(null) if @resource && @defaults && @defaults.merge_resources  # if a resources has been automatically set - clear it
      else
        @person = per
        @settings.person = @person.id if set_selected
        @parts_links.person = @person.$href('self')
        if per.$has('days')
          @days_link = per
        if per.$has('book')
          @book_link = per
        if @event_id && @$has('person') && @$href('person') != @person.self
          delete @event_id  # when changing the person - we ahve to clear any pre-set event
          @setResource(null) if @resource && @defaults && @defaults.merge_resources  # if a resources has been automatically set - clear it

    setResource: (res, set_selected = true) ->
      if set_selected && @earliest_time
        delete @earliest_time

      if !res
        @resource = true
        @settings.resource = -1 if set_selected
        @parts_links.resource = null
        @setService(@service) if @service
        @setPerson(@person, false) if @person && !@anyPerson()
        if @event_id
          delete @event_id  # when changing the resource - we ahve to clear any pre-set event
          @setPerson(null) if @person && @defaults && @defaults.merge_people # if a person has been automatically set - clear it
      else
        @resource = res
        @settings.resource = @resource.id if set_selected
        @parts_links.resource = @resource.$href('self')
        if res.$has('days')
          @days_link = res
        if res.$has('book')
          @book_link = res
        if @event_id && @$has('resource') && @$href('resource') != @resource.self
          delete @event_id  # when changing the resource - we ahve to clear any pre-set event
          @setPerson(null) if @person && @defaults && @defaults.merge_people # if a person has been automatically set - clear it

    setDuration: (dur) ->
      @duration = dur
      if @service
        @base_price = @service.getPriceByDuration(dur)
      if @time && @time.price
        @base_price = @time.price
      if @price && (@price != @base_price) 
        @setPrice(@price)
      else 
         @setPrice(@base_price)


    print_time: () ->
      @time.print_time() if @time

    print_end_time: () ->
      @time.print_end_time(@duration) if @time

    print_time12: (show_suffix = true) ->
      @time.print_time12(show_suffix) if @time

    print_end_time12: (show_suffix = true) ->
      @time.print_end_time12(show_suffix, @duration) if @time



    setTime: (time) ->
      @time.unselect() if @time
      @time = time
      if @time
        @time.select()

        if @datetime
          val = parseInt(time.time)
          hours = parseInt(val / 60)
          mins = val % 60
          @datetime.hour(hours)
          @datetime.minutes(mins)

        if @price && @time.price && (@price != @time.price) 
          @setPrice(@price)
        else if @price && !@time.price
         @setPrice(@price)
        else if @time.price && !@price
           @setPrice(@time.price)
        else
           @setPrice(null)


      @checkReady()

    setDate: (date) ->
      @date = date
      if @date
        @date.date = moment(@date.date)
        if @datetime
          @datetime.date(@date.date.date())
          @datetime.month(@date.date.month())
          @datetime.year(@date.date.year())

      @checkReady()


    clearDateTime: () ->
      delete @date
      delete @time
      delete @datetime
      @ready = false
      @reserve_ready = false


    clearTime: () ->
      delete @time
      @ready = false
      @reserve_ready = false  


    setGroup: (group) ->
      @group = group


    setAskedQuestions: ->
      @asked_questions = true
      @checkReady()

    # check if an item is ready for checking out
    # @ready - means it's fully ready for checkout
    # @reserve_ready - means the question still need asking - but it can be reserved
    checkReady: ->
      if ((@date && @time && @service) || @event || @product || @deal || (@date && @service && @service.duration_unit == 'day')) && (@asked_questions || !@has_questions)
        @ready = true
      if ((@date && @time && @service) || @event || @product || @deal || (@date && @service && @service.duration_unit == 'day'))  && (@asked_questions || !@has_questions || @reserve_without_questions)
        @reserve_ready = true

    getPostData: ->

      if @cloneAnswersItem
        for o_question in @cloneAnswersItem.item_details.questions
          for m_question in @item_details.questions
            if m_question.id == o_question.id
              m_question.answer = o_question.answer

      data = {}
      if @date
        data.date = @date.date.toISODate()
      if @time
        data.time = @time.time
        if @time.event_id
          data.event_id = @time.event_id
        else if @time.event_ids
          data.event_ids = @time.event_ids
      else if @date and @date.event_id
        data.event_id = @date.event_id
      data.price = @price
      data.paid = @paid
      if @book_link
        data.book = @book_link.$href('book')
      data.id = @id
      data.duration = @duration
      data.settings = @settings
      data.settings ||= {}
      data.settings.earliest_time = @earliest_time if @earliest_time
      data.questions = @item_details.getPostData() if @item_details && @asked_questions
      data.move_item_id = @move_item_id if @move_item_id
      data.move_item_id = @srcBooking.id if @srcBooking
      data.service_id = @service.id if @service
      data.resource_id = @resource.id if @resource
      data.person_id = @person.id if @person
      data.length = @length
      if @event
        data.event_id = @event.id
        if @event.pre_paid_booking_id?
          data.pre_paid_booking_id = @event.pre_paid_booking_id
        else if @tickets.pre_paid_booking_id?
          data.pre_paid_booking_id = @tickets.pre_paid_booking_id
        data.tickets = @tickets
      data.pre_paid_booking_id = @pre_paid_booking_id if @pre_paid_booking_id?
      data.event_chain_id = @event_chain_id
      data.event_group_id = @event_group_id
      data.qty = @qty   
      data.status = @status if @status
      data.num_resources = parseInt(@num_resources) if @num_resources?
      data.product = @product
      data.deal = @deal if @deal
      data.recipient = @recipient if @deal && @recipient
      data.recipient_mail = @recipient_mail if @deal && @recipient && @recipient_mail
      data.coupon_id = @coupon_id
      data.is_coupon = @is_coupon
      data.attachment_id = @attachment_id if @attachment_id
      data.vouchers = @deal_codes if @deal_codes

      data.email = @email if @email
      data.first_name = @first_name if @first_name
      data.last_name = @last_name if @last_name

      if @email?
        data.email = @email
      if @email_admin?
        data.email_admin = @email_admin
      data.private_note = @private_note if @private_note
      if @available_slot
        data.available_slot = @available_slot
      return data

    setPrice: (nprice) ->
      if nprice?
        @price = parseFloat(nprice)
        printed_price = @price / 100
        @printed_price = if printed_price % 1 == 0 then "£" + parseInt(printed_price) else $window.sprintf("£%.2f", printed_price)
        @printed_vat_cal = @.company.settings.payment_tax if @.company && @.company.settings
        @printed_vat = @printed_vat_cal / 100 * printed_price if @printed_vat_cal
        @printed_vat_inc = @printed_vat_cal / 100 * printed_price + printed_price if @printed_vat_cal
      else
        @price = null
        @printed_price = null
        @printed_vat_cal = null
        @printed_vat = null
        @printed_vat_inc = null

    getStep: ->
      temp = {}
      temp.service = @service
      temp.category = @category
      temp.person = @person
      temp.resource = @resource
      temp.duration = @duration
      temp.event = @event
      temp.event_group = @event_group
      temp.event_chain = @event_chain
      temp.time = @time
      temp.date = @date
      temp.days_link = @days_link
      temp.book_link = @book_link
      temp.ready = @ready
      return temp

    loadStep: (step) ->
      # don't load the step - if we have an id
      return if @id
      @service = step.service
      @category = step.category
      @person = step.person
      @resource = step.resource
      @duration = step.duration
      @event = step.event
      @event_chain = step.event_chain
      @event_group = step.event_group
      @time = step.time
      @date = step.date
      @days_link = step.days_link
      @book_link = step.book_link
      @ready = step.ready


    # functions for pretty printing some information about of the basket item
    describe: ->
      title = "-"
      title = @service.name if @service
      if @event_group && @event && title == "-"
        title = @event_group.name + " - " + @event.description
      title = @product.name if @product
      title = @deal.name if @deal
      return title

    booking_date: (format) ->
      return null if !@date || !@date.date
      @date.date.format(format)

    booking_time: (seperator = '-') ->
      return null if !@time
      duration = if @listed_duration then @listed_duration else @duration 
      @time.print_time() + " " + seperator + " " +  @time.print_end_time(duration)

    # prints the amount due - which might be different if it's a waitlist
    duePrice: () ->
      if @isWaitlist()
        return 0
      return @price

    isWaitlist: () ->
      return @status && @status == 8 # 8 = waitlist

    # get booking start datetime
    start_datetime: () ->
      return null if !@date || !@time
      start_datetime = moment(@date.date.toISODate())
      start_datetime.minutes(@time.time)
      start_datetime

    # get booking end datetime
    end_datetime: () ->
      return null if !@date || !@time || (!@listed_duration && !@duration)
      duration = if @listed_duration then @listed_duration else @duration 
      end_datetime = moment(@date.date.toISODate())
      end_datetime.minutes(@time.time + duration)
      end_datetime

    # set a booking are to be a move (or a copy?) from a previous booking
    setSrcBooking: (booking) ->
      @srcBooking = booking
      # convert duration from seconds to minutes
      @duration = booking.duration / 60

    anyPerson: () ->
      @person && (typeof @person == 'boolean')
 
    anyResource: () ->
      @resource && (typeof @resource == 'boolean')

    isMovingBooking: ->
      (@srcBooking || @move_item_id)

    setCloneAnswers: (otherItem) ->
      @cloneAnswersItem = otherItem

    questionPrice: =>

      return 0 if !@item_details
      return @item_details.questionPrice(@getQty())


    getQty: =>
      return @qty if @qty
      return @tickets.qty if @tickets
      return 1

    # price including discounts
    totalPrice: =>
      if @tickets.pre_paid_booking_id
        return 0
      if @discount_price?
        return @discount_price + @questionPrice()
      pr = @total_price
      pr = @price if !angular.isNumber(pr)
      pr = 0      if !angular.isNumber(pr)
      return pr + @questionPrice()

    # price not including discounts
    fullPrice: =>
      pr = @base_price
      pr ||= @total_price
      pr ||= @price
      pr ||= 0
      return pr + @questionPrice()

    setProduct: (product) ->
      @product = product
      @book_link = @product if @product.$has('book')

    setDeal: (deal) ->
      @deal = deal
      @book_link = @deal if @deal.$has('book')
      @setPrice(deal.price) if deal.price

    ####################
    # various status tests

    hasPrice: () ->
      if @price
        true
      else
        false

    getAttachment: () ->
      return @attachment if @attachment
      if @$has('attachment') && @attachment_id
        @_data.$get('attachment').then (att) =>
          @attachment = att
          @attachment
