
MesInfosIntegrator = require '../models/integrator'
MesInfosStatuses = require '../models/mesinfosstatuses'

module.exports = (app) ->


    # The integrator starts requesting the processor on demand
    ping: (req, res) ->
        MesInfosIntegrator.getConfig (err, integrator) ->

            if err?
                return res.send 500, error: "Internal server error -- #{err}"
            else
                # execute the HTTP request to processor
                retriever = require('../lib/retriever.coffee')
                password = integrator.token
                retriever.init password, app.get('processor_url')
                retriever.getData req.params.partner, (err) ->
                    if err?
                        msg = "Error while retrieving data."
                        res.send 500, error: "#{msg} -- #{err}"
                    else
                        msg = "Ping ok, Data retrieved successfully."
                        res.send 200, success: msg

    index: (req, res) ->

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

        MesInfosIntegrator.getConfig (err, integrator) ->
            if err?
                console.log "main route > #{err}"
            else
                statuses = integrator.data_integrator_status
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
                        date: dateFormat value, "dd/mm/yyyy"
                        time: dateFormat value, "HH:MM"

                rs = integrator.getRegistrationStatuses()

                # render template with calculated data
                opts =
                    isGoogleMarkedAsRegistered: rs.google_oauth_registered
                    statuses: displayStatuses
                res.render 'index.jade', opts


    disableGoogleNotification: (req, res) ->
        MesInfosStatuses.getStatuses (err, status) ->
            unless status.google_oauth_registered
                status.updateAttributes google_oauth_registered: true, (err) ->
                    res.redirect "back"
            else
                res.redirect "back"
