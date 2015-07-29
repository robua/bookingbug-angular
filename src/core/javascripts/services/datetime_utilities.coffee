angular.module('BB.Services').factory "DateTimeUlititiesService", () ->

  # converts date and time belonging to BBModel.Day and BBModel.TimeSlot into
  # a valid moment object
  convertTimeSlotToMoment: (day, time_slot) ->
    return if !day and !time_slot

    datetime = moment()
    val = parseInt(time_slot.time)
    hours = parseInt(val / 60)
    mins = val % 60
    datetime.hour(hours)
    datetime.minutes(mins)
    datetime.seconds(0)
    datetime.date(day.date.date())
    datetime.month(day.date.month())
    datetime.year(day.date.year())

    return datetime

  convertMomentToTime: (datetime) ->
    return datetime.minutes() + datetime.hours() * 60