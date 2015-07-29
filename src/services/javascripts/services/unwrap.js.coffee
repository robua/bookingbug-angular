
angular.module('BB.Services').factory "BB.Service.schedule", ($q, BBModel) ->
  unwrap: (resource) ->
    return new BBModel.Admin.Schedule(resource)