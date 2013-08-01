async = require "async"

MesInfosIntegrator = require './server/models/mesinfosintegrator'
MesInfosStatuses = require './server/models/mesinfosstatuses'

# Create all requests
module.exports = init = (callback) ->
    all = (doc) -> emit doc._id, doc

    prepareRequests = []

    # Create request and the document if not existing
    prepareRequests.push (callback) ->
        MesInfosIntegrator.defineRequest 'all', all, (err) ->
            if err
                callback err
            else
                MesInfosIntegrator.getConfig (err, midi) ->
                    if err?
                        msg = "Internal error occurred, can't load the config"
                        console.log msg
                        callback err
                    else
                        if midi.length is 0
                            console.log "No existing document, creating..."
                            MesInfosIntegrator.create {}, (err, midi) ->
                                console.log "Config created."
                                callback err
                        else
                            callback err

    # Create request and the document if not existing
    prepareRequests.push (callback) ->
        MesInfosStatuses.defineRequest 'all', all, (err) ->
            if err
                callback err
            else
                MesInfosStatuses.getStatuses (err, mis) ->
                    if err?
                        msg = "Internal error occurred, can't load the status"
                        console.log msg
                        callback err
                    else
                        if mis.length is 0
                            console.log "No existing document, creating..."
                            MesInfosStatuses.create {}, (err, mis) ->
                                console.log "Statuses intialized."
                                callback err
                        else
                            callback err
    async.series prepareRequests, (err, results) ->
        callback(err)

# so we can do "coffee init"
if not module.parent
    init (err) ->
        if err
            console.log "init failled"
            console.log err.stack
        else
            console.log "init success"