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

describe "Notification checker", ->

    before helpers.cleanDBWithRequests
    # required to initialize requests
    before (done) -> require('../init')(done)
    after helpers.cleanDBWithRequests

    describe "When startNotificationChecker is called", ->

        before ->
            @sandbox = sinon.sandbox.create()
            @clock = @sandbox.useFakeTimers()
            notifChecker = require '../server/lib/notification-checker'
            @stub = @sandbox.stub notifChecker, 'checkNotifications'

        before ->
            {startNotificationChecker} = require '../server/lib/notification-checker'
            startNotificationChecker()

        after -> @sandbox.restore()

        it "It should check notifications once", ->
            @stub.calledOnce.should.be.true

        it "And notifications shouldn't be checked 59 minutes later", ->
            @clock.tick 1000 * 60 * 59
            @stub.calledOnce.should.be.true

        it "And notifications should be checked 1 hour later", ->
            @clock.tick 1000 * 60 * 1
            @stub.calledTwice.should.be.true

    describe "When checkNotifications is called", ->

        before (done) -> fixtures.load callback: done, dirPath: './tests/fixtures/fixtures.json'

        before ->
            @sandbox = sinon.sandbox.create()
            notifChecker = require '../server/lib/notification-checker'
            @stub = @sandbox.stub notifChecker, 'updateNotifications'
            @stub.callsArg 1

        before (done) ->
            {checkNotifications} = require '../server/lib/notification-checker'
            checkNotifications ->
                done()

        after -> @sandbox.restore()

        it "It should call updateNotifications once", ->
            @stub.called.should.be.true
            @stub.calledOnce.should.be.true

        it "With statuses as parameters", ->
            data = require './fixtures/fixtures.json'
            delete data[1].docType
            @stub.args[0].length.should.equal 2
            callArgs = @stub.args[0]
            data[1].should.deep.equal callArgs[0]

    describe "When updateNotifications is called", ->

        before ->
            @notifChecker = require '../server/lib/notification-checker'

        before (done) ->
            @clientDS = new Client "http://localhost:9101/"
            map = """
                function (doc) {
                    if (doc.docType.toLowerCase() === "notification") {
                        return emit(doc._id, doc);
                    }
                }
            """
            @clientDS.put 'request/notification/all/', map: map, (err, res, body) ->
                should.not.exist err
                should.exist body
                done()

        describe "If the user hasn't registered to anything yet", ->
            it "It should create a notification to register to privowny", (done) ->
                @notifChecker.updateNotifications
                        cozy_registered: false
                        privowny_registered: false
                        privowny_oauth_registered: false
                        google_oauth_registered: false
                , (err) =>
                    should.not.exist err
                    @clientDS.post 'request/notification/all/', {}, (err, res, body) ->
                        should.not.exist err
                        should.exist body
                        body.length.should.equal 1
                        body[0].value.type.should.equal 'persistent'
                        body[0].value.ref.should.equal 'mesinfos-status-privowny_registered'
                        done()

        describe "If the user has registered to privowny", ->
            it "It should create a notification to register to privowny oauth", (done) ->
                @notifChecker.updateNotifications
                        cozy_registered: false
                        privowny_registered: true
                        privowny_oauth_registered: false
                        google_oauth_registered: false
                , (err) =>
                    should.not.exist err
                    @clientDS.post 'request/notification/all/', {}, (err, res, body) ->
                        should.not.exist err
                        should.exist body
                        body.length.should.equal 1
                        body[0].value.type.should.equal 'persistent'
                        body[0].value.ref.should.equal 'mesinfos-status-privowny_oauth_registered'
                        done()


        describe "If the user has registered to privowny oauth", ->
            it "There shouldn't be notifications from the app anymore", (done) ->
                @notifChecker.updateNotifications
                        cozy_registered: false
                        privowny_registered: true
                        privowny_oauth_registered: true
                        google_oauth_registered: false
                , (err) =>
                    should.not.exist err
                    @clientDS.post 'request/notification/all/', {}, (err, res, body) ->
                        should.not.exist err
                        should.exist body
                        body.length.should.equal 0
                        done()

