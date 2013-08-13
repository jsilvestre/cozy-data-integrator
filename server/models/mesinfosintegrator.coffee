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
    MesInfosIntegrator.request 'all', (err, midi) ->
        midi = midi[0] if midi? and midi.length > 0

        cb = callback
        MesInfosStatuses.getStatuses (err, mis) ->
            if err?
                console.log "MIIntegratorModel > Can't get statuses"
                cb(err, null)
            else
                midi.registration_status = {}
                midi.registration_status.cozy_registered = mis.cozy_registered
                midi.registration_status.privowny_registered = mis.privowny_registered
                midi.registration_status.privowny_oauth_registered = mis.privowny_oauth_registered
                midi.registration_status.google_oauth_registered = mis.google_oauth_registered
                cb(err, midi)
