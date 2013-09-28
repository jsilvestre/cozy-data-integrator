db = require '../db/cozy-adapter'

module.exports = CozyInstance = db.define 'CozyInstance',
    id: String
    domain: String
    locale: String
    helpUrl: String

CozyInstance.getInstance = (callback) ->
    CozyInstance.request 'all', (err, instances) ->
        if err
            callback err, null
        else if not(instances? and instances.length > 0)
            callback new Error 'No instance parameters found', null
        else
            callback null, instances[0]
