Client = require('request-json').JsonClient
should = require('chai').should()
sinon = require 'sinon'
fixtures = require 'cozy-fixtures'
path = require 'path'

helpers = require './helpers'
helpers.options =
    serverHost: 'localhost'
    serverPort: '8888'
client = new Client "http://#{helpers.options.serverHost}:#{helpers.options.serverPort}/"

fixtures.setDefaultValues
    dirPath: path.resolve __dirname, './fixtures/'
    silent: true
    removeBeforeLoad: false # useless because we clean the DB before tests

describe "Integrator Configuration (Model)", ->

    before ->
        @sandbox = sinon.sandbox.create()
        realtime = require '../server/initializers/realtime'
        realtimeStub = @sandbox.stub realtime, "realtimeInitializer"
        realtimeStub.callsArg 2 # call the callback

    before helpers.cleanDBWithRequests
    before helpers.startApp
    before (done) -> fixtures.load callback: done, dirPath: './tests/fixtures/fixtures.json'
    after helpers.stopApp
    after helpers.cleanDBWithRequests
    after -> @sandbox.restore()

    Integrator = require '../server/models/mesinfosintegrator'

    describe "Integrator.getConfig", ->

        before (done) ->
            Integrator.getConfig (err, integrator) =>
                @err = err
                @integrator = integrator
                done()

        it "There shouldn't be an error", ->
            should.not.exist @err
            should.exist @integrator

        it "And the result should be properly formed", ->
            data = @integrator.__data
            data.should.have.property 'password'
            data.should.have.property 'isUpdating'
            data.should.have.property 'data_integrator_status'

        it "And it should includes the registration statuses", ->
            statuses = @integrator.getRegistrationStatuses()
            statuses.should.have.property('cozy_registered').equal false
            statuses.should.have.property('privowny_registered').equal false
            statuses.should.have.property('privowny_oauth_registered').equal false
            statuses.should.have.property('google_oauth_registered').equal false


