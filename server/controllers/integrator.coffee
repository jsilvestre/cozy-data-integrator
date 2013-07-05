
MesInfosIntegrator = require '../models/mesinfosintegrator'

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

    sendStatus: (req, res) ->

    refreshDoctype: (req, res) ->

        console.log "refreshing doctype..."


        # Getting the token information
        # Requesting the data processor with token and doctype
        # Adding the results to the data system
        # Updating the "last update" date


    getStatus: (req, res) ->
        ###
        Returns the current status of the cozy :
            * Cozy registration
            * Privowny registration
            * Privowny oAuth authorization
            * Google oAuth authorization
            * Bank account creation
        ####

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