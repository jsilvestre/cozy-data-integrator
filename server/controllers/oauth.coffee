OAuth = require('mashape-oauth').OAuth
CozyInstance = require '../models/cozyinstance'

oauthTemp = {}
oa = new OAuth
    requestUrl: "https://www.google.com/accounts/OAuthGetRequestToken?scope=https%3A%2F%2Fwww.google.com%2Fcalendar%2Ffeeds%2F+https%3A%2F%2Fwww.google.com%2Fm8%2Ffeeds%2F+https%3A%2F%2Fpicasaweb.google.com%2Fdata%2F"
    accessUrl: "https://www.google.com/accounts/OAuthGetAccessToken"
    callback: "http://localhost:9260/oauth/callback"
    consumerKey: "anonymous"
    consumerSecret: "anonymous"
    version: "1.0"
    signatureMethod: "HMAC-SHA1"

util = require 'util'
request = require 'request'

module.exports = (app) ->
    app.oa = oa unless app.oa?

    # Set the right callback URL
    CozyInstance.getInstance (err, ci) ->
        app.oa.authorizeCallback = "http://#{ci.domain}/apps/collecteur-mesinfos/oauth/callback"

    initiate: (req, res) ->
        app.oa.getOAuthRequestToken (err, oauth_token, oauth_token_secret, results) ->
            if err?
                res.error 500, err
            else
                oauthTemp[oauth_token] =
                    token: oauth_token
                    secret: oauth_token_secret
                host = "https://www.google.com/"
                url = "accounts/OAuthAuthorizeToken"
                params = "?oauth_token=#{oauth_token}&hd=default&hl=fr"
                res.redirect "#{host}#{url}#{params}"

    callback: (req, res) ->
        options =
            oauth_token: req.query.oauth_token
            oauth_verifier: req.query.oauth_verifier
            oauth_token_secret: oauthTemp[req.query.oauth_token].secret

        app.oa.getOAuthAccessToken options, (err, token, secret, result) ->
            if err?
                console.log "Error while retrieving access token: "
                res.error 500, err
            else
                console.log 'token: ' + token
                console.log 'secret: ' + secret
                url = "https://www.googleapis.com/calendar/v3/users/me/calendarList"
                oauth =
                    consumer_key: 'anonymous'
                    consumer_secret: 'anonymous'
                    token: token
                    token_secret: secret

                request.get {url: url, oauth: oauth, json: true}, (err, res, body) ->
                    console.log res.statusCode
                    console.log err
                    console.log body unless err?
                res.send 200, "Oauth callback url"

# https://groups.google.com/forum/#!topic/google-help-dataapi/GnrI76P8tsQ
# http://stackoverflow.com/questions/8146756/google-oauthgetrequesttoken-returns-signature-invalid

# The request to send :
# https://developers.google.com/accounts/docs/OAuth_ref#AccessToken

# Signature
# http://oauth.net/core/1.0/#anchor14