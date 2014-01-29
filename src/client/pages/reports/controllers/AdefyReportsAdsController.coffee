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
window.AdefyApp.controller "AdefyReportsAdsController", ($scope, Ad, $http) ->

  ##
  ## Initial render settings and options
  ##
  $scope.range =
    startDate: new Date(new Date().getTime() - 86400000)
    endDate: new Date()
  $scope.graphInterval = "30minutes"
  $scope.graphSum = true
  $scope.intervalOptions = [
    { val: "5minutes", name: "5 Minutes" }
    { val: "15minutes", name: "15 Minutes" }
    { val: "30minutes", name: "30 Minutes" }
    { val: "1hour", name: "1 Hour" }
    { val: "2hours", name: "2 Hours" }
  ]

  ##
  ## Define graphs
  ##
  initNullGraphs = ->
    $scope.impressionsData = null
    $scope.clicksData = null
    $scope.spentData = null
    $scope.comparisonData = null
  initNullGraphs()

  ##
  ## Hover formatter and re-useable axis definitino
  ##
  $scope.hoverFormatNumber = (series, x, y) ->
    "#{series.name}: #{accounting.formatNumber y, 2}"
  $scope.hoverFormatSpent = (series, x, y) ->
    "#{series.name}: #{accounting.formatMoney y, "$", 2}"

  graphAxesNumber =
    x:
      type: "x"
      formatter: (x) -> moment(x).fromNow()
    counts:
      type: "y"
      orientation: "left"
      formatter: (y) -> accounting.formatNumber y

  graphAxesCurrency =
    x:
      type: "x"
      formatter: (x) -> moment(x).fromNow()
    currency:
      type: "y"
      orientation: "left"
      formatter: (y) -> accounting.formatMoney y, "$", 2

  ##
  ## Fetch ads and build graph data
  ##
  Ad.query (ads) ->
    for ad in ads
      ad.stats.ctr *= 100
      ad.stats.ctr24h *= 100

    buildPerformanceGraphs ads
    buildComparisonTable ads
    $scope.ads = ads

  # Graph data generation
  buildPerformanceGraphs = (ads) ->
    $scope.impressionsData = { graphs: [], axes: graphAxesNumber }
    $scope.clicksData = { graphs: [], axes: graphAxesNumber }
    $scope.spentData = { graphs: [], axes: graphAxesCurrency }

    start = $scope.range.startDate.getTime()
    end = $scope.range.endDate.getTime()

    start = moment(start).format "HH:MM_YYYYMMDD"
    end = moment(end).format "HH:MM_YYYYMMDD"

    for ad in ads
      $scope.impressionsData.graphs.push
        name: "#{ad.name}"
        stat: "impressions-#{ad.name}"
        url: "/api/v1/analytics/ads/#{ad.id}/impressions"
        y: "counts"
        from: "#{start}"
        until: "#{end}"
        interval: $scope.graphInterval
        sum: $scope.graphSum
        newcol: true

      $scope.clicksData.graphs.push
        name: "#{ad.name}"
        stat: "clicks-#{ad.name}"
        url: "/api/v1/analytics/ads/#{ad.id}/clicks"
        y: "counts"
        from: "#{start}"
        until: "#{end}"
        interval: $scope.graphInterval
        sum: $scope.graphSum
        newcol: true

      $scope.spentData.graphs.push
        name: "#{ad.name}"
        stat: "spent-#{ad.name}"
        url: "/api/v1/analytics/ads/#{ad.id}/spent"
        y: "currency"
        from: "#{start}"
        until: "#{end}"
        interval: $scope.graphInterval
        sum: $scope.graphSum
        newcol: true

  buildComparisonTable = (ads) ->
    doneCount = ads.length * 3
    done = (cb) -> doneCount--; if doneCount == 0 then cb()

    start = $scope.range.startDate.getTime()
    end = $scope.range.endDate.getTime()

    start = moment(start).format "HH:MM_YYYYMMDD"
    end = moment(end).format "HH:MM_YYYYMMDD"

    suffix = "?from=#{start}&until=#{end}&interval=24h&total=true"
    prefix = "/api/v1/analytics/ads"

    tableData = []

    buildTableDataForAd = (ad) ->
      index = tableData.length
      tableData.push name: ad.name

      $http.get("#{prefix}/#{ad.id}/impressions#{suffix}").success (data) ->
        tableData[index].impressions = data
        done -> finished()

      $http.get("#{prefix}/#{ad.id}/clicks#{suffix}").success (data) ->
        tableData[index].clicks = data
        done -> finished()

      $http.get("#{prefix}/#{ad.id}/spent#{suffix}").success (data) ->
        tableData[index].spent = data
        done -> finished()

    finished = ->
      for i in [0...tableData.length]
        if tableData[i].impressions != 0
          tableData[i].ctr = tableData[i].clicks / tableData[i].impressions

      $scope.comparisonData = tableData

    buildTableDataForAd ad for ad in ads

  update = ->
    initNullGraphs()
    if $scope.ads == undefined then return

    setTimeout ->
      $scope.$apply ->
        buildPerformanceGraphs $scope.ads
        buildComparisonTable $scope.ads
    , 1

  $("body").off "change", ".ad-reports-controls select[name=interval]"
  $("body").off "change", ".ad-reports-controls input[name=sum]"
  $("body").on "change", ".ad-reports-controls input[name=sum]", -> update()
  $("body").on "change", ".ad-reports-controls select[name=interval]", -> update()

  $scope.$watch "range.startDate", -> update()
  $scope.$watch "range.endDate", -> update()
