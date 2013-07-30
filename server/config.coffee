module.exports = (app) ->

    shortcuts = require './helpers/shortcut'
    express   = require 'express'

    # all environements
    app.use express.bodyParser
        # uploadDir: './uploads'
        keepExtensions: true

    # extend express to DRY controllers
    app.use shortcuts

    #test environement
    app.configure 'test', ->
        app.set "processor_url", "http://localhost:8888/"

    #development environement
    app.configure 'development', ->
        app.use express.logger 'dev'
        app.use express.errorHandler
            dumpExceptions: true
            showStack: true
        app.set "processor_url", "http://localhost:9261/"

    #production environement
    app.configure 'production', ->
        app.use express.logger()
        app.use express.errorHandler
            dumpExceptions: true
            showStack: true
        app.set "processor_url", "http://localhost:9261/"
