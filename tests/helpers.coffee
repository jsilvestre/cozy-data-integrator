sinon = require 'sinon'
fixtures = require 'cozy-fixtures'

helpers = {}

# server management
helpers.options = {}
helpers.app = null

helpers.startApp = (done) ->
    @timeout 10000
    http = require 'http'
    express = require 'express'
    init = require '../init'
    router = require '../server/router'
    configure = require '../server/config'
    {realtimeInitializer} = require '../server/initializers/realtime'

    @app = express()
    configure @app
    router @app
    init (err) => # ./init.coffee
        if err
            console.log "Initialization failed, not starting"
            console.log err.stack
            return

        port = helpers.options.serverPort
        host = helpers.options.serverHost
        server = http.createServer(@app).listen port, host, =>
            console.log "Server listening on %s:%d within %s environment",
                host, port, @app.get 'env'
            @app.server = server
            realtimeInitializer @app, server, done

helpers.stopApp = (done) ->
    @timeout 3000
    setTimeout =>
        @app.server.close ->
            helpers.clearRequire()
            done()
    , 1000

# those instances are shared and require cache must be cleaned so we can isolate
# tests cases
helpers.clearRequire = ->
    delete require.cache[require.resolve('../server/initializers/realtime')]
    delete require.cache[require.resolve('../server/lib/retriever')]
    delete require.cache[require.resolve('../server/lib/notification-checker')]
    # todo: clear socket.io callbacks

# database helper
helpers.cleanDB = (done) ->
    @timeout 10000
    fixtures.resetDatabase callback: done
helpers.cleanDBWithRequests = (done) ->
    @timeout 10000
    fixtures.resetDatabase removeAllViews: true, callback: done

module.exports = helpers