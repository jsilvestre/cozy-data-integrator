
MesInfosIntegrator = require '../models/mesinfosintegrator'
OAuth = require('mashape-oauth').OAuth
#Client = require('request-json').JsonClient

module.exports = (app) ->

    # The integrator starts requesting the processor on demand
    ping: (req, res) ->
        MesInfosIntegrator.getConfig (err, midi) ->

            return res.error 500, 'Internal server error', err if err

            unless midi.isUpdating
                midi.updateAttributes isUpdating: false, (err) ->
                    res.error 500, 'Error while setting the status', err if err

                    # execute the HTTP request to processor
                    retriever = require('../lib/retriever.coffee')
                    retriever.init app.get('processor_url'), midi.password
                    retriever.getData req.params.partner

                    res.send 204
            else
                # 409 Conflict
                res.send 409, 'The data integrator is already updating.'

    oauth: (req, res) ->
        oa = new OAuth
                    requestUrl: "https://www.google.com/accounts/OAuthGetRequestToken?scope=https%3A%2F%2Fwww.google.com%2Fcalendar%2Ffeeds%2F+https%3A%2F%2Fwww.google.com%2Fm8%2Ffeeds%2F+https%3A%2F%2Fpicasaweb.google.com%2Fdata%2F"
                    accessUrl: "https://www.google.com/accounts/OAuthGetAccessToken"
                    #callback: "http%3A%2F%2Flocalhost%2Foauth%2Fcallback%2F"
                    callback: "http%3A%2F%2Fgooglecodesamples.com%2Foauth_playground%2Findex.php"
                    consumerKey: "anonymous"
                    consumerSecret: "anonymous"
                    version: "1.0"
                    signatureMethod: "HMAC-SHA1"

        oa.getOAuthRequestToken (error, oauth_token, oauth_token_secret, results) ->
            if error?
                res.error 500, error
            else
                console.log "GOT TOKEN: #{oauth_token} / #{oauth_token_secret}"
                console.log results
                #client = new Client 'https://www.google.com/'
                host = "https://www.google.com/"
                url = "accounts/OAuthAuthorizeToken"
                params = "?oauth_token=#{oauth_token}&hl=fr"
                res.redirect "#{host}#{url}#{params}"

                #client.get url, (err, res, body) ->
                #    if err?
                #        console.log err
                #    else
                #        console.log body
                #oa.getOAuthAccessToken
                    #oauth_verifier: ""
                #    oauth_token: oauth_token
                #    oauth_token_secret: oauth_token_secret,
                #    (error, token, secret, result) ->
                #        if error?
                #            res.error error.statusCode, error.data
                #        else
                #            res.send 200, "GOT ACCESS: #{token} / #{secret}"



    oauthCallback: (req, res) ->
        console.log req.params
        res.send 200, "Got callback"





    refreshDoctype: (req, res) ->

        console.log "refreshing doctype..."

        # Getting the token information
        # Requesting the data processor with token and doctype
        # Adding the results to the data system
        # Updating the "last update" date

    ###
    At initialization: creation of the persistent notifications
    Detect all the status update
        * Cozy registration: listen to doctype user
        * Privowny registration: after registration, privowny sends a http
            request with the token to a public route in the privowny app which
            update its status
        * Privowny oAuth authorization: when the data integrator app has the
            privwony oauth access token, it updates the status
        * Google oAuth authorization: when the data integrator has the google
            oauth access token, it updates the status
        * Bank account creation: listen to doctype bank account

    When a status update occurs, the data integrator must send the updated
        status to the data processor
    Also the associated notifications must be updated
    ###