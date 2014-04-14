moment = require 'moment'
async = require 'async'

Receipt = require '../models/receipt'
Geoloc = require '../models/geoloc'
ReceiptDetail = require '../models/receipt_details'
PhoneCommunicationLog = require '../models/cra'

destroyProcess = (model, callback) ->
    model.destroy callback

retrieveDuplicatesProcess = (doctype) -> (oneDoc, callback) ->
    doctypeName = doctype.toString()

    doctype.allLike oneDoc, (err, duplicates) ->
        if duplicates? and duplicates.length > 1
            duplicates.shift() # we want to keep on examplar
            console.log "\t#{duplicates.length} duplicates found for #{doctypeName}!"
            async.each duplicates, destroyProcess, (err) ->
                console.log "\t> duplicates removed" unless err?
                callback err
        else
            callback err

deduplicateDoctype = (doctype) -> (callback) ->
    doctypeName = doctype.toString()

    console.log "Start of dedudplication for #{doctypeName}"
    doctype.all (err, allDocuments) ->
        async.eachSeries allDocuments, retrieveDuplicatesProcess(doctype), (err) ->
            if err?
                console.log err
            console.log "End of deduplication for #{doctypeName}"
            callback err

deduplicate = ->

    console.log "Start of deduplication round..."
    deduplications = [
        deduplicateDoctype Receipt
        deduplicateDoctype Geoloc
        deduplicateDoctype ReceiptDetail
        deduplicateDoctype PhoneCommunicationLog
    ]
    async.series deduplications, (err) ->
        console.log err if err?
        console.log "End of deduplication round."
        module.exports.apply()

module.exports.apply = ->

    delta =  Math.floor(Math.random() * 5 * 60)
    now = moment()
    patchTime = now.clone().add(1, 'days')
                        .hours(2)
                        .minutes(delta)
                        .seconds(0)
    #patchTime = now.clone().add(5, 'seconds') # dev mode
    setTimeout(
        () -> deduplicate()
    , patchTime.diff(now))

    format = "DD/MM/YYYY [at] HH:mm:ss"
    console.log "> Next patch apply at #{patchTime.format(format)}"

