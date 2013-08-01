
MesInfosIntegrator = require '../models/mesinfosintegrator'
MesInfosStatuses = require '../models/mesinfosstatuses'
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

                    res.send 204, "Ping successful"
            else
                # 409 Conflict
                res.send 409, 'The data integrator is already updating.'

    main: (req, res) ->

        mapper =
            'orange': 'Orange'
            'axa': 'AXA'
            'societegenerale': 'Société Générale'
            'creditcooperatif': 'Crédit Coopératif'
            'banquepostale': 'Banque Postale'
            'intermarche': 'Intermarché'
            'laposte': 'La Poste'
            'voyagesncf': 'Voyages-SNCF'
            'mobivia': 'Mobivia'
            'midas': 'Midas'
            'norauto': 'Norauto'
            'eden': 'Eden'
            'fing': 'Fing'
        dateFormat = require 'dateformat'

        MesInfosIntegrator.getConfig (err, midi) ->
            if err?
                console.log "main route > #{err}"
            else
                statuses = midi.data_integrator_status
                console.log statuses
                displayStatuses = {}
                for slug, value of statuses

                    # handle potential partner not mapped in the app
                    if mapper[slug]?
                        label = mapper[slug]
                    else
                        label = slug

                    # prepare the data that will be passed to the template
                    displayStatuses[slug] =
                        label: label
                        date: dateFormat(value, "dd/mm/yyyy")
                        time: dateFormat(value, "HH:MM")

                # render template with calculated data
                opts =
                    isGoogleMarkedAsRegistered: midi.registration_status.google_oauth_registered
                    statuses: displayStatuses
                res.render 'index.jade', opts, (err, html) ->
                    res.send 200, html

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

    disableGoogleNotification: (req, res) ->
        MesInfosStatuses.getStatuses (err, mis) ->
            unless mis.google_oauth_registered
                mis.updateAttributes google_oauth_registered: true, (err) ->
                    res.redirect "back"
            else
                res.redirect "back"
            #res.redirect "back"
        # Updating the "last update" date