db = require '../db/cozy-adapter'
module.exports = GeolocationLog = db.define 'geolocationlog',
    'id': String
    'origin': String
    'idMesInfos': String
    'timestamp': Date
    'latitude': Number
    'longitude': Number
    'radius': Number
    'msisdn': String
    'deviceState':
        'type': String, 'default': null
    'snippet': String

GeolocationLog.allLike = (geoloc, callback) ->
    key = geoloc.timestamp

    GeolocationLog.request 'allLike', key: key, (err, receipts) ->
        callback err, receipts