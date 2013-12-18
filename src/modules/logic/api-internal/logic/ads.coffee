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

##
## Ad manipulation
##
spew = require "spew"
db = require "mongoose"

module.exports = (utility) ->

  # Create an ad, expects "name" in url and req.cookies.user to be valid
  #
  # POST /api/v1/ads
  # Tested in api-ads.coffee
  #
  # @param [Object] req request
  # @param [Object] res response
  create: (req, res) ->
    if not utility.param req.param("name"), res, "Ad name" then return

    # Create new ad entry
    newAd = db.model("Ad")
      owner: req.user.id
      name: req.param "name"
      data: ""
      campaigns: []

    newAd.save (err) ->
      if err
        spew.error "Error saving new ad [#{err}]"
        res.json 500
        return

      res.json 200, newAd.toAPI()

  # Delete an ad, expects "id" in url and req.cookies.user to be valid
  #
  # DELETE /api/v1/ads/:id
  # Tested in api-ads.coffee
  #
  # @param [Object] req request
  # @param [Object] res response
  delete: (req, res) ->
    db.model("Ad")
    .findById(req.param("id"))
    .populate("campaigns.campaign")
    .exec (err, ad) ->

      if utility.dbError err, res then return
      if not ad then res.send(404); return

      if not req.user.admin and not ad.owner.equals req.user.id
        res.send 403
        return

      # Remove ourselves from all campaigns we are currently part of
      ad.removeFromCampaigns()

      # Now remove ourselves. So sad ;(
      ad.remove()

      res.send 200

  # Fetches owned ads
  #
  # GET /api/v1/ads
  # Tested in api-ads.coffee
  #
  # @param [Object] req request
  # @param [Object] res response
  get: (req, res) ->
    db.model("Ad")
    .find({ owner: req.user.id })
    .populate("campaigns.campaign")
    .exec (err, ads) ->
      if utility.dbError err, res then return

      ret = []
      if ads then ret.push ad.toAPI() for ad in ads

      res.json 200, ret


  # Finds a single ad by ID
  #
  # GET /api/v1/ads/:id
  # Tested in api-ads.coffee
  #
  # @param [Object] req request
  # @param [Object] res response
  find: (req, res) ->
    db.model("Ad").findById req.param("id"), (err, ad) ->
      if utility.dbError err, res then return
      if not ad then res.send(404); return

      if not req.user.admin and not ad.owner.equals req.user.id
        res.send 403
        return

      res.json ad.toAPI()
