'use strict';

angular.module('BB.Services').factory 'QuestionService', ($window, QueryStringService, $bbug) ->
  
  # grab url params
  defaults = QueryStringService() or {}

  convertDates = (obj) ->
    _.each obj, (val, key) ->
      date = $window.moment(obj[key])
      if _.isString(obj[key]) and date.isValid()
        obj[key] = date


  #  store any values from $window.bb_setup if it exists
  if $window.bb_setup
    convertDates($window.bb_setup)
    angular.extend(defaults, $window.bb_setup)


  # adds an answer property to a question object if the id of the question
  # matches the id of the values stored in the defaults object. this would
  # almost defintiely be used to get values from the querystring i.e.
  # ?14393=Wedding&14392=true
  addAnswersById = (questions) ->
    if !questions
      return

    if angular.isArray questions
      _.each questions, (question) ->
        id = question.id + ''

        if !question.answer and defaults[id]
          question.answer = defaults[id]
    else
      
      questions.answer = defaults[questions.id + ''] if defaults[questions.id + '']



  # converts a string to a clean, snake case string. it's used to convert
  # question names into snake case so they can be accessed using the object dot
  # notation and match any values set using $window.bb_set_up
  convertToSnakeCase = (str) ->
    str = str.toLowerCase();
    str = $.trim(str)
    # replace all punctuation and special chars
    str = str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|'’!<>;:,.~`=+-@£&%"]/g, '')
    # replace any double or more spaces
    str = str.replace(/\s{2,}/g, ' ')
    # convert to sanke case
    str = str.replace(/\s/g, '_')
    return str


  # takes an array of questions objects. loops through the questions gettting
  # the obj.name value and converting it into snake case. then loop through the
  # stored value key name and see if there is whole or partial match.
  addDynamicAnswersByName = (questions) ->
    if angular.isArray questions
      keys = _.keys(defaults)

      _.each questions, (question) ->
        name = convertToSnakeCase(question.name)
        _.each keys, (key) ->
          if name.indexOf(key) >= 0
            if defaults[key] and !question.answer
              question.answer = defaults[key]
              delete defaults[key]
          return


  # takes an object and array of key names. it loops through key names and if
  # they match the key names in the stored values, then the values are added to
  # calling obj.
  addAnswersByName = (obj, keys) ->
    type = Object.prototype.toString.call(obj).slice(8,-1)

    if type is 'Object' and angular.isArray(keys)
      for key in keys
        # only add property to calling object if it doesn't have a property
        if defaults[key] and !obj[key]
          obj[key] = defaults[key]
          # remove it once it's set otherwise there could be a lot of issues
          delete defaults[key]
      return


  # takes an array of questions and an answers hash which then matches answers either
  # by thier key name and the questions help_text value or by question id
  addAnswersFromDefaults = (questions, answers) ->
    for question in questions
      name = question.help_text
      question.answer = answers[name] if answers[name]
      question.answer = answers[question.id + ''] if answers[question.id + ''] 


  storeDefaults = (obj) ->
    angular.extend(defaults, obj.bb_setup or {})


  checkConditionalQuestions = (questions) ->
    for q in questions
      if q.settings && q.settings.conditional_question
        cond = findByQuestionId(questions, parseInt(q.settings.conditional_question)) 
        if cond
          # check if the question has an answer which means "show"
          ans = cond.getAnswerId()
          found = false
          if $bbug.isEmptyObject(q.settings.conditional_answers) && cond.detail_type == "check" && !cond.answer
            # this is messy - we're showing the question when we ahve a checkbox conditional, based on it being unticked
            found = true

          for a,v of q.settings.conditional_answers
            if a[0] == 'c' && parseInt(v) == 1 && cond.answer
              found = true
            else if parseInt(a) == ans && parseInt(v) == 1
              found = true
          if found
            q.showElement()
          else
            q.hideElement()


  findByQuestionId = (questions, qid) ->
    for q in questions
      return q if q.id == qid
    return null


  return {
    getStoredData   : ->
      return defaults

    storeDefaults             : storeDefaults
    addAnswersById            : addAnswersById
    addAnswersByName          : addAnswersByName
    addDynamicAnswersByName   : addDynamicAnswersByName
    addAnswersFromDefaults    : addAnswersFromDefaults
    convertToSnakeCase        : convertToSnakeCase
    checkConditionalQuestions : checkConditionalQuestions
  }
