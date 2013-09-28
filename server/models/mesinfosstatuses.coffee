db = require '../db/cozy-adapter'

module.exports = MesInfosStatuses = db.define 'mesinfosstatuses',
    id: String
    cozy_registered:
        type: Boolean
        default: false
    privowny_registered:
        type: Boolean
        default: false
    privowny_oauth_registered:
        type: Boolean
        default: false
    google_oauth_registered:
        type: Boolean
        default: false

MesInfosStatuses.getStatuses = (callback) ->
    MesInfosStatuses.request 'all', (err, statuses) ->
        if err
            callback err, null
        else if not (statuses? and statuses.length > 0)
            callback null, null
        else
            callback null, statuses[0]
