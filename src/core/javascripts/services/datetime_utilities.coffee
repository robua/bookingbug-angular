angular.module('BB.Services').factory "DateTimeUlititiesService", () ->

  # converts date and time belonging to BBModel.Day and BBModel.TimeSlot into
  # a valid moment object
  convertTimeSlotToMoment: (date, time) ->
    return if !date and !time

    datetime = moment()
    val = parseInt(time.time)
    hours = parseInt(val / 60)
    mins = val % 60
    datetime.hour(hours)
    datetime.minutes(mins)
    datetime.seconds(0)
    datetime.date(date.date.date())
    datetime.month(date.date.month())
    datetime.year(date.date.year())

    return datetime

  convertMomentToTime: (datetime) ->
    return datetime.minutes() + datetime.hours() * 60