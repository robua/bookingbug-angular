angular.module("BB.Models").factory "Member.WalletModel", (BBModel, BaseModel) ->

  class Member_Wallet extends BaseModel
    constructor: (data) ->
      super(data)