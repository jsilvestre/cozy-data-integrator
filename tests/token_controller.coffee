Client = require('request-json').JsonClient
should = require('chai').should()
sinon = require 'sinon'
path = require 'path'

helpers = require './helpers'
helpers.options =
    serverHost: 'localhost'
    serverPort: '8888'
client = new Client "http://#{helpers.options.serverHost}:#{helpers.options.serverPort}/"
clientDS = new Client "http://localhost:9101/"

describe "Token management", ->

    before ->
        @sandbox = sinon.sandbox.create()
        realtime = require '../server/initializers/realtime'
        realtimeStub = @sandbox.stub realtime, "realtimeInitializer"
        realtimeStub.callsArg 2 # call the callback
    before helpers.cleanDBWithRequests
    before helpers.startApp
    after helpers.stopApp
    after helpers.cleanDBWithRequests
    after -> @sandbox.restore()

    describe "When the token is set the first time", =>

        before (done) =>
            @token = "randomtoken"
            client.get "/public/set-token/#{@token}", (err, res, body) =>
                @err = err
                @res = res
                @body = body
                done()

        it "The response should be a success", =>
            should.not.exist @err
            should.exist @res
            @res.should.have.property 'statusCode'
            @res.statusCode.should.equal 200
            should.exist @body
            @body.should.have.property 'token'
            @body.token.should.equal @token

        it "And the token should be set in the database", (done) =>
            Integrator = require '../server/models/mesinfosintegrator'
            Integrator.request "all", (err, results) =>
                should.not.exist err
                should.exist results
                results.length.should.equal 1
                results[0].should.have.property "password"
                results[0].password.should.equal @token
                done()

    describe "When there is another attempt to set the token", =>

        before (done) =>
            @token2 = "anotherrandomtoken"
            client.get "/public/set-token/#{@token2}", (err, res, body) =>
                @err = err
                @res = res
                @body = body
                done()

        it "The response should be an error", =>
            should.not.exist @err
            should.exist @res
            @res.should.have.property 'statusCode'
            @res.statusCode.should.equal 403
            should.exist @body
            @body.should.have.property 'error'

        it "And the token shouldn't have changed", (done) =>
            Integrator = require '../server/models/mesinfosintegrator'
            Integrator.request "all", (err, results) =>
                should.not.exist err
                should.exist results
                results.length.should.equal 1
                results[0].should.have.property "password"
                results[0].password.should.equal @token
                done()
