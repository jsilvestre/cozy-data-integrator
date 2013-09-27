db = require '../db/cozy-adapter'

module.exports = CozyInstance = db.define 'CozyInstance',
    id: String
    domain: String
    locale: String
    helpUrl: String

CozyInstance.getInstance = (callback) ->
    CozyInstance.request 'all', (err, instances) ->
        instances = instances[0] if instances? and instances.length > 0
        callback err, instances
