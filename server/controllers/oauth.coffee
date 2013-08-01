    initiate: (req, res) ->

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

    callback: (req, res) ->
        options =
            oauth_verifier: req.query.oauth_verifier
            oauth_token: req.query.oauth_token
            oauth_secret: oauthTemp.secret

        options =
            consumer_key: 'anonymous'
            consumer_secret: 'anonymous'
            token: req.query.oauth_token
            verifier: req.query.oauth_verifier
        url = "https://www.google.com/accounts/OAuthGetAccessToken"
        console.log options, url
        request = require 'request'

        request.post {url: url, oauth: options}, (e, r, body) ->
            console.log e
            #console.log r
            console.log body
        # utiliser request pour tester
        ###
        oa.getOAuthAccessToken options, (err, token, secret, result) ->
            if err?
                console.log "Error while retrieving access token: "
                console.log "#{err.statusCode}-#{err.data}"
                console.log decodeURIComponent err.data
            else
                console.log token
                console.log secret
                console.log result
        ###

        res.send 200, "Got callback"