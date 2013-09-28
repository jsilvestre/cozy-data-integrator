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
    registrationStatuses:
        type: Object
        default: {}


MesInfosIntegrator.getConfig = (callback) ->

    MesInfosIntegrator.request 'all', (err, integrator) ->
        if err?
            callback err, null
        else if not (integrator? and integrator.length > 0)
            callback null, null
        else
            integrator = integrator[0]
            MesInfosStatuses.getStatuses (err, statuses) ->
                if err?
                    console.log "MIIntegratorModel > Can't get statuses"
                    callback null, null
                else
                    # workaround because we can't add data easily in that object
                    # so we add it to the model but feed it from another
                    integrator.registrationStatuses =
                        cozy_registered: statuses.cozy_registered
                        privowny_registered: statuses.privowny_registered
                        privowny_oauth_registered: statuses.privowny_oauth_registered
                        google_oauth_registered: statuses.google_oauth_registered

                    callback null, integrator