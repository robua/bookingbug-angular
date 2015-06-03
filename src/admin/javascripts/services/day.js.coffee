
angular.module('BBAdmin.Services').factory 'AdminDayService', ($q, $window,
    halClient, BBModel, UriTemplate) ->

  query: (prms) ->
    url = ""
    url = prms.url if prms.url
    href = url + "/api/v1/{company_id}/day_data{?month,week,date,edate,event_id,service_id}"

    uri = new UriTemplate(href).fillFromObject(prms || {})
    deferred = $q.defer()
    halClient.$get(uri, {}).then  (found) =>
      if found.items
        mdays = []
        # it has multiple days of data
        for item in found.items
          halClient.$get(item.uri).then (data) ->
            days = []
            for i in data.days
              if (i.type == prms.item)
                days.push(new BBModel.Day(i))
            dcol = new $window.Collection.Day(data, days, {})
            mdays.push(dcol)
        deferred.resolve(mdays)
    , (err) =>
      deferred.reject(err)

    deferred.promise
