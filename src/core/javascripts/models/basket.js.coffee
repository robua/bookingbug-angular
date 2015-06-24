'use strict';

angular.module('BB.Models').factory "BasketModel", ($q, BBModel, BaseModel) ->

  class Basket extends BaseModel
    constructor: (data, scope) ->
      if scope && scope.isAdmin
        @is_admin = scope.isAdmin
      else
        @is_admin = false
      if scope? && scope.parent_client
        @parent_client_id = scope.parent_client.id
      @items = []
      super(data)


    addItem: (item) ->
      # check if then item is already in the basket
      for i in @items
        if i == item
          return
        if i.id && item.id && i.id == item.id
          return
      @items.push(item)


    clear: () ->
      @items = []

    clearItem: (item) ->
      @items = @items.filter (i) -> i isnt item

    # should we try to checkout ?
    readyToCheckout: ->
      if @items.length > 0
        return true
      else
        return false


    timeItems: ->
      titems = []
      for i in @items
        titems.push(i) if !i.is_coupon and !i.ready
      titems

    couponItems: ->
      citems = []
      for i in @items
        citems.push(i) if i.is_coupon
      citems

    removeCoupons: ->
      for item, i in @items
        if item.is_coupon
          @items.splice(i, 1)
      @items

    setSettings: (set) ->
      return if !set
      @settings ||= {}
      $.extend(@settings, set)


    setClient: (client) ->
      @client = client


    setClientDetails: (client_details) ->
      @client_details = new BBModel.PurchaseItem(client_details)


    getPostData: ->
      post =
        client: @client.getPostData()
        settings: @settings
        reference: @reference
      post.is_admin = @is_admin
      post.parent_client_id = @parent_client_id
      post.items = []
      for item in @items
        post.items.push(item.getPostData())
      return post


    # the amount due now - taking account of any wait list items
    dueTotal: ->
      total = @totalPrice()
      for item in @items
        total -= item.price if item.isWaitlist()
      total = 0 if total < 0
      total


    length: ->
      @items.length


    questionPrice: (options) ->
      unready = options and options.unready
      price = 0
      for item in @items
        price += item.questionPrice() if (!item.ready and unready) or !unready
      return price

    # return the total price after coupons have been applied
    totalPrice: (options) ->
      unready = options and options.unready
      price = 0
      for item in @items
        price += item.totalPrice() if (!item.ready and unready) or !unready
      return price

    # return the full price before any coupons or deals have been applied
    fullPrice: ->
      price = 0
      for item in @items
        price += item.fullPrice()
      return price

    hasCoupon: ->
      for item in @items
        return true if item.is_coupon
      return false


   # return the total coupon discount applied to the basket
    totalCoupons: ->
      @fullPrice() - @totalPrice() - @totalDealPaid()
    

    totalDuration: ->
      duration = 0
      for item in @items
        duration += item.service.listed_duration if item.service and item.service.listed_duration
      return duration

    containsDeal: ->
      for item in @items
        return true if item.deal_id
      return false

    hasDeal: ->
      for item in @items
        return true if item.deal_codes && item.deal_codes.length > 0
      return false

    getDealCodes: ->
      @deals = if @items[0] && @items[0].deal_codes then @items[0].deal_codes else []
      @deals

    # return the total value of deals (gift certificates) applied to the basket
    totalDeals: ->
      value = 0
      for deal in @getDealCodes()
        value += deal.value
      return value

    # return amount paid by deals (gift certficates)
    totalDealPaid: ->
      total_cert_paid = 0
      for item in @items
        total_cert_paid += item.certificate_paid if item.certificate_paid
      return total_cert_paid

    # return the remaining deal (gift certificate) balance
    remainingDealBalance : ->
      return @totalDeals() - @totalDealPaid()


    hasWaitlistItem : ->
      for item in @items
        return true if item.isWaitlist()
      return false
      