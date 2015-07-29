angular.module('BB.Services').factory "BasketService", ($q, $rootScope, BBModel, MutexService) ->

  addItem: (company, params) ->
    deferred = $q.defer()
    lnk = params.item.book_link
    data = params.item.getPostData()
    if !lnk
      deferred.reject("rel book not found for event")
    else
      MutexService.getLock().then (mutex) ->
        lnk.$post('book', params, data).then (basket) ->
          MutexService.unlock(mutex)
          company.$flush('basket')
          mbasket = new BBModel.Basket(basket, params.bb)
          basket.$get('items').then (items) ->
            promises = []
            for i in items
              item = new BBModel.BasketItem(i, params.bb)
              mbasket.addItem(item)
              # keep an eye on if this item needs any promises resolved to be valid
              promises = promises.concat item.promises
            if promises.length > 0
              $q.all(promises).then () ->
                deferred.resolve(mbasket)
            else
              deferred.resolve(mbasket)
          , (err) ->
            deferred.reject(err)
        , (err) ->
          MutexService.unlock(mutex)
          deferred.reject(err)
    deferred.promise


  applyCoupon: (company, params) ->
    deferred = $q.defer()

    MutexService.getLock().then (mutex) ->
      company.$post('coupon', {}, {coupon: params.coupon}).then (basket) ->
        MutexService.unlock(mutex)
        company.$flush('basket')
        mbasket = new BBModel.Basket(basket, params.bb)
        basket.$get('items').then (items) ->
          promises = []
          for i in items
            item = new BBModel.BasketItem(i, params.bb)
            mbasket.addItem(item)
            # keep an eye on if this item needs any promises resolved to be valid
            promises = promises.concat item.promises
          if promises.length > 0
            $q.all(promises).then () ->
              deferred.resolve(mbasket)
          else
            deferred.resolve(mbasket)
        , (err) ->
          deferred.reject(err)
      , (err) ->
        MutexService.unlock(mutex)
        deferred.reject(err)
    deferred.promise


  


  # add several items at onece - params should have an array of items:
  updateBasket: (company, params) ->
    deferred = $q.defer()
    
    data = {entire_basket: true, items:[]}

    for item in params.items
      lnk = item.book_link if item.book_link 
      xdata = item.getPostData() 
      # force the date into utc
#      d = item.date.date._a
#      date = new Date(Date.UTC(d[0], d[1], d[2]))
#      xdata.date = date
      data.items.push(xdata)  

    if !lnk
      deferred.reject("rel book not found for event")
      return deferred.promise
    MutexService.getLock().then (mutex) ->
      lnk.$post('book', params, data).then (basket) ->
        MutexService.unlock(mutex)
        company.$flush('basket')
        mbasket = new BBModel.Basket(basket, params.bb)
        basket.$get('items').then (items) ->
          promises = []
          for i in items
            item = new BBModel.BasketItem(i, params.bb)
            mbasket.addItem(item)
            # keep an eye on if this item needs any promises resolved to be valid
            promises = promises.concat item.promises
          if promises.length > 0
            $q.all(promises).then () ->
              deferred.resolve(mbasket)
          else
            deferred.resolve(mbasket)
        , (err) ->
          deferred.reject(err)
      , (err) ->
        MutexService.unlock(mutex)
        deferred.reject(err)

    deferred.promise 


  checkPrePaid: (company, event, pre_paid_bookings) ->
    valid_pre_paid = null
    for booking in pre_paid_bookings
      if booking.checkValidity(event)
        valid_pre_paid = booking
    valid_pre_paid

  query: (company, params) ->
    deferred = $q.defer()
    if !company.$has('basket')
      deferred.reject("rel basket not found for company")
    else
      company.$get('basket').then (basket) ->
        basket = new BBModel.Basket(basket, params.bb)
        if basket.$has('items')
          basket.$get('items').then (items) ->
            basket.addItem(new BBModel.BasketItem(item, params.bb)) for item in items
        deferred.resolve(basket)
      , (err) ->
        deferred.reject(err)
    deferred.promise

  deleteItem: (item, company, params) ->
    params = {} if !params
    deferred = $q.defer()
    if !item.$has('self')
      deferred.reject("rel self not found for item")
    else
      MutexService.getLock().then (mutex) ->
        item.$del('self', params).then (basket) ->
          MutexService.unlock(mutex)
          company.$flush('basket')
          basket = new BBModel.Basket(basket, params.bb)
          if basket.$has('items')
            basket.$get('items').then (items) ->
              basket.addItem(new BBModel.BasketItem(item, params.bb)) for item in items
          deferred.resolve(basket)
        , (err) ->
          deferred.reject(err)
      , (err) ->
        MutexService.unlock(mutex)
        deferred.reject(err)

    deferred.promise

  checkout: (company, basket, params) ->
    deferred = $q.defer()
    if !basket.$has('checkout')
      deferred.reject("rel checkout not found for basket")
    else
      data = basket.getPostData()
      data.qudini_booking_id = params.bb.qudini_booking_id if params.bb.qudini_booking_id
      data.affiliate_id = $rootScope.affiliate_id
      MutexService.getLock().then (mutex) ->
        basket.$post('checkout', params, data).then (total) ->
          MutexService.unlock(mutex)
          $rootScope.$broadcast('updateBookings')
          tot = new BBModel.Purchase.Total(total)
          $rootScope.$broadcast('newCheckout', tot)
          basket.clear()
          deferred.resolve(tot)
        , (err) ->
          deferred.reject(err)
      , (err) ->
        MutexService.unlock(mutex)
        deferred.reject(err)
    deferred.promise

  empty: (bb) ->
    deferred = $q.defer()
    MutexService.getLock().then (mutex) ->
      bb.company.$del('basket').then (basket) ->
        MutexService.unlock(mutex)
        bb.company.$flush('basket')
        deferred.resolve(new BBModel.Basket(basket, bb))
      , (err) ->
        deferred.reject(err)
    , (err) ->
      MutexService.unlock(mutex)
      deferred.reject(err)
    deferred.promise

  memberCheckout: (basket, params) ->
    deferred = $q.defer()
    if !basket.$has('checkout')
      deferred.reject("rel checkout not found for basket")
    else if $rootScope.member == null
      deferred.reject("member not set")
    else
      basket._data.setOption('auth_token', $rootScope.member._data.getOption('auth_token'))
      data = {items: (item._data for item in basket.items)}
      basket.$post('checkout', params, data).then (total) ->
        if total.$has('member')
          total.$get('member').then (member) ->
            $rootScope.member.flushBookings()
            $rootScope.member = new BBModel.Member.Member(member)
        deferred.resolve(total)
      , (err) ->
        deferred.reject(err)
    deferred.promise
  
  applyDeal: (company, params) ->
    deferred = $q.defer()

    MutexService.getLock().then (mutex) ->
      params.bb.basket.$post('deal', {}, {deal_code: params.deal_code}).then (basket) ->
        MutexService.unlock(mutex)
        company.$flush('basket')
        mbasket = new BBModel.Basket(basket, params.bb)
        basket.$get('items').then (items) ->
          promises = []
          for i in items
            item = new BBModel.BasketItem(i, params.bb)
            mbasket.addItem(item)
            # keep an eye on if this item needs any promises resolved to be valid
            promises = promises.concat item.promises
          if promises.length > 0
            $q.all(promises).then () ->
              deferred.resolve(mbasket)
          else
            deferred.resolve(mbasket)
        , (err) ->
          deferred.reject(err)
      , (err) ->
        MutexService.unlock(mutex)
        deferred.reject(err)
    deferred.promise

  removeDeal: (company, params) ->
    params = {} if !params
    deferred = $q.defer()
    if !params.bb.basket.$has('deal')
      deferred.reject("No Remove Deal link found")
    else
      MutexService.getLock().then (mutex) ->
        params.bb.basket.$put('deal', {}, {deal_code_id: params.deal_code_id.toString()}).then (basket) ->
          MutexService.unlock(mutex)
          company.$flush('basket')
          basket = new BBModel.Basket(basket, params.bb)
          if basket.$has('items')
            basket.$get('items').then (items) ->
              basket.addItem(new BBModel.BasketItem(item, params.bb)) for item in items
              deferred.resolve(basket)
            , (err) ->
              deferred.reject(err)
        , (err) ->
          MutexService.unlock(mutex)
          deferred.reject(err)
      deferred.promise
