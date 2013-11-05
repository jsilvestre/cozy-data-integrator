OAuth = require('mashape-oauth').OAuth
CozyInstance = require '../models/cozyinstance'

oauthTemp = {}
requestUrl = "https://www.google.com/accounts/OAuthGetRequestToken?scope="
requestUrl += "https%3A%2F%2Fwww.google.com%2Fcalendar%2Ffeeds%2F+"
requestUrl += "https%3A%2F%2Fwww.google.com%2Fm8%2Ffeeds%"
requestUrl += "2F+https%3A%2F%2Fpicasaweb.google.com%2Fdata%2F"

oa = new OAuth
    requestUrl: requestUrl
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
    CozyInstance.getInstance (err, instance) ->
        url = "http://#{instance.domain}/apps/collecteur-mesinfos/oauth/" + \
              "callback"
        app.oa.authorizeCallback = url

    initiate: (req, res) ->
        app.oa.getOAuthRequestToken (err, token, tokenSecret, results) ->
            if err?
                res.error 500, err
            else
                oauthTemp[token] =
                    token: token
                    secret: tokenSecret
                host = "https://www.google.com/"
                url = "accounts/OAuthAuthorizeToken"
                params = "?oauth_token=#{token}&hd=default&hl=fr"
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
                url = "https://www.googleapis.com/calendar/"
                url += "v3/users/me/calendarList"
                oauth =
                    consumer_key: 'anonymous'
                    consumer_secret: 'anonymous'
                    token: token
                    token_secret: secret

                data = {url: url, oauth: oauth, json: true}
                request.get data, (err, res, body) ->
                    console.log res.statusCode
                    console.log err
                    console.log body unless err?
                res.send 200, "Oauth callback url"

# https://groups.google.com/forum/#!topic/google-help-dataapi/GnrI76P8tsQ
# http://stackoverflow.com/questions/8146756/
# google-oauthgetrequesttoken-returns-signature-invalid

# The request to send :
# https://developers.google.com/accounts/docs/OAuth_ref#AccessToken

# Signature
# http://oauth.net/core/1.0/#anchor14
