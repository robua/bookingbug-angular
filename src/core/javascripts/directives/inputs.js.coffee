'use strict';

# Directives
app = angular.module 'BB.Directives'


app.directive 'bbQuestionLine', ($compile) ->
  transclude: false,
  restrict: 'A',
  link: (scope, element, attrs) ->
    if scope.question.detail_type == "heading"
      elm = ""
      if scope.question.name.length > 0
        elm += "<div class='bb-question-heading'>" + scope.question.name + "</div>"
      if scope.question.help_text && scope.question.help_text.length > 0
        elm += "<div class='bb-question-help-text'>" + scope.question.help_text + "</div>"
      element.html(elm)

    # are we using a completely custom question
    if scope.idmaps and ((scope.idmaps[scope.question.detail_type] and scope.idmaps[scope.question.detail_type].block) or 
      (scope.idmaps[scope.question.id] && scope.idmaps[scope.question.id].block))
        index = if scope.idmaps[scope.question.id] then scope.question.id else scope.question.detail_type
        html = scope.$parent.idmaps[index].html
        e = $compile(html) scope, (cloned, scope) =>
          element.replaceWith(cloned)


app.directive 'bbQuestion', ($compile, $timeout) ->
  priority: 0,
  replace: true,
  transclude: false,
  restrict: 'A',
  compile: (el,attr,trans) ->
      pre: (scope, element, attrs) ->
        adminRequired = attrs.bbAdminRequired ? false
        
        scope.$watch attrs.bbQuestion, (question) ->
          if question
            html = ''
            lastName = ''
            
            scope.recalc = () =>
              if angular.isDefined(scope.recalc_price)
                scope.recalc_price() if !question.outcome
              if angular.isDefined(scope.recalc_question)
                scope.recalc_question()

            # are we using a completely custom question
            if scope.idmaps and (scope.idmaps[question.detail_type] or scope.idmaps[question.id])
              index = if scope.idmaps[scope.question.id] then scope.question.id else scope.question.detail_type
              html = scope.idmaps[index].html

            else if question.detail_type is "select" || question.detail_type is "select-price"
              html = "<select ng-model='question.answer' name='q#{question.id}' id='#{question.id}' ng-change='recalc()' ng-required='question.currentlyShown && (#{adminRequired} || (question.required && !bb.isAdmin))' class='form-question form-control'>"
              for itemx in question.options
                html += "<option data_id='#{itemx.id}' value='#{itemx.name}'>#{itemx.display_name}</option>"
              html += "</select>"

            else if question.detail_type is "text_area"
              html = "<textarea ng-model='question.answer' name='q#{question.id}' id='#{question.id}' ng-required='question.currentlyShown && (#{adminRequired} || (question.required && !bb.isAdmin))' rows=3 class='form-question form-control'>#{question['answer']}</textarea>"

            else if question.detail_type is "radio"
              html = '<div class="radio-group">'
              for itemx in question.options
                html += "<div class='radio'><label class='radio-label'><input ng-model='question.answer' name='q#{question.id}' id='#{question.id}' ng-change='recalc()' ng-required='question.currentlyShown && (#{adminRequired} || (question.required && !bb.isAdmin))' type='radio' value=\"#{itemx.name}\"/>#{itemx.name}</label></div>"
              html += "</div>"

            else if question.detail_type is "check"
              # stop the duplication of question names for muliple checkboxes by
              # checking the question name against the previous question name.
              name = question.name
              if name is lastName
                name = ""
              lastName = question.name
              html = "<div class='checkbox' ng-class='{\"selected\": question.answer}'><label><input name='q#{question.id}' id='#{question.id}' ng-model='question.answer' ng-checked='question.answer == \"1\"' ng-change='recalc()' ng-required='question.currentlyShown && (#{adminRequired} || (question.required && !bb.isAdmin))' type='checkbox' value=1>#{name}</label></div>"

            else if question.detail_type is "check-price"
              html = "<div class='checkbox'><label><input name='q#{question.id}' id='#{question.id}' ng-model='question.answer' ng-checked='question.answer == \"1\"' ng-change='recalc()' ng-required='question.currentlyShown && (#{adminRequired} || (question.required && !bb.isAdmin))' type='checkbox' value=1> ({{question.price | currency:'GBP'}})</label></div>"

            else if question.detail_type is "date"
              html = "
                <div class='input-group date-picker'>
                  <input type='text' class='form-question form-control' name='q#{question.id}' id='#{question.id}' bb-datepicker-popup='DD/MM/YYYY' datepicker-popup='dd/MM/yyyy' ng-model='question.answer' ng-required='question.currentlyShown && (#{adminRequired} || (question.required && !bb.isAdmin))' datepicker-options='{\"starting-day\": 1}' show-weeks='false' show-button-bar='false' is-open='opened' />
                  <span class='input-group-btn' ng-click='$event.preventDefault();$event.stopPropagation();opened=true'>
                    <button class='btn btn-default' type='submit'><span class='glyphicon glyphicon-calendar'></span></button>
                  </span>
                </div>"

            else
              html = "<input type='text' ng-model='question.answer' name='q#{question.id}' id='#{question.id}' ng-required='question.currentlyShown && (#{adminRequired} || (question.required && !bb.isAdmin))' class='form-question form-control'/>"

            if html
              e = $compile(html) scope, (cloned, scope) =>
                element.replaceWith(cloned)
      ,
      post: (scope, $e, $a, parentControl) ->



app.directive 'bbQuestionSetup', ->
  restrict: 'A'
  terminal: true
  priority: 1000

  link: (scope, element, attrs) ->
    idmaps = {}
    def = null
    for child, index in element.children()
      id = $(child).attr("bb-question-id")
      block = false
      if $(child).attr("bb-replace-block")
        block = true
      # replace form name with something unique to ensure custom questions get registered
      # with the form controller and subjected to validation
      child.innerHTML = child.innerHTML.replace(/question_form/g, "question_form_#{index}")
      idmaps[id] = {id: id, html: child.innerHTML, block: block}
    scope.idmaps = idmaps
    element.replaceWith("")


# Directive for testing if a input is focused
# Provided by http://www.ng-newsletter.com/posts/validations.html
app.directive "bbFocus", [->
    FOCUS_CLASS = "bb-focused"
    {
      restrict: "A",
      require: "ngModel",
      link: (scope, element, attrs, ctrl) ->
        ctrl.$focused = false
        element.bind("focus", (evt) ->
          element.addClass FOCUS_CLASS
          scope.$apply ->
            ctrl.$focused = true

        ).bind "blur", (evt) ->
          element.removeClass FOCUS_CLASS
          scope.$apply ->
            ctrl.$focused = false
    }
]


# Min/Max directives for use with number inputs
# Although angular provides min/max directives when using a HTML number input, the control does not validate if the field is actually a number
# so we have to use a text input with a ng-pattern that only allows numbers.
# http://jsfiddle.net/g/s5gKC/

isEmpty = (value) ->
  angular.isUndefined(value) or value is "" or value is null or value isnt value

app.directive "ngMin", ->
  restrict: "A"
  require: "ngModel"
  link: (scope, elem, attr, ctrl) ->
    scope.$watch attr.ngMin, ->
      ctrl.$setViewValue ctrl.$viewValue
      return

    minValidator = (value) ->
      min = scope.$eval(attr.ngMin) or 0
      if not isEmpty(value) and value < min
        ctrl.$setValidity "ngMin", false
        `undefined`
      else
        ctrl.$setValidity "ngMin", true
        value

    ctrl.$parsers.push minValidator
    ctrl.$formatters.push minValidator
    return

app.directive "ngMax", ->
  restrict: "A"
  require: "ngModel"
  link: (scope, elem, attr, ctrl) ->
    scope.$watch attr.ngMax, ->
      ctrl.$setViewValue ctrl.$viewValue
      return

    maxValidator = (value) ->
      max = scope.$eval(attr.ngMax) # or Infinity
      if not isEmpty(value) and value > max
        ctrl.$setValidity "ngMax", false
        `undefined`
      else
        ctrl.$setValidity "ngMax", true
        value

    ctrl.$parsers.push maxValidator
    ctrl.$formatters.push maxValidator
    return


app.directive "creditCardNumber", ->

  getCardType = (ccnumber) ->
    return '' unless ccnumber
    ccnumber = ccnumber.toString().replace(/\s+/g, '')
    if /^(34)|^(37)/.test(ccnumber)
      return "american_express"
    if /^(62)|^(88)/.test(ccnumber)
      return "china_unionpay"
    if /^30[0-5]/.test(ccnumber)
      return "diners_club_carte_blanche"
    if /^(2014)|^(2149)/.test(ccnumber)
      return "diners_club_enroute"
    if /^36/.test(ccnumber)
      return "diners_club_international"
    if /^(6011)|^(622(1(2[6-9]|[3-9][0-9])|[2-8][0-9]{2}|9([01][0-9]|2[0-5])))|^(64[4-9])|^65/.test(ccnumber)
      return "discover"
    if /^35(2[89]|[3-8][0-9])/.test(ccnumber)
      return "jcb"
    if /^(6304)|^(6706)|^(6771)|^(6709)/.test(ccnumber)
      return "laser"
    if /^(5018)|^(5020)|^(5038)|^(5893)|^(6304)|^(6759)|^(6761)|^(6762)|^(6763)|^(0604)/.test(ccnumber)
      return "maestro"
    if /^5[1-5]/.test(ccnumber)
      return "master"
    if /^4/.test(ccnumber)
      return "visa"
    if /^(4026)|^(417500)|^(4405)|^(4508)|^(4844)|^(4913)|^(4917)/.test(ccnumber)
      return "visa_electron"

  isValid = (ccnumber) ->
    return false unless ccnumber
    ccnumber = ccnumber.toString().replace(/\s+/g, '')
    len = ccnumber.length
    mul = 0
    prodArr = [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9], [0, 2, 4, 6, 8, 1, 3, 5, 7, 9]]
    sum = 0
    while len--
      sum += prodArr[mul][parseInt(ccnumber.charAt(len), 10)]
      mul ^= 1
    return (sum % 10 == 0 && sum > 0)

  linker = (scope, element, attributes, ngModel) ->
    scope.$watch () ->
      ngModel.$modelValue
    , (newValue) ->
      ngModel.$setValidity 'card_number', isValid(newValue)
      scope.cardType = getCardType(newValue)
      if newValue? && newValue.length == 16
        if ngModel.$invalid
          element.parent().addClass 'has-error'
          element.parent().removeClass 'has-success'
        else
          element.parent().removeClass 'has-error'
          element.parent().addClass 'has-success'
      else
        element.parent().removeClass 'has-success'

  return {
    restrict: "C"
    require: "ngModel"
    link: linker
    scope: {
      'cardType': '='
    }
  }

app.directive "cardSecurityCode", ->

  linker = (scope, element, attributes) ->
    scope.$watch 'cardType', (newValue) ->
      if newValue == 'american_express'
        element.attr('maxlength', 4)
        element.attr('placeholder', "••••")
      else
        element.attr('maxlength', 3)
        element.attr('placeholder', "•••")

  return {
    restrict: "C"
    link: linker
    scope: {
      'cardType': '='
    }
  }

# bbInputGroupManager
# Allows you you register inputs
app.directive 'bbInputGroupManager', (ValidatorService) ->
  restrict: 'A'
  controller: ($scope, $element, $attrs) ->
    #$scope.
    $scope.input_manger = {

      input_groups: {}
      inputs      : []

      registerInput: (input, name) ->

        # return if the input has already been registered
        return if @inputs.indexOf(input.$name) >= 0

        @inputs.push(input.$name)

        # group the input by the name provided
        if not @input_groups[name]
          @input_groups[name] = {
            inputs : [],
            valid  : false
          } 

        @input_groups[name].inputs.push(input)

      validateInputGroup: (name) ->
        is_valid = false
        for input in @input_groups[name].inputs
          is_valid = input.$modelValue
          break if is_valid

        if is_valid is not @input_groups[name].valid 

          for input in @input_groups[name].inputs
            input.$setValidity(input.$name,is_valid)

          @input_groups[name].valid = is_valid
          
    }

    # on form submit, validate all input groups
    $element.on "submit", ->  
      for input_group of $scope.input_manger.input_groups
        $scope.input_manger.validateInputGroup(input_group)


app.directive "bbInputGroup", () ->
  restrict: "A",
  require: 'ngModel',
  link: (scope, elem, attrs, ngModel) ->

    # return if the input has already been registered
    return if scope.input_manger.inputs.indexOf(ngModel.$name) >= 0

    # register the input
    scope.input_manger.registerInput(ngModel, attrs.bbInputGroup)

    # watch the input for changes
    scope.$watch attrs.ngModel, (newval, oldval) ->
      scope.input_manger.validateInputGroup(attrs.bbInputGroup) if newval is not oldval




app.directive 'bbQuestionLabel', ($compile) ->
  transclude: false,
  restrict: 'A',
  scope: false,
  link: (scope, element, attrs) ->
    scope.$watch attrs.bbQuestionLabel, (question) ->
      if question
        if question.detail_type == "check" || question.detail_type == "check-price"
          element.html("")





app.directive 'bbQuestionLabel', ($compile) ->
  transclude: false,
  restrict: 'A',
  scope: false,
  link: (scope, element, attrs) ->
    scope.$watch attrs.bbQuestionLabel, (question) ->
      if question
        if question.detail_type == "check" || question.detail_type == "check-price"
          element.html("")




app.directive 'bbQuestionLink', ($compile) ->
  transclude: false,
  restrict: 'A',
  scope: true,
  link: (scope, element, attrs) ->
    id = parseInt(attrs.bbQuestionLink)
    scope.$watch "question_set", (newval, oldval) ->
      if newval
        for q in scope.question_set
          if q.id == id
            scope.question = q
            element.attr('ng-model',"question.answer")
            element.attr('bb-question-link',null)
            $compile(element)(scope)


app.directive 'bbQuestionSet', ($compile) ->
  transclude: false,
  restrict: 'A',
  scope: true,
  link: (scope, element, attrs) ->
    set = attrs.bbQuestionSet
    element.addClass 'ng-hide'
    scope.$watch set, (newval, oldval) ->
      if newval
        scope.question_set = newval
        element.removeClass 'ng-hide'


# Input match test
app.directive "bbMatchInput", ->
  restrict: "A"
  require: 'ngModel'
  link: (scope, element, attrs, ctrl, ngModel) ->

    scope.$watch attrs.bbMatchInput, ->
      scope.val_1 = scope.$eval(attrs.bbMatchInput)
      compare(ctrl.$viewValue)

    compare = (value) ->
      ctrl.$setValidity 'match', scope.val_1 is value

    ctrl.$parsers.push compare
