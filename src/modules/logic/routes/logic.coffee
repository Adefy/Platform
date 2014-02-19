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
spew = require "spew"
routes = require "../../../angularDashboardViews.json"
config = require "../../../config"
crypto = require "crypto"
passport = require "passport"

# Route middleware to make sure a user is logged in
isLoggedIn = (req, res, next) ->
  if req.isAuthenticated() then next()
  else res.redirect "/login"

setup = (options, imports, register) ->

  app = imports["core-express"].server
  utility = imports["logic-utility"]

  # Serve layout to each path
  for p in routes.views
    app.get p, isLoggedIn, (req, res) ->

      viewData = {}
      viewData.user = req.user
      viewData.mode = config("NODE_ENV")
      viewData.intercomSecureHash = (email) ->
        API_SECRET = "_J_vAQD69KY9l9Ryzrbd9XZeXr03wa2bZyxpTapZ"
        crypto.createHmac("sha256", API_SECRET)
        .update(req.user.email).digest "hex"

      res.render "dashboard/layout.jade", viewData, (err, html) ->
        if err then spew.error err
        else res.send html

  ##
  ## Todo: Cleanup the routines below
  ##

  # Dashboard views
  app.get "/views/dashboard/:view", isLoggedIn, (req, res) ->

    # Fancypathabstractionthingthatisprobablynotthatfancybutheywhynotgg
    if req.params.view.indexOf(":") != -1
      req.params.view = req.params.view.split(":").join "/"

    # Sanitize req.params.view
    # TODO: figure out if this is enough
    if req.params.view.indexOf("..") != -1
      req.params.view = req.params.view.split("..").join ""

    viewData = {}
    viewData.user = req.user
    viewData.mode = config("NODE_ENV")
    viewData.intercomSecureHash = (email) ->
      API_SECRET = "_J_vAQD69KY9l9Ryzrbd9XZeXr03wa2bZyxpTapZ"
      crypto.createHmac("sha256", API_SECRET)
      .update(req.user.email).digest "hex"

    res.render "dashboard/views/#{req.params.view}.jade", viewData

  # Creator view
  app.get "/views/creator/:view", (req, res) ->

    # Fancypathabstractionthingthatisprobablynotthatfancybutheywhynotgg
    if req.params.view.indexOf(":") != -1
      req.params.view = req.params.view.split(":").join "/"

    # Sanitize req.params.view
    # TODO: figure out if this is enough
    if req.params.view.indexOf("..") != -1
      req.params.view = req.params.view.split("..").join ""

    viewData = {}
    viewData.user = req.user
    viewData.mode = config("NODE_ENV")
    viewData.intercomSecureHash = (email) ->
      API_SECRET = "_J_vAQD69KY9l9Ryzrbd9XZeXr03wa2bZyxpTapZ"
      crypto.createHmac("sha256", API_SECRET)
      .update(req.user.email).digest "hex"

    res.render "creator/#{req.params.view}.jade", viewData

  register null, {}

module.exports = setup
