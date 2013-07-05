db = require '../db/cozy-adapter'

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
        default: null

MesInfosIntegrator.getConfig = (callback) ->
    MesInfosIntegrator.request 'all', (err, midi) ->
        midi = midi[0] if midi? and midi.length > 0
        callback(err, midi)