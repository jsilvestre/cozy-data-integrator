module.exports = (app) ->
    integrator = require('./controllers/integrator')(app)
    token = require('./controllers/token')(app)
    #oauth = require('./controllers/oauth')(app)

    # todo change from get to put
    app.get '/public/set-token/:token/?', token.set
    app.get '/public/ping/:partner/?', integrator.ping

    app.get '/', integrator.index
    #app.get '/disable-google-notification/?', \
    #        integrator.disableGoogleNotification
    #app.get '/oauth/', oauth.initiate
    #app.get '/oauth/callback/?', oauth.callback
