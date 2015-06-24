# Filters
app = angular.module 'BB.Filters'

# strips the postcode from the end of the address. i.e.
# '15 some address, somwhere, SS1 4RP' becomes '15 some address, somwhere'
app.filter 'stripPostcode', ->
  (address) ->
    # test to see if the address contains a postcode by searching for a any
    # letter followed by a number i.e N1, CM11
    match = address.toLowerCase().match(/[a-z]+\d/)
    # if there's a match, get the index of the match and remove postcode
    if match
      address = address.substr(0, match.index)
    # trim white space
    address = $.trim(address)
    #  remove trailing comma if there is one
    if /,$/.test(address)
      address = address.slice(0, -1)

    return address

   
app.filter 'labelNumber', ->
  (input, labels) ->
    response = input
    if labels[input]
      response = labels[input]
    return response


app.filter 'interpolate', ['version', (version) ->
  (text) ->
    return String(text).replace(/\%VERSION\%/mg, version)
]


app.filter 'rag', ->
  (value, v1, v2) ->
   if (value <= v1)
      return "red"
    else if (value <=v2)
      return "amber"
    else
      return "green"


app.filter 'time', ($window) ->
  (v) ->
    return $window.sprintf("%02d:%02d",Math.floor(v / 60), v%60 )


app.filter 'address_single_line', ->
  (address) =>

    return if !address
    return if !address.address1

    addr = ""
    addr += address.address1
    if address.address2 && address.address2.length > 0
      addr += ", "
      addr += address.address2
    if address.address3 && address.address3.length > 0
      addr += ", "
      addr += address.address3
    if address.address4 && address.address4.length > 0
      addr += ", "
      addr += address.address4
    if address.address5 && address.address5.length > 0
      addr += ", "
      addr += address.address5
    if address.postcode && address.postcode.length > 0
      addr += ", "
      addr += address.postcode
    return addr


app.filter 'address_multi_line', ->
  (address) =>

    return if !address
    return if !address.address1

    str = ""
    str += address.address1 if address.address1
    str += "<br/>" if address.address2 && str.length > 0
    str += address.address2 if address.address2
    str += "<br/>" if address.address3 && str.length > 0
    str += address.address3 if address.address3
    str += "<br/>" if address.address4 && str.length > 0
    str += address.address4 if address.address4
    str += "<br/>" if address.address5 && str.length > 0
    str += address.address5 if address.address5
    str += "<br/>" if address.postcode && str.length > 0
    str += address.postcode if address.postcode
    return str

app.filter 'map_lat_long', ->
  (address) =>
    return if !address
    return if !address.map_url

    cord = /([-+]*\d{1,3}[\.]\d*)[, ]([-+]*\d{1,3}[\.]\d*)/.exec(address.map_url)
    return cord[0]

app.filter 'currency', ($filter) ->
  (number, currencyCode) =>
    return $filter('icurrency')(number, currencyCode)

app.filter 'icurrency', ($window, $rootScope) ->
  (number, currencyCode) =>
    currencyCode ||= $rootScope.bb_currency
    currency = {
      USD: "$",
      GBP: "£",
      AUD: "$",
      EUR: "€",
      CAD: "$",
      MIXED: "~"
    }

    if $.inArray(currencyCode, ["USD", "AUD", "CAD", "MIXED", "GBP"]) >= 0
      thousand = ","
      decimal = "."
      format = "%s%v"
    else
      thousand = "."
      decimal = ","
      format = "%s%v"

    number = number / 100.0

    $window.accounting.formatMoney(number, currency[currencyCode], 2, thousand, decimal, format)


app.filter 'pretty_price', ($filter) ->
  (price, symbol) ->
    return $filter('ipretty_price')(price, symbol)


app.filter 'ipretty_price', ($window, $rootScope) ->
  (price, symbol) ->
    if !symbol
      currency = {
        USD: "$",
        GBP: "£",
        AUD: "$",
        EUR: "€",
        CAD: "$",
        MIXED: "~"
      }
      symbol = currency[$rootScope.bb_currency]

    price /= 100.0

    if parseFloat(price) == 0
      return 'Free'
    else if parseFloat(price) % 1 == 0
      return symbol + parseFloat(price)
    else
      return symbol + $window.sprintf("%.2f", parseFloat(price))


app.filter 'time_period', ->
  (v, options) ->

    return if !angular.isNumber(v)

    hour_string = if options && options.abbr_units then "hr"  else "hour"
    min_string  = if options && options.abbr_units then "min" else "minute"
    seperator   = if options && angular.isString(options.seperator) then options.seperator else "and"

    val = parseInt(v)
    if val < 60
      return "#{val} #{min_string}s"
    hours = parseInt(val / 60)
    mins = val % 60
    if mins == 0
      if hours == 1
        return "1 #{hour_string}"
      else
       return "#{hours} #{hour_string}s"
    else
      str = "#{hours} #{hour_string}"
      str += "s" if hours > 1
      return str if mins == 0
      str += " #{seperator}" if seperator.length > 0
      str += " #{mins} #{min_string}s"

    return str


app.filter 'twelve_hour_time', ($window) ->
  (time, options) ->

    return if !angular.isNumber(time)

    omit_mins_on_hour = options && options.omit_mins_on_hour or false
    seperator         = if options && options.seperator then options.seperator else ":"

    t = time
    h = Math.floor(t / 60)
    m = t%60
    suffix = 'am'
    suffix = 'pm' if h >=12
    h -=12 if (h > 12)
    if m is 0 && omit_mins_on_hour
      time = "#{h}"
    else
      time = "#{h}#{seperator}" + $window.sprintf("%02d", m)
    time += suffix
    return time


app.filter 'time_period_from_seconds', ->
  (v) ->
    val = parseInt(v)
    if val < 60
      return "" + val + " seconds"
    hours = Math.floor(val / 3600)
    mins  = Math.floor(val % 3600 / 60)
    secs  = Math.floor(val % 60)
    str = ""
    if hours > 0
      str += hours + " hour"
      str += "s" if hours > 1
      return str if mins == 0 && secs == 0
      str += " and "
    if mins > 0
      str +=  mins + " minute"
      str += "s" if mins > 1
      return str if secs == 0
      str += " and "
    str += secs + " second"
    str += "s" if secs > 0  
    return str


app.filter 'round_up', ->
  (number, interval) ->
    result = number / interval
    result = parseInt(result)
    result = result * interval
    if (number % interval) > 0
      result = result + interval
    return result


# Usage:
# day in days | exclude_days : ['Saturday','Sunday']
app.filter 'exclude_days', ->
  (days, excluded) ->
    _.filter days, (day) ->
      excluded.indexOf(day.date.format('dddd')) == -1


# US phone formatter
# http://stackoverflow.com/questions/12700145/how-to-format-a-telephone-number-in-angularjs
app.filter "us_tel", ->
  (tel) ->
    return ""  unless tel
    value = tel.toString().trim().replace(/^\+/, "")
    return tel  if value.match(/[^0-9]/)
    country = undefined
    city = undefined
    number = undefined
    switch value.length
      when 10 # +1PPP####### -> C (PPP) ###-####
        country = 1
        city = value.slice(0, 3)
        number = value.slice(3)
      when 11 # +CPPP####### -> CCC (PP) ###-####
        country = value[0]
        city = value.slice(1, 4)
        number = value.slice(4)
      when 12 # +CCCPP####### -> CCC (PP) ###-####
        country = value.slice(0, 3)
        city = value.slice(3, 5)
        number = value.slice(5)
      else
        return tel
    country = ""  if country is 1
    number = number.slice(0, 3) + "-" + number.slice(3)
    (country + city + "-" + number).trim()


app.filter "uk_local_number", ->
  (tel) ->
    return ""  unless tel
    return tel.replace(/\+44 \(0\)/, '0')


# format datetime, expects moment object but will attempt to convert to
# moment object
# TODO get timezone from company
app.filter "datetime", ->
  (datetime, format, show_timezone = true) ->

    return if !datetime

    datetime = moment(datetime)
    return if !datetime.isValid()

    result = datetime.format(format)

    # if the dates time zone is different to the users, show the timezone too
    if datetime.zone() != new Date().getTimezoneOffset() && show_timezone
      if datetime._z
        result += datetime.format(" z") 
      else
        result += " UTC" + datetime.format("Z") 

    return result


app.filter 'range', ->
  (input, min, max) ->
    (input.push(i) for i in [parseInt(min)..parseInt(max)])
    input


app.filter 'international_number', () ->
  (number, prefix) =>
    if number and prefix
      return "#{prefix} #{number}" 
    else if number
      return "#{number}"
    else
      return ""


app.filter "startFrom", ->
  (input, start) ->
    if input is `undefined`
      input
    else
      input.slice +start


app.filter 'add', ->
  (item, value) =>
    if item and value
      item = parseInt(item)
      return item + value

app.filter 'spaces_remaining', () ->
  (spaces) ->
    if spaces < 1
      return 0
    else 
      return spaces

app.filter 'key_translate', ->
  (input) ->
    upper_case = angular.uppercase(input)
    remove_punctuations = upper_case.replace(/[\.,-\/#!$%\^&\*;:{}=\-_`~()]/g,"")
    add_underscore = remove_punctuations.replace(/\ /g, "_")
    return add_underscore