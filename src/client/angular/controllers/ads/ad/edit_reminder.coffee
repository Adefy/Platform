angular.module("AdefyApp").controller "AdefyAdReminderController", ($scope, AdService, $routeParams) ->

  AdService.getAd $routeParams.id, (ad) ->
    $scope.ad = ad

  $scope.dateNow = Date.now()
  $scope.submitted = false
  $scope.saving = false

  $scope.save = ->
    $scope.submitted = true
    $scope.saving = true

    AdService.save $scope.ad, (ad) ->
      $scope.setNotification "Saved!", "success"
      $scope.ad = ad
      $scope.saving = false
    , ->
      $scope.saving = false
      $scope.setNotification "There was an error with your submission", "error"

  $scope.pickIcon = ->
    filepicker.pickAndStore
      mimetype: "image/*"
    ,
      location: "S3"
      path: "/ads/assets/"
    , (blob) ->
      $scope.$apply -> $scope.ad.pushIcon = blob[0]
