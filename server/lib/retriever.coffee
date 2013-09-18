Client = require('request-json').JsonClient
async = require 'async'
MesInfosIntegrator = require '../models/mesinfosintegrator'

class Retriever

    token: null
    clientProcessor: null
    clientDataSystem: null
    doctypeList: []

    init: (url, token) ->
        unless @token? or @clientProcessor? or @clientDataSystem?
            console.log "Initialize the retriever..."
            @token = token
            @clientProcessor = new Client url
            @clientDataSystem = new Client "http://localhost:9101/"
            if process.env.NODE_ENV is "production"
                console.log "Setting basic authentification..."
                username = process.env.NAME
                password = process.env.TOKEN
                @clientDataSystem.setBasicAuth username, password

            @clientDataSystem.get 'doctypes/', (err, res, body) =>
                console.log err if err?
                console.log body
                @doctypeList = body

        else
            console.log "Retriever already initialized."

    getData: (partner, controllerCallback) ->
        url = "token/#{@token}/data/#{partner}"
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
                            console.log body
                            @putToDataSystem body, controllerCallback

    putToDataSystem: (documentList, controllerCallback) ->
        prepareRequests = []

        pushFactory = (clientDS, document) -> (callback) =>
            data = document.doc
            if document.action is "update" and document.pkField?

                # The url to create the request
                allRequestURL = "request/#{data.docType}/by#{document.pkField}/"

                # we define the request textually to allow the parameters to be interpreted
                allRequest =
                    map: """
                        function (doc) {
                            if (doc.docType === "#{data.docType}") {
                                return emit(doc.#{document.pkField}, doc);
                            }
                        }
                    """
                console.log "Create request by#{document.pkField} for doctype #{data.docType} to make sure it exists..."
                clientDS.put allRequestURL, allRequest, (err, res, body) =>

                    # request a specific document among the doctype's documents
                    requestedKey = {}
                    requestedKey[document.pkField] = {}
                    requestedKey[document.pkField] = data[document.pkField]
                    # Now we request the request to see if the document already exists
                    clientDS.post allRequestURL, {key: data[document.pkField]}, (err, res, body) ->
                        console.log "[error][#{res.statusCode}] #{err}" if err?
                        if body? and body.length > 0 # update the existing doc
                            url = "data/#{body[0].id}/"
                            clientDS.put url, data, (updateErr, updateRes, updateBody) ->
                                if updateErr?
                                    callback "#{updateRes.statusCode} - #{updateErr}", null
                                else
                                    console.log res.statusCode
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

        # create the "all" request
        accessFactory = (doctype) -> (callback) =>
            # The url to create the request
            allRequestURL = "request/#{doctype}/all/"

            # we define the request textually to allow the parameters to be interpreted
            allRequest =
                map: """
                    function (doc) {
                        if (doc.docType === "#{doctype}") {
                            return emit(doc.id, doc);
                        }
                    }
                """
            console.log "Create request all for doctype #{doctype} to make sure it exists..."
            clientDS.put allRequestURL, allRequest, (err, res, body) =>
                if err?
                    console.log err
                else
                    @doctypeList.push doctype


        for document in documentList
            prepareRequests.push pushFactory @clientDataSystem, document
            if document.docType not in @doctypeList
                accessRequests.push accessFactory document.docType
                @doctypeList.push document.docType # to avoid multiple requests

        console.log "Requesting the processor the new data to add..."
        async.series prepareRequests, (err, results) ->
            console.log "Documents added or updated to the data system."
            console.log err if err?
            console.log results if results.length? and results.length > 0
            controllerCallback err


    sendStatus: (statuses) ->
        console.log "Sending status to the processor..."
        url = "token/#{@token}/status/"
        @clientProcessor.post url, statuses, (err, res, body) ->
            if err?
                console.log "Send statuses: #{err}"
            else
                console.log "#{res.statusCode} - #{body}"

module.exports = new Retriever()