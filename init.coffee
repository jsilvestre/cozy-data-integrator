async = require "async"

MesInfosIntegrator = require './server/models/mesinfosintegrator'
MesInfosStatuses = require './server/models/mesinfosstatuses'
CozyInstance = require './server/models/cozyinstance'
Receipt = require './server/models/receipt'
GeolocationLog = require './server/models/geoloc'
ReceiptDetail = require './server/models/receipt_details'
PhoneCommunicationLog = require './server/models/cra'

log = ->
    if process.env.SILENT? and process.env.SILENT is "false"
        console.log.apply console, arguments

# Create all requests
module.exports = init = (callback) ->
    all = (doc) -> emit doc._id, doc

    allLikeReceipt = (doc) -> emit doc.receiptId, doc
    allLikeGeoloc = (doc) -> emit doc.timestamp, doc
    allLikeReceiptDetail = (doc) ->
        emit [doc.ticketId, doc.order, doc.barcode], doc
    allLikeCRA = (doc) ->
        key = [
            doc.direction
            doc.timestamp
            doc.subscriberNumber
            doc.correspondantNumber
            doc.chipCount
            doc.chipType
            doc.type
            doc.imsi
            doc.imei
            doc.latitude
            doc.longitude
        ]
        emit key, doc

    prepareRequests = []
    # Create request and the document if not existing
    prepareRequests.push (callback) ->
        MesInfosStatuses.defineRequest 'all', all, (err) ->
            if err
                callback err
            else
                MesInfosStatuses.getStatuses (err, mis) ->
                    if err?
                        msg = "Internal error occurred, can't load the status"
                        log msg
                        callback err
                    else
                        unless mis?
                            log "No existing document, creating..."
                            MesInfosStatuses.create {}, (err, mis) ->
                                log "Statuses intialized."
                                callback err
                        else
                            callback err

    # Create request and the document if not existing
    prepareRequests.push (callback) ->
        MesInfosIntegrator.defineRequest 'all', all, (err) ->
            if err
                callback err
            else
                MesInfosIntegrator.getConfig (err, midi) ->
                    if err?
                        msg = "Internal error occurred, can't load the config"
                        log "#{msg} -- #{err}"
                        callback err
                    else
                        unless midi?
                            log "No existing document, creating..."
                            MesInfosIntegrator.create {}, (err, midi) ->
                                log "MesInfosIntegratorConfig created."
                                callback err
                        else
                            callback err

    # Create request and the document if not existing
    prepareRequests.push (callback) ->
        CozyInstance.defineRequest 'all', all, (err) ->
            callback err

    prepareRequests.push (callback) ->
        Receipt.defineRequest 'all', all, (err) ->
            callback err

    prepareRequests.push (callback) ->
        Receipt.defineRequest 'allLike', allLikeReceipt, (err) ->
            callback err

    prepareRequests.push (callback) ->
        GeolocationLog.defineRequest 'all', all, (err) ->
            callback err

    prepareRequests.push (callback) ->
        GeolocationLog.defineRequest 'allLike', allLikeGeoloc, (err) ->
            callback err

    prepareRequests.push (callback) ->
        ReceiptDetail.defineRequest 'all', all, (err) ->
            callback err

    prepareRequests.push (callback) ->
        ReceiptDetail.defineRequest 'allLike', allLikeReceiptDetail, (err) ->
            callback err

    prepareRequests.push (callback) ->
        PhoneCommunicationLog.defineRequest 'all', all, (err) ->
            callback err

    prepareRequests.push (callback) ->
        PhoneCommunicationLog.defineRequest 'allLike', allLikeCRA, (err) ->
            callback err

    async.series prepareRequests, (err, results) ->
        callback err

# so we can do "coffee init"
if not module.parent
    init (err) ->
        if err
            log "init failled"
            log err.stack
        else
            log "init success"