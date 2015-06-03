
angular.module('BBAdmin.Services').factory "AdminLoginService", ($q, halClient,
    $rootScope, BBModel, $sessionStorage, $cookies, UriTemplate) ->
 
  login: (form, options) ->
    deferred = $q.defer()
    url = "#{$rootScope.bb.api_url}/api/v1/login/admin"
    if (options? && options.company_id?)
      url = "#{url}/#{options.company_id}"
    
    halClient.$post(url, options, form).then (login) =>
      if login.$has('administrator')
        login.$get('administrator').then (user) =>
          user = @setLogin(user)
          deferred.resolve(user)
      else if login.$has('administrators')
        login_model = new BBModel.Admin.Login(login)
        deferred.resolve(login_model)
      else
        deferred.reject("No admin account for login")
    , (err) =>
      if err.status == 400
        login = halClient.$parse(err.data)
        if login.$has('administrators')
          login_model = new BBModel.Admin.Login(login)
          deferred.resolve(login_model)
        else
          deferred.reject(err)
      else
        deferred.reject(err)
    deferred.promise


  ssoLogin: (options, data) ->
    deferred = $q.defer()
    url = $rootScope.bb.api_url + "/api/v1/login/sso/" + options['company_id']

    halClient.$post(url, {}, data).then (login) =>
      params = {auth_token: login.auth_token}
      login.$get('user').then (user) =>
        user = @setLogin(user)
        deferred.resolve(user)
    , (err) =>
      deferred.reject(err)
    deferred.promise
      

  isLoggedIn: ->
    @checkLogin().then () ->
      if $rootScope.user
        true
      else
        false


  setLogin: (user) ->
    auth_token = user.getOption('auth_token')
    user = new BBModel.Admin.User(user)
    $sessionStorage.setItem("user", user.$toStore())
    $sessionStorage.setItem("auth_token", auth_token)
    $rootScope.user = user
    user

  user: () ->
    @checkLogin().then () ->
      $rootScope.user

  checkLogin: (params = {}) ->
    defer = $q.defer()
    defer.resolve() if $rootScope.user
    user = $sessionStorage.getItem("user")
    if user
      $rootScope.user = halClient.createResource(user)
      defer.resolve()
    else
      auth_token = $cookies['Auth-Token']
      if auth_token
        if $rootScope.bb.api_url
          url = "#{$rootScope.bb.api_url}/api/v1/login{?id,role}"
        else
          url = "/api/v1/login{?id,role}"
        params.id = params.companyId || params.company_id
        params.role = 'admin'
        href = new UriTemplate(url).fillFromObject(params || {})
        options = {auth_token: auth_token}
        halClient.$get(href, options).then (login) =>
          if login.$has('administrator')
            login.$get('administrator').then (user) ->
              $rootScope.user = new BBModel.Admin.User(user)
              defer.resolve()
          else
            defer.resolve()
        , () ->
          defer.resolve()
      else
        defer.resolve()
    defer.promise

  logout: () ->
    $rootScope.user = null
    $sessionStorage.removeItem("user")
    $sessionStorage.removeItem("auth_token")
    $cookies['Auth-Token'] = null

  getLogin: (options) ->
    defer = $q.defer()
    url = "#{$rootScope.bb.api_url}/api/v1/login/admin/#{options.company_id}"
    halClient.$get(url, options).then (login) =>
      if login.$has('administrator')
        login.$get('administrator').then (user) =>
          user = @setLogin(user)
          defer.resolve(user)
        , (err) ->
          defer.reject(err)
      else
        defer.reject()
    , (err) ->
      defer.reject(err)
    defer.promise

