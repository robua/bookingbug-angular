
angular
.module('angular-hal', []).provider('data_cache', function() {
 
    this.$get = function() {
      data = [];

      return {

        set: function(key, val)
        {
          data[key] = val
          return val
        },
        get: function(key)
        {
          return data[key]
        },
        del: function(key)
        {
          delete data[key]
        },
        has: function(key)
        {
          return (key in data)
        },
        delMatching: function(str)
        {
          for (var k in data) {      
            if (k.indexOf(str) != -1)
              delete data[k]
          }
        }

      }
    };
 
})
.provider('shared_header', function() {
   this.$get = function() {
      data = {};

      return {

        set: function(key, val)
        {
          // also store this in the session store
          sessionStorage.setItem(key, val)
          data[key] = val
          return val
        },
        get: function(key)
        {
          return data[key]
        },
        del: function(key)
        {
          delete data[key]
        },
        has: function(key)
        {
          return (key in data)
        }
      }
    };

})
.factory('halClient', [
  '$http', '$q', 'data_cache', 'shared_header', 'UriTemplate', function(
    $http, $q, data_cache, shared_header, UriTemplate
  ){
    return {
      setCache: function(cache) {
        data_cache = cache
      },
      clearCache: function(str) {
        data_cache.delMatching(str)
      },
      createResource: function(store)
      {
        if (typeof store === 'string') {
          store = JSON.parse(store)
        }
        resource = store.data
        resource._links = store.links
        key = store.links.self.href
        options = store.options
        return new BaseResource(key, options, resource)
      },
      $get: function(href, options){
        if(data_cache.has(href) && (!options || !options.no_cache)) return data_cache.get(href);
        return data_cache.set(href, callService('GET', href, options));
//        return callService('GET', href, options);
      }//get
      , $post: function(href, options, data){
        return callService('POST', href, options, data);
      }//post
      , $put: function(href, options, data){
        return callService('PUT', href, options, data);
      }//put
      , $patch: function(href, options, data){
        return callService('PATCH', href, options, data);
      }//patch
      , $del: function(href, options){
        return callService('DELETE', href, options);
      }//del
      , $parse: function(data){
        return parseHal(data)
      }//parse
    };
  
    function BaseResource(href, options, data){
      if(!options) options = {};
      var links = {};
      var embedded = data_cache
      if (data.hasOwnProperty('auth_token')) {
        options['auth_token'] = data['auth_token'];
      }

      href = getSelfLink(href, data).href;

      defineHiddenProperty(this, '$href', function(rel, params) {
        if(!(rel in links)) return null;

        return hrefLink(links[rel], params);
      });
      defineHiddenProperty(this, '$has', function(rel) {
        return rel in links;
      });
      defineHiddenProperty(this, '$flush', function(rel, params) {
        var link = links[rel];
        return flushLink(link, params);
      });
      defineHiddenProperty(this, '$get', function(rel, params){
        var link = links[rel];
        return callLink('GET', link, params);
      });
      defineHiddenProperty(this, '$post', function(rel, params, data){
        var link = links[rel];
        return callLink('POST', link, params, data);
      });
      defineHiddenProperty(this, '$put', function(rel, params, data){
        var link = links[rel];
        return callLink('PUT', link, params, data);
      });
      defineHiddenProperty(this, '$patch', function(rel, params, data){
        var link = links[rel];
        return callLink('PATCH', link, params, data);
      });
      defineHiddenProperty(this, '$del', function(rel, params){
        var link = links[rel];
        return callLink('DELETE', link, params);
      });
      defineHiddenProperty(this, '$links', function(){
        return links
      });
      defineHiddenProperty(this, '$toStore', function(){
        return JSON.stringify({data: this, links: links, options:options})
      });
      defineHiddenProperty(this, 'setOption', function(key, value){
        options[key] = value
      });
      defineHiddenProperty(this, 'getOption', function(key){
        return options[key]
      });
      defineHiddenProperty(this, '$link', function(rel){
        return links[rel]
      });

      Object.keys(data)
      .filter(function(key){
        return !~['_', '$'].indexOf(key[0]);
      })
      .forEach(function(key){
        this[key] = data[key]
//        Object.defineProperty(this, key, {
  //        configurable: false
  //        , enumerable: true
  //        , value: data[key]
   //     });
      }, this)
      ;


      if(data._links) {
        Object
        .keys(data._links)
        .forEach(function(rel){
          var link = data._links[rel];          
          link = normalizeLink(href, link);
          links[rel] = link;
        }, this)
        ;
      }

      if(data._embedded) {
        Object
        .keys(data._embedded)
        .forEach(function(rel){
          var embedded = data._embedded[rel];
          var link = getSelfLink(href, embedded);
          links[rel] = link;

          var resource = createResource(href, options, embedded);

          embedResource(resource);

        }, this);
      }

      function defineHiddenProperty(target, name, value) {
        target[name] = value
//        Object.defineProperty(target, name, {
//          configurable: false
 //         , enumerable: false
  //        , value: value
   //     });
      }//defineHiddenProperty


      function embedResource(resource) {
        if(angular.isArray(resource)) return resource.map(function(resource){
          return embedResource(resource);
        });
        
        var href = resource.$href('self');

        embedded.set(href, $q.when(resource));
      }//embedResource

      function hrefLink(link, params) {
        var href = link.templated
        ? new UriTemplate(link.href).fillFromObject(params || {})
        : link.href
        ;

        return href;
      }//hrefLink

      function callLink(method, link, params, data) {
        if(angular.isArray(link)) return $q.all(link.map(function(link){
          if(method !== 'GET') throw 'method is not supported for arrays';

          return callLink(method, link, params, data);
        }));

        var linkHref = hrefLink(link, params);
        if(method === 'GET') {
          if (params) {
            if (params.hasOwnProperty('no_cache')) {
              options['no_cache'] = params['no_cache'];
            }
          }
          if(embedded.has(linkHref) && (!options || !options.no_cache)) return embedded.get(linkHref);
          
          return embedded.set(linkHref, callService(method, linkHref, options, data));
        }
        else {
          return callService(method, linkHref, options, data);  
        }

      }//callLink

      function flushLink(link, params) {
        if(angular.isArray(link)) return link.map(function(link){
          return flushLink(link, params);
        });

        var linkHref = hrefLink(link, params);
        if(embedded.has(linkHref)) embedded.del(linkHref);
      }//flushLink

    }//Resource




    function createResource(href, options, data){
      if(angular.isArray(data)) return data.map(function(data){
        return createResource(href, options, data);
      });

      var resource = new BaseResource(href, options, data);

      return resource;

    }//createResource


    function normalizeLink(baseHref, link){
      if(angular.isArray(link)) return link.map(function(link){
        return normalizeLink(baseHref, link);
      });

      if(link) {
        if(typeof link === 'string') link = { href: link };
        link.href = resolveUrl(baseHref, link.href);
      }
      else {
        link = { href: baseHref };      
      }

      return link;
    }//normalizeLink


    function getSelfLink(baseHref, resource){
      if(angular.isArray(resource)) return resource.map(function(resource){
        return getSelfLink(baseHref, resource);
      });

      return normalizeLink(baseHref, resource && resource._links && resource._links.self);
    }//getSelfLink



    function callService(method, href, options, data){
      if(!options) options = {};
      headers = {
        'Authorization': options.authorization
        , 'Content-Type': 'application/json'
        , 'Accept': 'application/hal+json,application/json'
      }
      if (options.app_id) shared_header.set('app_id', options.app_id);
      if (options.app_key) shared_header.set('app_key', options.app_key);
      if (options.auth_token) {
        sessionStorage.setItem('auth_token', options.auth_token);
        shared_header.set('auth_token', options.auth_token);
      }

      if (shared_header.has('app_id')) headers['App-Id'] = shared_header.get('app_id');
      if (shared_header.has('app_key')) headers['App-Key'] = shared_header.get('app_key');
      if (shared_header.has('auth_token')) headers['Auth-Token'] = shared_header.get('auth_token');

      if (options.bypass_auth) headers['Bypass-Auth'] = options.bypass_auth;

      var resource = (
        $http({
          method: method
          , url: options.transformUrl ? options.transformUrl(href) : href
          , headers: headers
          , data: data
        })
        .then(function(res){

          // copy out the auth token from the header if there was one and make sure the child commands use it
          if (res.headers('auth-token') && res.status != 304){
            options.auth_token = res.headers('Auth-Token')
            shared_header.set('auth_token', res.headers('Auth-Token'))
          }
          switch(res.status){
            case 200:
            if(res.data) return createResource(href, options, res.data);
            return null;

            case 201:
            if(res.data) return createResource(href, options, res.data);
            if(res.headers('Content-Location')) return res.headers('Content-Location');
            return null;

            case 204:
            return null

            default:
            return $q.reject(res);
          }
        }, function(res)
        {
          return $q.reject(res);
        })
      );

      return resource;
    }//callService

    function parseHal(data){
      var resource = createResource(data._links.self.href, null, data);
      return resource;
    }//parseHal



    function resolveUrl(baseHref, href){
      var resultHref = '';
      var reFullUrl = /^((?:\w+\:)?)((?:\/\/)?)([^\/]*)((?:\/.*)?)$/;
      var baseHrefMatch = reFullUrl.exec(baseHref);
      var hrefMatch = reFullUrl.exec(href);

      for(var partIndex = 1; partIndex < 5; partIndex++) {
        if(hrefMatch[partIndex]) resultHref += hrefMatch[partIndex];
        else resultHref += baseHrefMatch[partIndex]
      }

      return resultHref;
    }//resolveUrl

  }
])//service
;
