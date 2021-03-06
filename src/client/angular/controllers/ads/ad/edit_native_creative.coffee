angular.module("AdefyApp").controller "AdefyAdNativeCreativeController", ($scope, AdService, $routeParams, $timeout, $http) ->

  AdService.getAd $routeParams.id, (ad) ->
    $scope.ad = ad
    $scope.ad.getNativeStatus()

  $scope.submitted = false
  $scope.saving = false

  $scope.pickIcon = ->
    filepicker.pickAndStore
      mimetype: "image/*"
    ,
      location: "S3"
      path: "/ads/assets/"
    , (blob) ->
      $scope.$apply -> $scope.ad.native.iconURL = blob[0]

  $scope.pickFeature = ->
    filepicker.pickAndStore
      mimetype: "image/*"
    ,
      location: "S3"
      path: "/ads/assets/"
    , (blob) ->
      $scope.$apply -> $scope.ad.native.featureURL = blob[0]

  # Ad status is artificial (put on the model by us) and set on load/save
  $scope.dataStatus = ->
    if $scope.ad
      $scope.ad.native.status
    else
      false

  $scope.activeToggled = ->
    if $scope.ad.native.active
      $http.post "/api/v1/ads/#{$scope.ad.id}/native/deactivate"
    else
      $http.post "/api/v1/ads/#{$scope.ad.id}/native/activate"

  $scope.save = ->
    $scope.submitted = true
    $scope.saving = true

    AdService.save $scope.ad, (ad) ->
      $scope.setNotification "Saved!", "success"
      $scope.ad = ad
      $scope.saving = false
      $scope.ad.getNativeStatus()
    , ->
      $scope.saving = false
      $scope.setNotification "There was an error with your submission", "error"
      $scope.ad.getNativeStatus()
