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
            return null
        else if statuses?
            tempStatuses =
                cozy_registered: statuses.cozy_registered
                privowny_registered: statuses.privowny_registered
                privowny_oauth_registered: statuses.privowny_oauth_registered
                google_oauth_registered: statuses.google_oauth_registered
            return tempStatuses
        else
            console.log "No mesinfostatuses"
            return null

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
                    clonedIntegrator = {}
                    for key, value of integrator.toJSON()
                        clonedIntegrator[key] = value

                    if statuses?
                        clonedIntegrator.registrationStatuses = statuses
                    else
                        clonedIntegrator.registrationStatuses = {}

                    callback null, clonedIntegrator
