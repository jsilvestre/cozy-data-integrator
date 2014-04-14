db = require '../db/cozy-adapter'
MesInfosStatuses = require './mesinfosstatuses'

module.exports = IntegratorConfig = db.define 'IntegratorConfig',
    id: String
    token:
        type: String
        default: ""
    isUpdating:  # is the DI updating itself ?
        type: Boolean
        default: false
    data_integrator_status:
        type: Object
        default: {}

IntegratorConfig.getConfig = (callback) ->
    IntegratorConfig.request 'all', (err, integrator) ->
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
                    privRegistered = statuses.privowny_registered
                    privoAuthRegistered = statuses.privowny_oauth_registered
                    googoAuthRegistered = statuses.google_oauth_registered
                    integrator.__data.registrationStatuses =
                        cozy_registered: statuses.cozy_registered
                        privowny_registered: privRegistered
                        privowny_oauth_registered: privoAuthRegistered
                        google_oauth_registered: googoAuthRegistered

                    callback null, integrator

IntegratorConfig::getRegistrationStatuses = ->
    return @__data.registrationStatuses