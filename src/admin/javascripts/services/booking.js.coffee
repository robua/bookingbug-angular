angular.module('BBAdmin.Services').factory 'AdminBookingService', ($q, $window,
    halClient, BookingCollections, BBModel, UriTemplate) ->

  query: (prms) ->
    if prms.slot
      prms.slot_id = prms.slot.id
    if prms.date
      prms.start_date = prms.date
      prms.end_date = prms.date
    if prms.company
      company = prms.company
      delete prms.company
      prms.company_id = company.id
      
    prms.per_page = 1024 if !prms.per_page?
    prms.include_cancelled = false if !prms.include_cancelled?

    deferred = $q.defer()
    existing = BookingCollections.find(prms)
    if existing
      deferred.resolve(existing)
    else if company
      company.$get('bookings', prms).then (collection) ->
        collection.$get('bookings').then (bookings) -> 
          models = (new BBModel.Admin.Booking(b) for b in bookings)
          spaces = new $window.Collection.Booking(collection, models, prms)
          BookingCollections.add(spaces)
          deferred.resolve(spaces)
        , (err) ->
          deferred.reject(err)
      , (err) ->
        deferred.reject(err)
    else      
      url = ""
      url = prms.url if prms.url
      href = url + "/api/v1/admin/{company_id}/bookings{?slot_id,start_date,end_date,service_id,resource_id,person_id,page,per_page,include_cancelled}"
      uri = new UriTemplate(href).fillFromObject(prms || {})

      halClient.$get(uri, {}).then  (found) =>
        found.$get('bookings').then (items) =>
          sitems = []
          for item in items
            sitems.push(new BBModel.Admin.Booking(item))
          spaces = new $window.Collection.Booking(found, sitems, prms)
          BookingCollections.add(spaces)
          deferred.resolve(spaces)
      , (err) =>
        deferred.reject(err)

    deferred.promise

  getBooking: (prms) ->
    deferred = $q.defer()
    if prms.company && !prms.company_id
      prms.company_id = prms.company.id
    href = "/api/v1/admin/{company_id}/bookings/{id}{?embed}"
    uri = new UriTemplate(href).fillFromObject(prms || {})
    halClient.$get(uri, { no_cache: true }).then (item) ->
      booking  = new BBModel.Admin.Booking(item)
      BookingCollections.checkItems(booking)
      deferred.resolve(booking)
    , (err) =>
      deferred.reject(err)
    deferred.promise

  cancelBooking: (prms, booking) ->
    deferred = $q.defer()
    href = "/api/v1/admin/{company_id}/bookings/{id}?notify={notify}"
    prms.id ?= booking.id
    
    notify = prms.notify
    notify ?= true
    
    uri = new UriTemplate(href).fillFromObject(prms || {})
    halClient.$del(uri, { notify: notify }).then (item) ->
      booking = new BBModel.Admin.Booking(item)
      BookingCollections.checkItems(booking)
      deferred.resolve(booking)
    , (err) =>
      deferred.reject(err)
    deferred.promise

  updateBooking: (prms, booking) ->
    deferred = $q.defer()
    href = "/api/v1/admin/{company_id}/bookings/{id}"
    prms.id ?= booking.id
    
    uri = new UriTemplate(href).fillFromObject(prms || {})
    halClient.$put(uri, {}, prms).then (item) ->
      booking = new BBModel.Admin.Booking(item)
      BookingCollections.checkItems(booking)
      deferred.resolve(booking)
    , (err) =>
      deferred.reject(err)
    deferred.promise

  blockTimeForPerson: (prms, person) ->
    deferred = $q.defer()
    href = "/api/v1/admin/{company_id}/people/{person_id}/block"
    prms.person_id ?= person.id
    prms.booking = true
    uri = new UriTemplate(href).fillFromObject(prms || {})
    halClient.$put(uri, {}, prms).then (item) ->
      booking = new BBModel.Admin.Booking(item)
      BookingCollections.checkItems(booking)
      deferred.resolve(booking)
    , (err) =>
      deferred.reject(err)
    deferred.promise

  addStatusToBooking: (prms, booking, status) ->
    deferred = $q.defer()
    href = "/api/v1/admin/{company_id}/bookings/{booking_id}/multi_status"
    prms.booking_id ?= booking.id
    uri = new UriTemplate(href).fillFromObject(prms || {})
    halClient.$put(uri, {}, { status: status }).then (item) ->
      booking  = new BBModel.Admin.Booking(item)
      BookingCollections.checkItems(booking)
      deferred.resolve(booking)
    , (err) =>
      deferred.reject(err)
    deferred.promise

  addPrivateNoteToBooking: (prms, booking, note) ->
    deferred = $q.defer()
    href = "/api/v1/admin/{company_id}/bookings/{booking_id}/private_notes"
    prms.booking_id ?= booking.id
    
    noteParam = note.note if note.note?
    noteParam ?= note
    
    uri = new UriTemplate(href).fillFromObject(prms || {})
    halClient.$put(uri, {}, { note: noteParam }).then (item) ->
      booking  = new BBModel.Admin.Booking(item)
      BookingCollections.checkItems(booking)
      deferred.resolve(booking)
    , (err) =>
      deferred.reject(err)
    deferred.promise

  updatePrivateNoteForBooking: (prms, booking, note) ->
    deferred = $q.defer()
    href = "/api/v1/admin/{company_id}/bookings/{booking_id}/private_notes/{id}"
    prms.booking_id ?= booking.id
    prms.id ?= note.id
    
    uri = new UriTemplate(href).fillFromObject(prms || {})
    halClient.$put(uri, {}, { note: note.note }).then (item) ->
      booking  = new BBModel.Admin.Booking(item)
      BookingCollections.checkItems(booking)
      deferred.resolve(booking)
    , (err) =>
      deferred.reject(err)
    deferred.promise

  deletePrivateNoteFromBooking: (prms, booking, note) ->
    deferred = $q.defer()
    href = "/api/v1/admin/{company_id}/bookings/{booking_id}/private_notes/{id}"
    prms.booking_id ?= booking.id
    prms.id ?= note.id
    
    uri = new UriTemplate(href).fillFromObject(prms || {})
    halClient.$del(uri, {}).then (item) ->
      booking  = new BBModel.Admin.Booking(item)
      BookingCollections.checkItems(booking)
      deferred.resolve(booking)
    , (err) =>
      deferred.reject(err)
    deferred.promise
