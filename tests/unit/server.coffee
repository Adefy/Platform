should = require("chai").should()
supertest = require "supertest"
superagent = require "superagent"
mongoose = require "mongoose"
exec = require("child_process").exec
fs = require "fs"
spew = require "spew"

config = require "../../src/server/config"

dbHost = "#{config("mongo_host")}:#{config("mongo_port")}"

# Setup mongo
before (done) ->
  @timeout 0

  dbSetup = exec "mongo #{dbHost} < #{__dirname}/../../setup_db.js"
  dbSetup.on "close", ->
    done()

# Connect to mongo
before (done) ->
  con = "mongodb://#{config("mongo_user")}:#{config("mongo_pass")}"
  con += "@#{config("mongo_host")}:#{config("mongo_port")}"
  con += "/#{config("mongo_db")}"

  mongoose.connect con, (err) ->
    if err then spew.critical "Error connecting to database [#{err}]"
    else spew.init "Connected to MongoDB [#{config("mongo_db")}]"

    # Setup db models
    modelPath = "#{__dirname}/../../src/server/models"
    fs.readdirSync(modelPath).forEach (file) ->
      if ~file.indexOf ".coffee"
        spew.init "Loading model #{file}"
        require "#{modelPath}/#{file}"

    done()

require "./server/models/ad"
require "./server/models/campaign"
require "./server/models/export"
require "./server/models/news"
require "./server/models/publisher"
require "./server/models/user"

require "./server/helpers/aem"
require "./server/helpers/randomize"
require "./server/helpers/compare"
require "./server/helpers/filters"
require "./server/helpers/graphiteInterface"
require "./server/helpers/redisInterface"

require "./server/api/base"
