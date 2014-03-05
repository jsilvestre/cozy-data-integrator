db = require '../db/cozy-adapter'

module.exports = UseTracker = db.define 'UseTracker',
    id: String
    app: String
    dateStart: Date
    dateEnd: Date
    duration: Number
    sent:
        type: Boolean
        default: null

UseTracker.getSome = (limit, callback) ->
    params = limit: limit
    UseTracker.request 'nonSent', params, callback