config = require "../config"
request = require "request"
spew = require "spew"

# Helper for graphite, builds and executes queries, and offers stat fetching
# helpers
module.exports =

  fetchStats: (options) ->
    query = @buildStatFetchQuery options
    query.exec (data) -> options.cb data

  buildStatFetchQuery: (options) ->
    if options == undefined
      spew.error "No stat fetch options set"
      return

    query = @query()
    if options.filter == true then query.enableFilter()

    for req in options.request
      for stat in req.stats

        if stat.prefix != undefined
          prefix = stat.prefix
        else
          prefix = options.prefix

        query.addStatCountTarget "#{prefix}.#{stat}", "summarize", req.range

    query

  # Used by the analytics API. Uses a standard options object to build a
  # suitable query.
  #
  # @param [Object] options
  # @param [Method] cb
  # @option options [String] stat unique stat string, without graphite prefix
  # @option options [String] start relative time from now (has to be negative)
  # @option options [String] end relative time from now (has to be negative)
  # @option options [String] interval data point interval
  # @option options [Boolean] sum defaults to false, returns a running sum
  # @option options [Array<String>] multipleSeries optional, triggers sumSeries
  makeAnalyticsQuery: (options, cb) ->
    query = @query()
    query.enableFilter()

    if options.start != null then query.from = options.start
    if options.end != null then query.until = options.end

    if options.total == "true" or options.total == true
      prefix = @getPrefixStatCounts()
    else
      prefix = @getPrefix()

    if options.multipleSeries != undefined
      for series, i in options.multipleSeries
        options.multipleSeries[i] = "#{prefix}#{series}"

      ref = "sumSeries(#{options.multipleSeries.join ","})"
    else
      ref = "#{prefix}#{options.stat}"

    if options.total == "true" or options.total == true
      query.addRawTarget "summarize(#{ref}, '#{options.interval}')"
    else if options.sum == "true" or options.sum == true
      query.addRawTarget "integral(hitcount(#{ref}, '#{options.interval}'))"
    else
      query.addRawTarget "hitcount(#{ref}, '#{options.interval}')"

    query.exec (data) ->
      if data.length == 0 then return cb []

      if options.total == "true" or options.total == true
        total = 0

        for point in data[0].datapoints
          if point.y != null then total += point.y

        cb total

      else
        cb data[0].datapoints

  getPrefix: -> "stats.#{config("NODE_ENV")}."

  # Builds a new query. Todo: Document fully
  query: ->

    @from = ""
    @until = ""

    @_filter = false
    @_targets = []

    @randomize = false

    @enableFilter = => @_filter = true
    @disableFilter = => @_filter = false
    @isFiltered = => @_filter

    @addRawTarget = (target) =>
      @_targets.push raw: target

    @addTarget = (target, method, args) =>
      if method == undefined then method = null
      @_targets.push
        method: method
        name: "#{config("NODE_ENV")}.#{target}"
        args: args

    @addStatTarget = (target, method, args) =>
      if method == undefined then method = null
      @_targets.push
        method: method
        name: "stats.#{config("NODE_ENV")}.#{target}"
        args: args

    @addStatSumTarget = (lists) =>
      if method == undefined then method = null
      @_targets.push
        method: "sumSeries"
        name: "stats.#{config("NODE_ENV")}.#{lists[0]}"
        args: lists[1...]

    @addStatIntegralTarget = (stat, args) =>
      if method == undefined then method = null
      @_targets.push
        method: "integral"
        name: "stats.#{config("NODE_ENV")}.#{stat}"
        args: args

    @addStatCountTarget = (target, method, args) =>
      if method == undefined then method = null
      @_targets.push
        method: method
        name: "stats_counts.#{config("NODE_ENV")}.#{target}"
        args: args

    @genRandomData = ->
      startX = 1395520440000
      startY = (Math.random() * 100) + 25

      data = [{}]
      data[0].datapoints = []

      for i in [0...300]

        point =
          x: startX
          y: startY

        startX += 100
        startY += (Math.random() * 10) - 5

        data[0].datapoints.push point

      data

    @exec = (cb) =>
      query = @_buildQuery()

      request query, (error, response, body) =>

        # Avoid the terrors of having to parse an empty response
        if body == undefined or body.length == 0 or body == "[]"
          return cb []

        if error then spew.error "Graphite request error: #{error}"
        else
          try
            if @_filter then body = @_filterResponse JSON.parse body
            else body = JSON.parse body

            if @randomize
              cb @genRandomData()
            else
              cb body

          catch err
            spew.error "Graphite response parsing error: #{err}"
            spew.error body
            if cb then cb []

    @getPrefixStat = -> "stats.#{config("NODE_ENV")}."
    @getPrefixStatCounts = -> "stats_counts.#{config("NODE_ENV")}."

    @_buildQuery = ->
      auth = "ferno:q94vY92GxMCK4nXHZJuKAHly"
      query = "http://#{auth}@#{config("stats_host")}/render?"

      for target, i in @_targets

        if target.raw != undefined
          query += "&target=#{target.raw}"
        else

          query += "&target="
          if target.method != null then query += "#{target.method}("
          query += target.name

          # Attach arguments, if any
          if target.args != undefined
            if target.args instanceof Array
              for arg in target.args
                if typeof arg == "string" then arg = "'#{arg}'"
                query += ", #{arg}"
            else
              arg = target.args

              if typeof arg == "string" then arg = "'#{arg}'"
              query += ", #{arg}"

          if target.method
            query += ")"

            # Add another paranthesis for each sub-function in the target
            for i in [0...target.method.split("(").length]
              query += ")"

      if @from.length > 0 then query += "&from=#{@from}"
      if @until.length > 0 then query += "&until=#{@until}"

      query += "&format=json"
      spew.info query if @debug == true
      query

    @_filterResponse = (data) ->

      for set in data
        newDataPoints = []

        for point in set.datapoints

          # Convert timestamp to ms
          newDataPoints.push
            x: point[1] * 1000
            y: point[0] or 0

        set.datapoints = newDataPoints

      data

    @
