angular.module('BB.Models').factory "Member.MemberModel", ($q, BBModel,
    BaseModel, ClientModel) ->

  class Member_Member extends ClientModel

    wallet: () ->
      if @$has("wallet")
        @$get("wallet").then (wallet) ->
          @wallet = wallet
          @wallet


