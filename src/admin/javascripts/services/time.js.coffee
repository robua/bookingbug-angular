

angular.module('BBAdmin.Services').factory 'AdminTimeService', ($q, $window,
    halClient, BBModel, UriTemplate) ->

  query: (prms) ->
    if prms.day
      prms.date = prms.day.date
    if !prms.edate && prms.date
      prms.edate = prms.date
    url = ""
    url = prms.url if prms.url
    href = url + "/api/v1/{company_id}/time_data{?date,event_id,service_id,person_id}"

    uri = new UriTemplate(href).fillFromObject(prms || {})
    deferred = $q.defer()
    halClient.$get(uri, { no_cache: false }).then (found) =>
      found.$get('events').then (events) =>
        eventItems = []
        for eventItem in events
          event = {}
          event.times = []
          event.event_id = eventItem.event_id
          event.person_id = found.person_id
          for time in eventItem.times
            ts = new BBModel.TimeSlot(time)
            event.times.push(ts)
          eventItems.push(event)
        deferred.resolve(eventItems)
    , (err) =>
      deferred.reject(err)

    deferred.promise
