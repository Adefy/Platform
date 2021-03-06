spew = require "spew"
db = require "mongoose"
_ = require "lodash"
async = require "async"
APIBase = require "./base"
aem = require "../helpers/aem"
compare = require "../helpers/compare"
engineFilters = require "../helpers/filters"

class APICampaigns extends APIBase

  constructor: (@app) ->
    super model: "Campaign", populate: ["ads"]
    @registerRoutes()

  ###
  # Creates a new campaign model with the provided options
  #
  # @param [Object] options
  # @param [ObjectId] owner
  # @return [Campaign] model
  ###
  createNewCampaign: (options, owner) ->
    db.model("Campaign")
      owner: owner
      name: options.name
      description: options.description || ""
      category: options.category

      totalBudget: Number options.totalBudget || 0
      dailyBudget: Number options.dailyBudget
      pricing: options.pricing

      bidSystem: options.bidSystem
      bid: Number options.bid

      networks: ["mobile", "wifi"]

      startDate: Number options.startDate || 0
      endDate: Number options.endDate || 0

      ads: []

  ###
  # Populate stats field with all stats on provided campaigns
  #
  # @param [Array<Campaign>] campaigns
  # @param [Method] callback
  ###
  populateCampaignStats: (campaigns, cb) ->
    async.map campaigns, (campaign, done) ->
      campaign.populateSelfAllStats ->
        done null, campaign
    , (err, campaigns) ->
      cb campaigns

  ###
  # Anonymize an array of campaigns
  #
  # @param [Array<Campaign>] campaigns
  # @param [Array<Object>] anonCampaigns
  ###
  anonymize: (campaigns) ->
    _.map campaigns, (campaign) -> campaign.toAnonAPI()

  ###
  # Generate individual lists of flat includes and excludes from a client
  # provided set.
  #
  # @param [Array<Object>] flatList
  # @return [Array<Array, Array>] filters
  ###
  generateFilterSet: (flatList) ->
    include = _.filter(flatList, (e) -> e.type == "include").map (e) -> e.name
    exclude = _.filter(flatList, (e) -> e.type == "exclude").map (e) -> e.name

    [include, exclude]

  ###
  # This is the heart of the campaign update method. Sorts the provided ad list
  # into seperate lists of ads to be added and removed, then returns a final
  # new ad list to be saved on the model along with the modifications.
  #
  # @param [Campaign] campaign campaign model
  # @param [Array<Object>] ads
  # @return [Array<Add, Remove, List>] results
  ###
  sortUpdatedAdList: (campaign, ads) ->

    add = []
    remove = []
    list = []

    for id, status of @getAdStatuses(campaign, ads)

      list.push id if status == "created" or status == "unmodified"
      remove.push id if status == "deleted"
      add.push id if status == "created"

    [add, remove, list]

  ###
  # Builds an object describing the status of the combined ads on the request
  # and the campaign. Statuses are "created", "deleted", or "unmodified"
  #
  # @param [Campaign] campaign campaign model
  # @param [Array<Object>] ads
  # @return [Object] statuses
  ###
  getAdStatuses: (campaign, ads) ->
    adStatus = {}
    adStatus["#{ad._id}"] = "deleted" for ad in campaign.ads

    _.each _.filter(ads, (ad) -> ad.status == 2), (ad) ->

      if adStatus[ad.id] == undefined
        adStatus[ad.id] = "created"
      else
        adStatus[ad.id] = "unmodified"

    adStatus

  ###
  # Register our routes on the express server
  ###
  registerRoutes: ->

    ###
    # POST /api/v1/campaigns
    #   Create a Campaign
    # @qparam [String] name
    # @qparam [String] catergory
    # @qparam [String] pricing
    # @qparam [String] dailyBudget
    # @qparam [String] bidSystem
    # @qparam [String] bid
    # @response [Object] Campaign returns a new Campaign object
    # @example
    #   $.ajax method: "POST",
    #          url: "/api/v1/campaigns",
    #          data:
    #            name: "MyCampaign"
    #            catergory: "games"
    #            pricing: ""
    #            dailyBudget: ""
    #            bidSystem: ""
    #            bid: ""
    ###
    @app.post "/api/v1/campaigns", @apiLogin, (req, res) =>
      return unless aem.param req.body.name, res, "Campaign name"
      return unless aem.param req.body.category, res, "Category"
      return unless aem.param req.body.pricing, res, "Pricing"
      return unless aem.param req.body.dailyBudget, res, "Daily budget"
      return unless aem.param req.body.bidSystem, res, "Bid system"
      return unless aem.param req.body.bid, res, "Bid"

      newCampaign = @createNewCampaign req.body, req.user.id
      newCampaign.validate (err) ->
        return aem.send res, "400:validate", error: err if err

        newCampaign.save()
        res.json newCampaign.toAnonAPI()

    ###
    # GET /api/v1/campaigns
    #   Returns a list of owned campaigns
    # @param [ID] id
    # @response [Array<Object>] Campaigns campaign list
    # @example
    #   $.ajax method: "GET",
    #          url: "/api/v1/campaigns",
    ###
    @app.get "/api/v1/campaigns", @apiLogin, (req, res) =>
      @queryOwner req.user.id, res, (campaigns) =>
        @populateCampaignStats campaigns, (campaigns) =>
          res.json 200, @anonymize campaigns

    ###
    # GET /api/v1/campaigns/:id
    #   Returns a Campaign by :id
    # @param [ID] id
    # @response [Object] Campaign
    # @example
    #   $.ajax method: "GET",
    #          url: "/api/v1/campaigns/gt8hfuquiNfzdJac3YYeWmgE"
    ###
    @app.get "/api/v1/campaigns/:id", @apiLogin, (req, res) =>
      @queryId req.params.id, res, (campaign) ->
        return aem.send res, "404" unless campaign
        return unless aem.isOwnerOf req.user, campaign, res

        campaign.populateSelfAllStats ->
          res.json campaign.toAnonAPI()

    ###
    # POST /api/v1/campaigns/:id
    #   Saves the campaign, and creates campaign references where needed. User must
    #   either be admin or own the campaign in question!
    # @param [ID] id
    # @response [Object] Campaign
    # @example
    #   $.ajax method: "POST",
    #          url: "/api/v1/campaigns/GwOqeuETAht3r47K2MX1omRx",
    #          data:
    #            --campaign-update-data--
    ###
    @app.post "/api/v1/campaigns/:id", @apiLogin, (req, res) =>

      # Todo: Figure out a way to break this stuff out onto the module
      #       scope, so we can test it

      @queryId req.params.id, res, (campaign) =>
        return aem.send res, "404" unless campaign
        return unless aem.isOwnerOf req.user, campaign, res

        # Perform basic validation
        if req.body.totalBudget
          return unless aem.optIsNumber req.body.totalBudget, "total budget", res

        if req.body.dailyBudget
          return unless aem.optIsNumber req.body.dailyBudget, "daily budget", res

        if req.body.bid
          return unless aem.optIsNumber req.body.bid, "bid amount", res

        if req.body.bidSystem
          return unless aem.optIsOneOf req.body.bidSystem, ["Manual", "Automatic"], "bid system", res

        if req.body.pricing
          return unless aem.optIsOneOf req.body.pricing, ["CPM", "CPC"], "pricing", res

        # Don't allow active state change through edit path
        delete req.body.active if req.body.active != undefined

        # Store modification information
        needsAdRefRefresh = false
        add = []
        remove = []

        # Keep ad id list, update later once we have the new one
        newAdList = campaign.ads

        # Process ad list first, so we know what we need to delete before
        # modifying refs
        if req.body.ads != undefined
          [add, remove, newAdList] = @sortUpdatedAdList campaign, req.body.ads

        # Generate refs and commit new list
        buildAdAddArray = (adlist, cb) ->
          db.model("Ad").find _id: { $in: adlist }, (err, ads) ->
            return if aem.dbError err, res

            cb _.filter ads, (ad) -> ad.status == 2

        buildAdRemovalArray = (adlist, cb) ->
          db.model("Ad").find _id: { $in: adlist }, (err, ads) ->
            return if aem.dbError err, res
            cb ads

        # At this point, we can clear deleted ad refs
        buildAdRemovalArray remove, (remove) =>
          campaign.removeAds remove, =>

            # Iterate over and change all other properties
            for key, val of req.body
              if key == "ads" then continue
              if key == "networks"
                if val[0] == "all" then val = ["mobile", "wifi"]

              # Only make changes if key is modified
              currentVal = campaign[key]
              validKey = key == "devices" or key == "countries" or
                         currentVal != undefined

              if not validKey or _.isEqual currentVal, val then continue

              # Convert include/exclude array sets
              if key == "devices" or key == "countries"

                # Properly form empty arguments
                val = [] if val.length == 0

                if key == "devices"
                  [include, exclude] = @generateFilterSet val
                  campaign.devicesInclude = include
                  campaign.devicesExclude = exclude
                else if key == "countries"
                  [include, exclude] = @generateFilterSet val
                  campaign.countriesInclude = include
                  campaign.countriesExclude = exclude

              # Set ref refresh flag if needed
              if not needsAdRefRefresh

                forceRefresh = [
                  "bidSystem"
                  "bid"
                  "devices"
                  "countries"
                  "pricing"
                  "category"
                ]

                needsAdRefRefresh = true if _.contains forceRefresh, key

              # Save final value on campaign
              if key != "countries" and key != "devices"
                campaign[key] = val

            # Refresh ad refs on unchanged ads (if we are active)
            if needsAdRefRefresh and campaign.active
              campaign.refreshAdRefs()

            buildAdAddArray add, (add) ->
              campaign.addAds add, ->
                campaign.ads = newAdList
                campaign.save ->
                  res.json campaign.toAnonAPI()

    ###
    # DELETE /api/v1/campaigns/:id
    #   Delete the campaign identified by id
    #   If we are not the administrator, we must own the campaign!
    # @param [ID] id
    # @example
    #   $.ajax method: "DELETE",
    #          url: "/api/v1/campaigns/olzXtI1Giw25zZ9hDlvBgFIK",
    #          data:
    #            --campaign-update-data--
    ###
    @app.delete "/api/v1/campaigns/:id", @apiLogin, (req, res) =>
      return unless aem.param req.params.id, res, "Id"

      @queryId req.params.id, res, (campaign) ->
        return aem.send res, "404" unless campaign
        return unless aem.isOwnerOf req.user, campaign, res

        campaign.remove()
        aem.send res, "200:delete"

    ###
    # GET /api/v1/campaigns/:id/:stat/:range
    #   Retrieves custom :stat from the Campaign based on :range by :id
    # @param [ID] id
    # @param [String] stat
    # @param [Range] range
    # @example
    #   $.ajax method: "GET",
    #          url: "/api/v1/campaigns/xGIX51EP6ABK12Kg4XDT5f1J/clicks/from=-24h&to=-1h"
    ###
    @app.get "/api/v1/campaigns/stats/:id/:stat/:range", @apiLogin, (req, res) =>
      return unless aem.param req.params.id, res, "Campaign id"
      return unless aem.param req.params.range, res, "Temporal range"
      return unless aem.param req.params.stat, res, "Stat"

      @queryId req.params.id, res, (campaign) ->
        return aem.send res, "404" unless campaign
        return unless aem.isOwnerOf req.user, campaign, res

        campaign.fetchCustomStat req.params.range, req.param.stat, (data) ->
          res.json data

    ###
    # POST /api/v1/campaigns/:id/activate
    #   Activates a Campaign
    # @param [ID] id
    # @example
    #   $.ajax method: "POST",
    #          url: "/api/v1/campaigns/U1FyJtQHy8S5nfZvmfyjDPt3/activate"
    ###
    @app.post "/api/v1/campaigns/:id/activate", @apiLogin, (req, res) =>
      @queryId req.params.id, res, (campaign) ->
        return aem.send res, "404" unless campaign
        return aem.send res, "401" if campaign.tutorial
        return unless aem.isOwnerOf req.user, campaign, res

        campaign.activate ->
          campaign.save ->
            res.json 200, campaign.toAnonAPI()

    ###
    # POST /api/v1/campaigns/:id/deactivate
    #   De-activates a Campaign
    # @param [ID] id
    # @example
    #   $.ajax method: "POST",
    #          url: "/api/v1/campaigns/WThH9UVp1V41Tw7qwOuR8PVm/deactivate"
    ###
    @app.post "/api/v1/campaigns/:id/deactivate", @apiLogin, (req, res) =>
      @queryId req.params.id, res, (campaign) ->
        return aem.send res, "404" unless campaign
        return aem.send res, "401" if campaign.tutorial
        return unless aem.isOwnerOf req.user, campaign, res

        campaign.deactivate ->
          campaign.save ->
            res.json 200, campaign.toAnonAPI()

module.exports = (app) -> new APICampaigns app
