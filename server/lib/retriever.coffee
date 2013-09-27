Client = require('request-json').JsonClient
async = require 'async'
MesInfosIntegrator = require '../models/mesinfosintegrator'

class Retriever

    token: null
    clientProcessor: null
    clientDataSystem: null

    init: (url, token) ->
        unless @token? or @clientProcessor? or @clientDataSystem?
            console.log "Initialize the retriever..."
            @token = token
            @clientProcessor = new Client url
            @clientDataSystem = new Client "http://localhost:9101/"

            # DS authentification in production
            if process.env.NODE_ENV is "production"
                console.log "Setting basic authentification..."
                username = process.env.NAME
                password = process.env.TOKEN
                @clientDataSystem.setBasicAuth username, password
        else
            console.log "Retriever already initialized."

    getData: (partner, controllerCallback) ->
        @token = "testblabla" if not process.env.NODE_ENV? \
                                 or process.env.NODE_ENV is "development"

        url = "token/#{@token}/data/#{partner}"
        # retrieve the data from the processor
        @clientProcessor.get url, (err, res, body) =>
            if err
                if res?.statusCode is 401
                    console.log "Authentification error..."

                msg = "Couldn't get the data of [#{partner}] " + \
                      "from the Data Processor. -- #{err}"
                console.log msg
                controllerCallback msg
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
                            @putToDataSystem body, controllerCallback

    putToDataSystem: (documentList, controllerCallback) ->
        prepareRequests = []

        # we need to make a 'factory' to run the code in a loop
        pushFactory = (clientDS, document) -> (callback) =>
            data = document.doc

            # Update is done considering a the "pkField"
            if document.action is "update" and document.pkField?

                allRequestURL = "request/#{data.docType}/"
                allRequestUrl += "allby#{document.pkField}/"

                # we define the request textually to allow the parameters to be
                # interpreted all the doc indexed by the pkField
                allRequest =
                    map: """
                        function (doc) {
                            if (doc.docType === "#{data.docType}") {
                                return emit(doc.#{document.pkField}, doc);
                            }
                        }
                    """
                msg = "Create request by#{document.pkField} "
                msg += "for doctype #{data.docType} to make sure it exists..."
                console.log msg
                clientDS.put allRequestURL, allRequest, (err, res, body) =>

                    # request a specific document among the doctype's documents
                    requestedKey = {}
                    requestedKey[document.pkField] = {}
                    requestedKey[document.pkField] = data[document.pkField]
                    # Now we request the request to see if the document already
                    # exists
                    dsData = {key: data[document.pkField]}
                    clientDS.post allRequestURL, dsData, (err, res, body) ->
                        console.log "[error][#{res.statusCode}] #{err}" if err?
                        if body? and body.length > 0 # update the existing doc
                            url = "data/#{body[0].id}/"
                            console.log "update !"

                            clientDS.put url, data, (err, res, body) ->
                                if err?
                                    callback "#{res.statusCode} - #{err}", null
                                else
                                    callback null, body[0].id
                        else # create a new doc
                            clientDS.post 'data/', data, (err, res, body) ->
                                if err?
                                    callback "#{res.statusCode} - #{err}", null
                                else
                                    callback null, body._id

            else # it is just a create action
                clientDS.post 'data/', data, (err, res, body) ->
                    if err?
                        callback "#{res.statusCode} - #{err}", null
                    else
                        callback null, body._id

        console.log "> #{documentList.length} docs to add"
        for document in documentList
            prepareRequests.push pushFactory @clientDataSystem, document

        console.log "Adding requested data to the data system..."
        async.series prepareRequests, (err, results) ->
            console.log "Documents added or updated to the data system."
            console.log err if err?
            if results? and results.length? and results.length > 0
                nbDocs = results.length
                console.log "> amount of added or updated docs: #{nbDocs}"

            controllerCallback err

    # Update the processor with cozy's status
    sendStatus: (statuses) ->
        console.log "Sending status to the processor..."
        url = "token/#{@token}/status/"
        @clientProcessor.post url, statuses, (err, res, body) ->
            if err?
                console.log "Send statuses: #{err}"
            else
                console.log "#{res.statusCode} - #{body}"

module.exports = new Retriever()
