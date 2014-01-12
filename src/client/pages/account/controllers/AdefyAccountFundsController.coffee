##
## Copyright © 2013 Spectrum IT Solutions Gmbh
##
## Firmensitz: Wien
## Firmenbuchgericht: Handelsgericht Wien
## Firmenbuchnummer: 393588g
##
## All Rights Reserved.
##
## The use and / or modification of this file is subject to
## Spectrum IT Solutions GmbH and may not be made without the explicit
## permission of Spectrum IT Solutions GmbH
##

window.AdefyDashboard.controller "AdefyAccountFundsController", ($scope, $rootScope, $http, $route) ->

  $http.get("/api/v1/user/transactions").success (data) ->
    $scope.transactions = data

  # modal
  $scope.creditCard = {} # define the object, or it will not get set inside the modal

  # Todo: complete
  $scope.withdraw = -> true
  $scope.deposit = -> true
