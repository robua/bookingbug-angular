angular.module('BBQueue.Services').factory 'PusherQueue', ($sessionStorage, $pusher, AppConfig) ->

  class PusherQueue

    @subscribe: (company) ->
      if company? && Pusher?
        unless @client?
          @client = new Pusher 'c8d8cea659cc46060608',
            authEndpoint: "/api/v1/push/#{company.id}/pusher.json"
            auth:
              headers:
                'App-Id' : AppConfig['App-Id']
                'App-Key' : AppConfig['App-Key']
                'Auth-Token' : $sessionStorage.getItem('auth_token')

        @pusher = $pusher(@client)
        @channel = @pusher.subscribe("mobile-queue-#{company.id}")

