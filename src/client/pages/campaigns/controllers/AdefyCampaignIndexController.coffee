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
window.AdefyApp.controller "AdefyCampaignIndexController", ($scope, Campaign, $http) ->

  buildGraphData = (campaign) ->
    campaign.graphData =
      prefix: "/api/v1/analytics/campaigns/#{campaign.id}"

      graphs: [
        name: "Impressions"
        stat: "impressions"
        from: "-24h"
        interval: "30minutes"
      ,
        name: "Clicks"
        stat: "clicks"
        from: "-24h"
        interval: "30minutes"
      ]

  Campaign.query (campaigns) ->

    for c in campaigns
      c.stats.ctr *= 100
      c.stats.ctr24h *= 100

    $scope.campaigns = campaigns
    buildGraphData c for c in $scope.campaigns
