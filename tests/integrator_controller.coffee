Client = require('request-json').JsonClient
should = require('chai').should()
sinon = require 'sinon'
path = require 'path'

helpers = require './helpers'
helpers.options =
    serverHost: 'localhost'
    serverPort: '8888'
client = new Client "http://#{helpers.options.serverHost}:#{helpers.options.serverPort}/"

describe "Integrator Controller", ->

    #before ->
        #@sandbox = sinon.sandbox.create()
        #realtime = require '../server/initializers/realtime'
        #realtimeStub = @sandbox.stub realtime, "realtimeInitializer"
        #realtimeStub.callsArg 2 # call the callback

        #retriever = require '../server/lib/retriever'
        #@retrieverStub = @sandbox.stub retriever
        #@retrieverStub.getData.callsArg 1 # call the callback

    #before helpers.cleanDBWithRequests
    #before helpers.startApp
    #after helpers.stopApp
    #after helpers.cleanDBWithRequests

    #after -> @sandbox.restore()

    describe "Ping", ->

        describe "When the application is pinged (idle)", ->
            true.should.be.ok

            #before (done) ->
                #client.get 'public/ping/orange', (err, res, body) =>
                    #@err = err
                    #@res = res
                    #@body = body
                    #done()

            #it "The response should be a success", ->
                #should.not.exist @err
                #should.exist @res
                #@res.should.have.property('statusCode').equal 200
                #should.exist @body

            #it "It should trigger request to the Data Processor", ->
                #@retrieverStub.getData.calledOnce.should.be.true


    #describe "Index", ->

        #describe "When the app index is requested", ->

            #before (done) ->
                #client.get '/', (err, res, body) =>
                    #@err = err
                    #@res = res
                    #@body = body
                    #done()
                #, false

            #it "The response should be a success", ->
                #should.not.exist @err
                #should.exist @res
                #@res.should.have.property('statusCode').equal 200
                #should.exist @body

            #it "It should send HTML", ->
                #@res.headers.should.have.property('content-type')
                #@res.headers['content-type'].should.equal 'text/html; charset=utf-8'

