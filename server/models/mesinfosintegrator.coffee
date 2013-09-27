db = require '../db/cozy-adapter'
MesInfosStatuses = require './mesinfosstatuses'


module.exports = MesInfosIntegrator = db.define 'MesInfosIntegrator',
    id: String
    password:
        type: String
        default: ""
    isUpdating:  # is the DI updating itself ?
        type: Boolean
        default: false
    data_integrator_status:
        type: Object
        default: {}


MesInfosIntegrator.getConfig = (callback) ->
    updateIntegrator = (err, statuses) ->
        if err?
            console.log "MIIntegratorModel > Can't get statuses"
            callback err, null
        else
            integrator.registration_status =
                cozy_registered: statuses.cozy_registered
                privowny_registered: statuses.privowny_registered
                privowny_oauth_registered: statuses.privowny_oauth_registered
                google_oauth_registered: statuses.google_oauth_registered
            callback null, integrator

    MesInfosIntegrator.request 'all', (err, integrator) ->
        integrator = integrator[0] if integrator? and integrator.length > 0
         if not integrator?
            console.log "No Integrator found"
            callback new Error "No integrator found", null
        else
            MesInfosStatuses.getStatuses updateIntegrator
