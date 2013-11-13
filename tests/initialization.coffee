Client = require('request-json').JsonClient
should = require('chai').should()
sinon = require 'sinon'

helpers = require './helpers'
helpers.options =
    serverHost: 'localhost'
    serverPort: '8888'
client = new Client "http://#{helpers.options.serverHost}:#{helpers.options.serverPort}/"

describe "Application Initialization", ->

    before helpers.cleanDBWithRequests
    beforeEach ->
        @sandbox = sinon.sandbox.create()
        realtime = require '../server/initializers/realtime'
        realtimeStub = @sandbox.stub realtime, "realtimeInitializer"
        realtimeStub.callsArg 2 # call the callback
    afterEach -> @sandbox.restore()
    after helpers.cleanDBWithRequests

    describe "Requests", ->

        describe "When the application is started the first time", ->
            before helpers.startApp
            after helpers.stopApp

            it "A 'all' request for doctype MesInfosStatuses should be created", (done) ->
                Statuses = require '../server/models/mesinfosstatuses'
                Statuses.request 'all', (err, results) =>
                    should.not.exist err
                    @results = results
                    should.exist @results
                    done()

            it "And a document for this doctype should be created", ->
                @results.length.should.equal 1

            it "A 'all' request for doctype MesInfosIntegrator should be created", (done) =>
                Integrator = require '../server/models/mesinfosintegrator'
                Integrator.request 'all', (err, results) =>
                    should.not.exist err
                    @results = results
                    should.exist @results
                    done()
            it "And a document for this doctype should be created", ->
                @results.length.should.equal 1

            it "A 'all' request for doctype CozyInstance should be created", (done) ->
                Instance = require '../server/models/cozyinstance'
                Instance.request 'all', (err, results) =>
                    should.not.exist err
                    should.exist results
                    done()

        describe "When the application is started the next time", ->
            before helpers.startApp
            after helpers.stopApp

            it "There should only be one document for doctype MesInfosStatuses", (done) ->
                Statuses = require '../server/models/mesinfosstatuses'
                Statuses.request 'all', (err, results) =>
                    should.not.exist err
                    should.exist results
                    results.length.should.equal 1
                    done()

            it "There should only be one document for doctype MesInfosIntegrator", (done) ->
                Integrator = require '../server/models/mesinfosintegrator'
                Integrator.request 'all', (err, results) =>
                    should.not.exist err
                    should.exist results
                    results.length.should.equal 1
                    done()

    describe "Realtime - when the app starts", ->

        describe "User listener", ->

            before ->
                @sandbox = sinon.sandbox.create()
                @sandbox.stub require '../server/lib/notification-checker'

            before helpers.cleanDB
            before helpers.startApp
            after helpers.stopApp
            after helpers.cleanDB
            after -> @sandbox.restore()

            it "When a user is created", (done) ->
                User = require '../server/models/user'
                User.create {}, (err, user) ->
                    should.not.exist err
                    should.exist user
                    done()

            it "We wait a little so the realtime callback can do its job", (done) ->
                @timeout 1000
                setTimeout done, 300

            it "Then the cozy_registered status should be updated", (done) ->
                Statuses = require '../server/models/mesinfosstatuses'
                Statuses.getStatuses (err, statuses) ->
                    should.not.exist err
                    should.exist statuses
                    statuses.__data.should.have.property 'cozy_registered'
                    statuses.cozy_registered.should.be.true
                    done()

        describe "Statuses listener", ->
            before ->
                @sandbox = sinon.sandbox.create()
                retriever = require '../server/lib/retriever'
                notifChecker = require '../server/lib/notification-checker'

                # disable the recurrent notification checking
                @sandbox.stub notifChecker, "startNotificationChecker"

                @fakeSendStatus = @sandbox.stub retriever, "sendStatus"
                @fakeUpdateNotif = @sandbox.stub notifChecker, "updateNotifications"

            before helpers.startApp
            after helpers.stopApp
            after -> @sandbox.restore()

            it "When statuses are updated", (done) ->
                Statuses = require '../server/models/mesinfosstatuses'
                Statuses.getStatuses (err, statuses) ->
                    should.not.exist err
                    should.exist statuses
                    attr = cozy_registered: true
                    statuses.updateAttributes attr, (err, statuses) ->
                        done()

            it "We wait a little so the realtime callback can do its job", (done) ->
                @timeout 1000
                setTimeout done, 300

            it "They should be sent to the Data Processor", ->
                @fakeSendStatus.called.should.be.true
                # improve: test that the parameters should be statuses with boolean values

            it "And notifications should be checked", ->
                @fakeUpdateNotif.called.should.be.true
                # improve: test that the parameters should be statuses with boolean values

        describe "Cozy Instance listener", ->

            before ->
                @sandbox = sinon.sandbox.create()
                @sandbox.stub require '../server/lib/notification-checker'

            before helpers.cleanDB
            before helpers.startApp
            after helpers.stopApp
            after helpers.cleanDB
            after -> @sandbox.restore()

            it "Whe cozy instance is created", (done) ->
                Instance = require '../server/models/cozyinstance'
                Instance.create {}, (err, instance) ->
                    done()

            it "We wait a little so the realtime callback can do its job", (done) ->
                @timeout 1000
                setTimeout(
                    (() =>
                        Instance = require '../server/models/cozyinstance'
                        Instance.getInstance (err, instance) =>
                            should.not.exist err
                            @instance = instance
                            should.exist @instance
                            done()
                    ), 300)

            it "The locale should be set to FR", ->
                @instance.locale.should.equal "fr"

            it "The helpUrl should be the one of MesInfos", ->
                @instance.helpUrl.should.equal "http://www.enov.fr/mesinfos/"

    describe "Recurrent status check - when the app starts", ->

        before ->
            @sandbox = sinon.sandbox.create()
            notifChecker = require '../server/lib/notification-checker'
            @stub = @sandbox.stub notifChecker, "startNotificationChecker"
        before helpers.startApp
        after helpers.stopApp
        after -> @sandbox.restore

        it "The notification checker should be started", ->
            @stub.called.should.be.true
            @stub.calledOnce.should.be.true


