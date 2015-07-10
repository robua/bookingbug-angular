

angular.module('BB.Services').factory "BB.Service.address", ($q, BBModel) ->
  unwrap: (resource) ->
    return new BBModel.Address(resource)


angular.module('BB.Services').factory "BB.Service.person", ($q, BBModel) ->
  unwrap: (resource) ->
    return new BBModel.Person(resource)


angular.module('BB.Services').factory "BB.Service.people", ($q, BBModel) ->
  promise: true
  unwrap: (resource) ->
    deferred = $q.defer()
    resource.$get('people').then (items) =>
      models = []
      for i in items
        models.push(new BBModel.Person(i))
      deferred.resolve(models)
    , (err) =>
      deferred.reject(err)

    deferred.promise


angular.module('BB.Services').factory "BB.Service.resource", ($q, BBModel) ->
  unwrap: (resource) ->
    return new BBModel.Resource(resource)


angular.module('BB.Services').factory "BB.Service.resources", ($q, BBModel) ->
  promise: true
  unwrap: (resource) ->
    deferred = $q.defer()
    resource.$get('resources').then (items) =>
      models = []
      for i in items
        models.push(new BBModel.Resource(i))
      deferred.resolve(models)
    , (err) =>
      deferred.reject(err)

    deferred.promise



angular.module('BB.Services').factory "BB.Service.service", ($q, BBModel) ->
  unwrap: (resource) ->
    return new BBModel.Service(resource)


angular.module('BB.Services').factory "BB.Service.services", ($q, BBModel) ->
  promise: true
  unwrap: (resource) ->
    deferred = $q.defer()
    resource.$get('services').then (items) =>
      models = []
      for i in items
        models.push(new BBModel.Service(i))
      deferred.resolve(models)
    , (err) =>
      deferred.reject(err)

    deferred.promise


angular.module('BB.Services').factory "BB.Service.event_group", ($q, BBModel) ->
  unwrap: (resource) ->
    return new BBModel.EventGroup(resource)


angular.module('BB.Services').factory "BB.Service.event_groups", ($q, BBModel) ->
  promise: true
  unwrap: (resource) ->
    deferred = $q.defer()
    resource.$get('event_groups').then (items) =>
      models = []
      for i in items
        models.push(new BBModel.EventGroup(i))
      deferred.resolve(models)
    , (err) =>
      deferred.reject(err)

    deferred.promise


angular.module('BB.Services').factory "BB.Service.event_chain", ($q, BBModel) ->
  unwrap: (resource) ->
    return new BBModel.EventChain(resource)


angular.module('BB.Services').factory "BB.Service.category", ($q, BBModel) ->
  unwrap: (resource) ->
    return new BBModel.Category(resource)


angular.module('BB.Services').factory "BB.Service.categories", ($q, BBModel) ->
  promise: true
  unwrap: (resource) ->
    deferred = $q.defer()
    resource.$get('categories').then (items) =>
      models = []
      for i in items
        cat = new BBModel.Category(i)
        cat.order ||= _i
        models.push(cat)
      deferred.resolve(models)
    , (err) =>
      deferred.reject(err)

    deferred.promise


angular.module('BB.Services').factory "BB.Service.client", ($q, BBModel) ->
  unwrap: (resource) ->
    return new BBModel.Client(resource)


angular.module('BB.Services').factory "BB.Service.child_clients", ($q, BBModel) ->
  promise: true
  unwrap: (resource) ->
    deferred = $q.defer()
    resource.$get('clients').then (items) =>
      models = []
      for i in items
        models.push(new BBModel.Client(i))
      deferred.resolve(models)
    , (err) =>
      deferred.reject(err)

    deferred.promise

angular.module('BB.Services').factory "BB.Service.clients", ($q, BBModel) ->
  promise: true
  unwrap: (resource) ->
    deferred = $q.defer()
    resource.$get('clients').then (items) =>
      models = []
      for i in items
        models.push(new BBModel.Client(i))
      deferred.resolve(models)
    , (err) =>
      deferred.reject(err)

    deferred.promise


angular.module('BB.Services').factory "BB.Service.questions", ($q, BBModel) ->
  unwrap: (resource) ->
    if resource.questions
      (new BBModel.Question(i) for i in resource.questions)
    else if resource.$has('questions')
      defer = $q.defer()
      resource.$get('questions').then (items) ->
        defer.resolve((new BBModel.Question(i) for i in items))
      , (err) ->
        defer.reject(err)
      defer.promise
    else
      (new BBModel.Question(i) for i in resource)


angular.module('BB.Services').factory "BB.Service.question", ($q, BBModel) ->
  unwrap: (resource) ->
    return new BBModel.Question(resource)


angular.module('BB.Services').factory "BB.Service.answers", ($q, BBModel) ->
  promise: false
  unwrap: (items) ->
    models = []
    for i in items
      models.push(new BBModel.Answer(i))
    answers =
      answers: models

      getAnswer: (question) ->
        for a in @answers
          return a.value if a.question_text is question or a.question_id is question

    return answers


angular.module('BB.Services').factory "BB.Service.administrators", ($q, BBModel) ->
  unwrap: (items) ->
    new BBModel.Admin.User(i) for i in items


angular.module('BB.Services').factory "BB.Service.company", ($q, BBModel) ->
  unwrap: (resource) ->
    return new BBModel.Company(resource)


angular.module('BB.Services').factory "BB.Service.event_chains", ($q, BBModel) ->
  promise: true
  unwrap: (resource) ->
    return new BBModel.EventChain(resource)


angular.module('BB.Services').factory "BB.Service.parent", ($q, BBModel) ->
  unwrap: (resource) ->
    return new BBModel.Company(resource)
    
    
angular.module('BB.Services').factory "BB.Service.company_questions", ($q, BBModel) ->
  promise: true
  unwrap: (resource) ->
    deferred = $q.defer()
    resource.$get('company_questions').then (items) =>
      models = []
      for i in items
        models.push(new BBModel.BusinessQuestion(i))
      deferred.resolve(models)
    , (err) =>
      deferred.reject(err)

    deferred.promise


angular.module('BB.Services').factory "BB.Service.company_question", ($q, BBModel) ->
  unwrap: (resource) ->
    return new BBModel.BusinessQuestion(resource)


angular.module('BB.Services').factory "BB.Service.images", ($q, BBModel) ->
  promise: true
  unwrap: (resource) ->
    deferred = $q.defer()
    resource.$get('images').then (items) =>
      models = []
      for i in items
        models.push(new BBModel.Image(i))
      deferred.resolve(models)
    , (err) =>
      deferred.reject(err)

    deferred.promise


angular.module('BB.Services').factory "BB.Service.bookings", ($q, BBModel) ->
  promise: true
  unwrap: (resource) ->
    deferred = $q.defer()
    resource.$get('bookings').then (items) =>
      models = []
      for i in items
        models.push(new BBModel.Member.Booking(i))
      deferred.resolve(models)
    , (err) =>
      deferred.reject(err)

    deferred.promise
