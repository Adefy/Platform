spew = require "spew"

should = require("chai").should()
expect = require("chai").expect
supertest = require "supertest"

config = require "../../../../src/server/config"
api = supertest "http://#{config('domain')}:#{config('port')}"

userApiKey = "apikey=DyF5l5tMS2n3zgJDEn1OwRga"
adminApiKey = "apikey=BAhz4dcT4xgs7ItgkjxhCV8Q"

module.exports = (user, admin) ->

  util = require("../../utility") api, user, admin

  handleError = util.handleError

  ###
  describe "Editor API", ->

    # GET /api/v1/editor/:ad
    it "---", (done) ->

      done()

    # POST /api/v1/editor/:action
    it "---", (done) ->

      done()

    # GET /api/v1/editor/exports/:folder/:file
    it "---", (done) ->

      done()
  ###
