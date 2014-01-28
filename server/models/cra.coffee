db = require '../db/cozy-adapter'
module.exports = PhoneCommunicationLog = db.define 'phonecommunicationlog',
    'id': String
    'origin': String
    'idMesInfos': String
    'direction': String
    'timestamp': Date
    'subscriberNumber': String
    'correspondantNumber': String
    'chipCount': Number
    'chipType': String
    'type': String
    'imsi':
        'type': String
        'default': null

    'imei':
        'type': String
        'default': null
    'latitude': Number
    'longitude': Number
    'snippet': String

PhoneCommunicationLog.allLike = (cra, callback) ->
    key = [
        cra.direction
        cra.timestamp
        cra.subscriberNumber
        cra.correspondantNumber
        cra.chipCount
        cra.chipType
        cra.type
        cra.imsi
        cra.imei
        cra.latitude
        cra.longitude
    ]

    PhoneCommunicationLog.request 'allLike', key: key, (err, cras) ->
        callback err, cras