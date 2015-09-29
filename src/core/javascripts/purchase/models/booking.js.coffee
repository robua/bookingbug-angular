'use strict';

angular.module('BB.Models').factory "Purchase.BookingModel", ($q, $window, BBModel, BaseModel, $bbug) ->


  class Purchase_Booking extends BaseModel
    constructor: (data) ->
      super(data)
      @ready = false
  
      @datetime = moment.parseZone(@datetime) 
      @datetime.tz(@time_zone) if @time_zone
      @original_datetime = moment(@datetime)

      @end_datetime = moment.parseZone(@end_datetime)
      @end_datetime.tz(@time_zone) if @time_zone
 
 

    getGroup: () ->
      return @group if @group
      if @_data.$has('event_groups')
        @_data.$get('event_groups').then (group) =>
          @group = group
          @group


    getColour: () ->
      if @getGroup()
        return @getGroup().colour
      else
        return "#FFFFFF"


    getCompany: () ->
      return @company if @company
      if @$has('company')
        @_data.$get('company').then (company) =>
          @company = new BBModel.Company(company)
          @company


    getAnswersPromise: () =>
      defer = $q.defer()
      defer.resolve(@answers) if @answers
      if @_data.$has('answers')
        @_data.$get('answers').then (answers) =>
          @answers = (new BBModel.Answer(a) for a in answers)
          defer.resolve(@answers)
      else
        defer.resolve([])
      defer.promise

    getSurveyAnswersPromise: () =>
      defer = $q.defer()
      defer.resolve(@survey_answers) if @survey_answers
      if @_data.$has('survey_answers')
        @_data.$get('survey_answers').then (survey_answers) =>
          @survey_answers = (new BBModel.Answer(a) for a in survey_answers)
          defer.resolve(@survey_answers)
      else
        defer.resolve([])
      defer.promise


    answer: (q) ->
      if @answers
        for a in @answers
          if a.name == q
            return a.answer
      return null


    getPostData: () ->
      data = {}

      data.attended = @attended
      data.client_id = @client_id
      data.company_id = @company_id
      data.time = (@datetime.hour() * 60) + @datetime.minute()
      data.date = @datetime.toISODate() 
      data.deleted = @deleted
      data.describe = @describe
      data.duration = @duration
      data.end_datetime = @end_datetime
      data.event_id = @event.id if @event
      data.event_id = @time.event_id if @time && @time.event_id
      data.full_describe = @full_describe
      data.id = @id
      data.min_cancellation_time =  @min_cancellation_time
      data.on_waitlist = @on_waitlist
      data.paid = @paid
      data.person_name = @person_name
      data.price = @price
      data.purchase_id = @purchase_id
      data.purchase_ref = @purchase_ref
      data.quantity = @quantity
      data.self = @self
      data.move_item_id = @move_item_id if @move_item_id
      data.move_item_id = @srcBooking.id if @srcBooking
      data.person_id = @person.id if @person
      data.service_id = @service.id if @service
      data.resource_id = @resource.id if @resource
      data.questions = @item_details.getPostData() if @item_details
      data.service_name = @service_name
      data.settings = @settings
      data.status = @status if @status
      if @email?
        data.email = @email
      if @email_admin?
        data.email_admin = @email_admin

      formatted_survey_answers = []
      if @survey_questions
        data.survey_questions = @survey_questions
        for q in @survey_questions
          formatted_survey_answers.push({value: q.answer, outcome: q.outcome, detail_type_id: q.id, price: q.price}) 
        data.survey_answers = formatted_survey_answers

      return data

    checkReady: ->
      if (@datetime && @id && @purchase_ref)
        @ready = true


    printed_price: () ->
      return "£" + parseInt(@price) if parseFloat(@price) % 1 == 0
      return $window.sprintf("£%.2f", parseFloat(@price))


    getDateString: () ->
      @datetime.toISODate()


    # return the time of day in total minutes
    getTimeInMins: () ->
      (@datetime.hour() * 60) + @.datetime.minute()


    getAttachments: () ->
      return @attachments if @attachments
      if @$has('attachments')
        @_data.$get('attachments').then (atts) =>
          @attachments = atts.attachments
          @attachments

    canCancel: () ->
      return moment(@min_cancellation_time).isAfter(moment())

    canMove: () ->
      return @canCancel()  

