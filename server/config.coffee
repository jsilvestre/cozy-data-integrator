module.exports = (app) ->

    shortcuts = require './helpers/shortcut'
    express   = require 'express'

    # all environments
    app.configure ->
        app.set 'views', __dirname + '/../client'
        app.engine '.html', require('jade').__express

        app.use express.bodyParser
            keepExtensions: true

        # extend express to DRY controllers
        app.use shortcuts

        # static middleware
        app.use express.static __dirname + '/../client/public',
            maxAge: 86400000

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
        app.set "processor_url", "http://processor.cozycloud.cc:8397/"
