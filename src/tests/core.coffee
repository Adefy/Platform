should = require("chai").should()
supertest = require "supertest"
superagent = require "superagent"

api = supertest "http://localhost:8080"

# Auth info
agent = superagent.agent()

describe "Authentication", ->

  it "Expect redirection on root access", (done) ->
    api.get("/").expect 302, done

  it "Should redirect to login on unauth access of existing page", (done) ->
    api.get("/dashboard").expect 302, done

  it "Should redirect to login on unauth access of non-existant page", (done) ->
    api.get("/tz4mnKtz4mnKqE03OqzDMWqE03OqzDMW").expect 302, done

  it "Should reject incorrect credentials", (done) ->
    api.post("/login").send
      username: "testy-tristat"
      password: "AvPV52ujHpmhUJjzorBx7aixkrIIKrca"
    .expect 401, done

  it "Should accept and authenticate test credentials", (done) ->
    api.post("/login").send
      username: "testy-trista"
      password: "AvPV52ujHpmhUJjzorBx7aixkrIIKrca"
    .expect(302)
    .end (err, res) ->
      agent.saveCookies res
      done()

  it "Should 404 on authorized access of non-existant page", (done) ->
    req = api.get("/tz4mnKtz4mnKqE03OqzDMWqE03OqzDMW")
    agent.attachCookies req
    req.expect 404, done