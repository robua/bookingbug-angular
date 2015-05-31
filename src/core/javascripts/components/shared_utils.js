
/* Usefull javascript functions usable directly withing html views - often for getting scope related data */

getControllerScope = function(controller, fn){
  $(document).ready(function(){
    var $element = $('div[data-ng-controller="' + controller + '"]');
    var scope = angular.element($element).scope();
    fn(scope); 
  });
}


function getURIparam( name ){
  name = name.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]");
  var regexS = "[\\?&]"+name+"=([^&#]*)";
  var regex = new RegExp( regexS );
  var results = regex.exec( window.location.href );
  if( results == null )
    return "";
  else
    return results[1];
}