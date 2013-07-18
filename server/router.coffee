module.exports = (app) ->
    integrator = require('./controllers/integrator')(app)
    token = require('./controllers/token')(app)

    # todo change from get to put
    app.get '/public/set-token/:token/?', token.set
    app.get '/public/ping/:partner/?', integrator.ping

    app.get '/oauth/', integrator.oauth
    app.get '/oauth/callback/?', integrator.oauthCallback