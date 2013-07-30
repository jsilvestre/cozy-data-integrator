
MesInfosIntegrator = require '../models/mesinfosintegrator'
OAuth = require('mashape-oauth').OAuth

oauthTemp = {}
oa = new OAuth
            requestUrl: "https://www.google.com/accounts/OAuthGetRequestToken?scope=https%3A%2F%2Fwww.google.com%2Fcalendar%2Ffeeds%2F+https%3A%2F%2Fwww.google.com%2Fm8%2Ffeeds%2F+https%3A%2F%2Fpicasaweb.google.com%2Fdata%2F"
            accessUrl: "https://www.google.com/accounts/OAuthGetAccessToken"
            callback: "http://localhost:9260/oauth/callback"
            consumerKey: "anonymous"
            consumerSecret: "anonymous"
            version: "1.0"
            signatureMethod: "HMAC-SHA1"

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

    main: (req, res) ->
        res.send 200, '<html><body><a href="oauth/">Trigger oauth</a></body></html>'

    oauth: (req, res) ->

        oa.getOAuthRequestToken (error, oauth_token, oauth_token_secret, results) ->
            if error?
                res.error 500, error
            else
                console.log "GOT TOKEN: #{oauth_token} / #{oauth_token_secret}"
                oauthTemp =
                    token: oauth_token
                    secret: oauth_token_secret
                host = "https://www.google.com/"
                url = "accounts/OAuthAuthorizeToken"
                params = "?oauth_token=#{oauth_token}&hd=default&hl=fr"
                res.redirect "#{host}#{url}#{params}"

    oauthCallback: (req, res) ->
        options =
            oauth_verifier: req.query.oauth_verifier
            oauth_token: req.query.oauth_token
            oauth_secret: oauthTemp.secret
        console.log options
        oa.getOAuthAccessToken options, (err, token, secret, result) ->
            if err?
                console.log "Error while retrieving access token: "
                console.log "#{err.statusCode}-#{err.data}"
                console.log decodeURIComponent err.data
            else
                console.log token
                console.log secret
                console.log result

        res.send 200, "Got callback"

        # Updating the "last update" date