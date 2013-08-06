
MesInfosIntegrator = require '../models/mesinfosintegrator'
MesInfosStatuses = require '../models/mesinfosstatuses'

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

                rs = midi.registration_status
                # render template with calculated data
                opts =
                    isGoogleMarkedAsRegistered: rs.google_oauth_registered
                    statuses: displayStatuses
                res.render 'index.jade', opts, (err, html) ->
                    res.send 200, html

    disableGoogleNotification: (req, res) ->
        MesInfosStatuses.getStatuses (err, mis) ->
            unless mis.google_oauth_registered
                mis.updateAttributes google_oauth_registered: true, (err) ->
                    res.redirect "back"
            else
                res.redirect "back"