Client = require('request-json').JsonClient
should = require('chai').should()
sinon = require 'sinon'
path = require 'path'
nock = require 'nock'

helpers = require './helpers'
clientDS = new Client "http://localhost:9101/"
authentifiedEnvs = ['test', 'production']
if process.env.NODE_ENV in authentifiedEnvs
    clientDS.setBasicAuth process.env.NAME, process.env.TOKEN

retriever = null
dataProcessToken = "randomtoken"
dataProcessorURL = "http://dataprocessor.com:80"

describe "Data retriever management", ->

    before helpers.cleanDBWithRequests
    before -> helpers.clearRequire()
    before ->
        retriever = require '../server/lib/retriever'
        retriever.init dataProcessToken, dataProcessorURL
    after helpers.cleanDBWithRequests

    describe "#getData", ->
        describe "When getData is called for an existing partner", ->

            before helpers.cleanDB
            # required to initialize requests
            before (done) -> require('../init')(done)
            before ->
                @sandbox = sinon.sandbox.create()
                @stub = @sandbox.stub retriever, "putToDataSystem"
                @stub.callsArg 1

                @fixtures =  [{action: 'create', doc: {}}, action: 'update', pkField: 'bla', doc: {'bla': 'coucou'}]
                nock(dataProcessorURL)
                    .get("/token/#{dataProcessToken}/data/orange")
                    .reply(200, @fixtures)

            before (done) ->
                @spy = @sandbox.spy (err) -> done()
                retriever.getData 'orange', @spy
            after ->
                @sandbox.restore()
                nock.restore()
            after helpers.cleanDB

            it "There shouldn't be any error", ->
                @spy.calledOnce.should.be.true
                @spy.args[0].length.should.equal 0

            it "And the data should be given to the next process", ->
                @stub.calledOnce.should.be.true
                @stub.args[0].length.should.equal 2
                @stub.args[0][0].should.deep.equal @fixtures

            it "And the last update date should be updated for given partner", (done) ->
                clientDS.post "request/mesinfosintegrator/all/", {}, (err, res, body) ->
                    should.not.exist err
                    should.exist body
                    body.length.should.equal 1
                    doc = body[0].value
                    doc.data_integrator_status.should.have.property 'orange'

                    # dirty trick to check date validity
                    new Date(doc.data_integrator_status.orange).getTime().should.be.above 0
                    done()

        describe "When getData is called for an unexisting partner", ->
            before ->
                @sandbox = sinon.sandbox.create()
                @stub = @sandbox.stub retriever, "putToDataSystem"
                @stub.callsArg 1

                nock(dataProcessorURL)
                    .get("/token/#{dataProcessToken}/data/orange2")
                    .reply(404)

            before (done) ->
                @spy = @sandbox.spy (err) -> done()
                retriever.getData 'orange2', @spy
            after ->
                @sandbox.restore()
                nock.restore()

            it "There should be an error", ->
                @spy.calledOnce.should.be.true
                @spy.args[0].length.should.equal 1

            it "And the process should stop", ->
                @stub.callCount.should.equal 0


        describe "When getData is called and no valid token is set", ->
            before ->
                @sandbox = sinon.sandbox.create()
                @stub = @sandbox.stub retriever, "putToDataSystem"
                @stub.callsArg 1

                nock(dataProcessorURL)
                    .get("/token/#{dataProcessToken}/data/orange")
                    .reply(401)

            before (done) ->
                @spy = @sandbox.spy (err) -> done()
                retriever.getData 'orange', @spy
            after ->
                @sandbox.restore()
                nock.restore()

            it "There shouldn't be any error", ->
                @spy.calledOnce.should.be.true
                @spy.args[0].length.should.equal 1

            it "And the process should stop", ->
                @stub.callCount.should.equal 0
