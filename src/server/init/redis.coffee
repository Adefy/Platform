# We re-build our redis database(s) from persistent mongo records
spew = require "spew"
db = require "mongoose"
cluster = require "cluster"
config = require "../config"
rebuild = config "redis_main_rebuild"
redis = require("../helpers/redisInterface").main
async = require "async"

handleError = (err) -> if err then spew.error err

###
# Update user funds and re-create redis structures
#
# @param [Method] callback
###
updateUserRedisEntries = (cb) ->
  db.model("User").find {}, (err, users) ->
    if err then return spew.error err

    async.each users, (user, cb) ->
      if not user.hasAPIKey() then user.createAPIKey()
      user.save()

      user.updateFunds ->
        user.createRedisStruture ->
          cb()
    , -> cb()

###
# Re-create redis structure for all ads
#
# @param [Method] callback
###
updateAdRedisEntries = (cb) ->
  db.model("Ad").find {}, (err, ads) ->
    if err then return spew.error err

    async.each ads, (ad, cb) ->
      ad.createRedisStruture -> cb()
    , -> cb()

# If we are a worker in a cluster, only execute for worker 1
return if cluster.worker != null and cluster.worker.id != 1

spew.info "Initializing redis data...."

updateUserRedisEntries ->
  updateAdRedisEntries ->
    spew.info "...done with basic entries"

if rebuild != true then return

##
## WARNING: This flushes the redis DB and rebuilds all entries!
##          If the autocomplete DB is running on the same instance as main,
##          it will need to be rebuilt!
##

spew.info "Re-generating redis structures (this may take awhile)..."

fetchModels = (cb) ->
  models = []

  db.model("Publisher").find {}, (err, publishers) ->
    handleError err
    models.push pub for pub in publishers

    db.model("Ad").find {}, (err, ads) ->
      handleError err
      models.push ad for ad in ads

      db.model("Campaign").find {}, (err, campaigns) ->
        handleError err
        models.push campaign for campaign in campaigns

        db.model("User").find {}, (err, users) ->
          handleError err
          models.push user for user in users

          cb models

# First, clear it
redis.flushall (err, res) ->
  handleError err

  # Fetch all models that store data in redis
  fetchModels (models) ->
    async.each models, (model, cb) ->
      model.createRedisStruture -> cb()
    , ->
      spew.info "...done, redis structures generated"
