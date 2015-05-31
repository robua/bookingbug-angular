
angular.module('BB.Directives').directive 'bbClientDetails', () ->
  restrict: 'AE'
  replace: true
  scope : true
  controller : 'ClientDetails'

angular.module('BB.Controllers').controller 'ClientDetails', ($scope,  $rootScope, ClientDetailsService, ClientService, LoginService, BBModel, ValidatorService, QuestionService, AlertService) ->
  $scope.controller = "public.controllers.ClientDetails"
  $scope.notLoaded $scope
  $scope.validator = ValidatorService
  $scope.existing_member = false
  $scope.login_error = false
  
  $rootScope.connection_started.then =>

    if !$scope.client.valid() && LoginService.isLoggedIn()
      # make sure we set the client to the currently logged in member
      # we should also jsut check the logged in member is  a member of the company they are currently booking with
      $scope.setClient(new BBModel.Client(LoginService.member()._data))

    if LoginService.isLoggedIn() && LoginService.member().$has("child_clients") && LoginService.member()
      LoginService.member().getChildClientsPromise().then (children) =>
        $scope.bb.parent_client = new BBModel.Client(LoginService.member()._data)
        $scope.bb.child_clients = children
        $scope.bb.basket.parent_client_id = $scope.bb.parent_client.id

    if $scope.client.client_details
      $scope.client_details = $scope.client.client_details
      QuestionService.checkConditionalQuestions($scope.client_details.questions) if $scope.client_details.questions
      $scope.setLoaded $scope
    else 
      ClientDetailsService.query($scope.bb.company).then (details) =>
        $scope.client_details = details
        $scope.client.pre_fill_answers($scope.client_details) if $scope.client
        QuestionService.checkConditionalQuestions($scope.client_details.questions) if $scope.client_details.questions
        $scope.setLoaded $scope
      , (err) ->  $scope.setLoadedAndShowError($scope, err, 'Sorry, something went wrong')

  , (err) ->  $scope.setLoadedAndShowError($scope, err, 'Sorry, something went wrong')


  $rootScope.$watch 'member', (oldmem, newmem) =>
    if !$scope.client.valid() && LoginService.isLoggedIn()
      $scope.setClient(new BBModel.Client(LoginService.member()._data))


  $scope.validateClient = (client_form, route) =>
    $scope.notLoaded $scope
    $scope.existing_member = false

    # we need to validate teh client information has been correctly entered here
    if $scope.bb && $scope.bb.parent_client
      $scope.client.parent_client_id = $scope.bb.parent_client.id
    $scope.client.setClientDetails($scope.client_details)

    ClientService.create_or_update($scope.bb.company, $scope.client).then (client) =>
      $scope.setLoaded $scope
      $scope.setClient(client)
      $scope.client.setValid(true) if $scope.bb.isAdmin
      $scope.existing_member = false
      $scope.decideNextPage(route)
    , (err) ->
      if err.data.error == "Please Log in" 
        $scope.existing_member = true
        AlertService.danger({msg: "You have already registered with this email address. Please log in or reset your password using the Forgot Password link below."})
      $scope.setLoaded $scope

  $scope.clientLogin = () =>
    $scope.login_error = false
    if $scope.login
      LoginService.companyLogin($scope.bb.company, {}, {email: $scope.login.email, password: $scope.login.password}).then (client) =>
        $scope.setClient(new BBModel.Client(client))
        $scope.login_error = false
        $scope.decideNextPage()
      , (err) ->
        $scope.login_error = true
        $scope.setLoaded $scope
        AlertService.danger({msg: "Sorry, your email or password was not recognised. Please try again."})

  $scope.setReady = () =>
    $scope.client.setClientDetails($scope.client_details)

    ClientService.create_or_update($scope.bb.company, $scope.client).then (client) =>
      $scope.setLoaded $scope

      $scope.setClient(client)
      if client.waitingQuestions
        client.gotQuestions.then () ->
          $scope.client_details = client.client_details
     
    , (err) ->  $scope.setLoadedAndShowError($scope, err, 'Sorry, something went wrong')

    return true


  $scope.clientSearch = () ->
    if $scope.client? && $scope.client.email? && $scope.client.email != ""
      $scope.notLoaded $scope
      ClientService.query_by_email($scope.bb.company, $scope.client.email).then (client) ->
        if client?
          $scope.setClient(client)
          $scope.client = client
        $scope.setLoaded $scope
      , (err) ->
        $scope.setLoaded $scope
    else
      $scope.setClient({})
      $scope.client = {}


  $scope.switchNumber = (to) ->
    $scope.no_mobile = !$scope.no_mobile
    if to == 'mobile'
      $scope.bb.basket.setSettings({send_sms_reminder: true})
      $scope.client.phone = null
    else
      $scope.bb.basket.setSettings({send_sms_reminder: false})
      $scope.client.mobile = null


  $scope.getQuestion = (id) ->
    for question in $scope.client_details.questions
      return question if question.id == id

    return null

  $scope.useClient = (client) ->
    $scope.setClient(client)
    

  $scope.recalc_question = () ->
    QuestionService.checkConditionalQuestions($scope.client_details.questions) if $scope.client_details.questions