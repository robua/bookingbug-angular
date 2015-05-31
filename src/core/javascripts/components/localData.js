
angular.module('ngLocalData', ['angular-hal']).
 factory('$localCache', ['halClient', '$q', function( halClient, $q) {
    data = {};

    jsonData = function(data) {
        return data && JSON.parse(data);
    }

    storage = function()
    {
      return sessionStorage
    } 
    localSave = function(key, item){
      storage().setItem(key, item.$toStore())   
    } 
    localLoad = function(key){
      res =  jsonData(storage().getItem(key))
      if (res)
      {  
        r = halClient.createResource(res)
        def = $q.defer()
        def.resolve(r)
        return def.promise
      }
      return null
    } 
    localDelete = function(key) {
      storage().removeItem(key)
    }

    return {

      set: function(key, val)
      {
        data[key] = val
        val.then(function(item){
          localSave(key, item)
        })
        return val
      },
      get: function(key)
      {
        localLoad(key)
        if (!data[key])
          data[key] = localLoad(key)
        return data[key]
      },
      del: function(key)
      {
        localDelete(key)
        delete data[key]
      },
      has: function(key)
      {
        if (!data[key])
        { 
          res = localLoad(key)
          if (res)
            data[key] = res
        }
        return (key in data)
      }      
    }

}]).
 factory('$localData', ['$http', '$rootScope', function($http, $rootScope) {
    function LocalDataFactory(name) {
      function LocalData(value){
        this.setStore(value);
      }

      LocalData.prototype.jsonData = function(data) {
          return data && JSON.parse(data);
      }

      LocalData.prototype.storage = function()
      {
        return sessionStorage
      }  

      LocalData.prototype.localSave = function(item)
      {
        this.storage().setItem(this.store_name + item.id, JSON.stringify(item))
      }


      LocalData.prototype.localSaveIndex = function(ids)
      {
        this.storage().setItem(this.store_name, ids.join(","))
        this.ids = ids;
      }

      LocalData.prototype.localLoadIndex = function()
      {
        store = this.storage().getItem(this.store_name)
        records = (store && store.split(",")) || [];
        return records
      }

      LocalData.prototype.localLoad = function( id)
      {
        return this.jsonData(this.storage().getItem(this.store_name + id))
      }

      LocalData.prototype.count = function()
      {
        return this.ids.length
      }

      LocalData.prototype.setStore = function(name)
      {
        this.store_name = name;
        this.data_store = []
        this.ids = this.localLoadIndex();
        for (a = 0; a < this.ids.length; a++){
          this.data_store.push(this.localLoad(this.ids[a]));
        }
    //    var channel = pusher.subscribe(name);
    //    var ds = this;

     //   channel.bind('add', function(data) {
     //     ds.data_store.push(data);
     //     $rootScope.$broadcast("Refresh_" + ds.store_name, "Updated");          
     //   });

      }

      LocalData.prototype.update = function(data)
      {
        ids = []
        for (x in data){
          if (data[x].id){
           ids.push(data[x].id)
           this.localSave(data[x])
         }
        }
        this.localSaveIndex(ids)
      }

      return new LocalData(name)

    };


    
    return LocalDataFactory
}]);
