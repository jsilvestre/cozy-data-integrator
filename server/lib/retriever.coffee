Client = require('request-json').JsonClient
async = require 'async'
MesInfosIntegrator = require '../models/mesinfosintegrator'

class Retriever

    token: null
    clientProcessor: null
    clientDataSystem: null

    #TODO: manage authentification to the data system

    init: (url, token) ->

        unless @token? or @clientProcessor? or @clientDataSystem?
            console.log "Initialize the retriever..."
            @token = token
            @clientProcessor = new Client url
            @clientDataSystem = new Client "http://localhost:9101/"
        else
            console.log "Retriever already initialized."

    getData: (partner) ->
        url = "token/#{@token}/data/#{partner}"
        @clientProcessor.get url, (err, res, body) =>
            if err
                if res.statusCode is 401
                    console.log "Authentification error..."

                msg = "Couldn't get the data of [#{partner}] " + \
                      "from the Data Processor."
                console.log msg
            else
                # we update the "last update" date for the partner
                MesInfosIntegrator.getConfig (err, midi) =>
                    if err?
                        console.log "Retriever:getData > #{err}"
                    else
                        statuses = midi.data_integrator_status
                        statuses[partner] = {} unless statuses[partner]?
                        statuses[partner] = new Date()
                        newValue = data_integrator_status: statuses
                        midi.updateAttributes newValue, (err) =>
                            # let's add the new data to the data system
                            @putToDataSystem body

    putToDataSystem: (documentList) ->
        prepareRequests = []
        for doc in documentList
            prepareRequests.push (callback) =>
                @clientDataSystem.post 'data/', doc, (err, res, body) ->
                    if err?
                        callback("#{res.statusCode} - #{err}", null)
                    else
                        callback(null, body._id)
        console.log "Requesting the processor the new data to add..."
        async.parallel prepareRequests, (err, results) ->
            console.log "Documents added to the data system."
            console.log err if err?
            console.log results if results.length? and results.length > 0


    sendStatus: (statuses) ->
        console.log "Sending status to the processor..."
        url = "token/#{@token}/status/"
        @clientProcessor.post url, statuses, (err, res, body) ->
            if err?
                console.log "Send statuses: #{err}"
            else
                console.log "#{res.statusCode} - #{body}"

module.exports = new Retriever()