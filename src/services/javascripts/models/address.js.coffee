'use strict';

angular.module('BB.Models').factory "Admin.AddressModel", ($q, BBModel, BaseModel, AddressModel) ->

  class Admin_Address extends AddressModel


    distanceFrom: (address, options) ->

      @dists ||= []
      @dists[address] ||= Math.round(Math.random() * 50, 0)
      return @dists[address]