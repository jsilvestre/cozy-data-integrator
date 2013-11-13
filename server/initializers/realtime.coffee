initializer = require 'cozy-realtime-adapter'
MesInfosIntegrator = require '../models/mesinfosintegrator'
MesInfosStatuses = require '../models/mesinfosstatuses'
CozyInstance = require '../models/cozyinstance'

{startNotificationChecker, updateNotifications} = require '../lib/notification-checker'

log = ->
    if process.env.SILENT? and process.env.SILENT is "false"
        console.log.apply console, arguments

module.exports.realtimeInitializer = (app, server, callback) ->

    watchedEvents = ['user.*', 'mesinfosstatuses.update', 'cozyinstance.*']
    realtime = initializer server: server, watchedEvents

    realtime.on 'user.create', onUserCreate # Handle user registration status
    realtime.on 'mesinfosstatuses.update', onStatusesUpdate
    realtime.on 'cozyinstance.create', onInstanceAction

    # not realtime related, just post server start process
    startNotificationChecker()
    retriever = require '../lib/retriever'
    retriever.setUrl app.get('processor_url')

    callback() if callback?

onUserCreate = (event, id) ->
    log "#{event} > #{id}"
    MesInfosStatuses.getStatuses (err, statuses) ->
        if err?
            log "RealtimeAdapter > #{err}"
        else
            attr = cozy_registered: true
            statuses.updateAttributes attr, (err, statuses) ->
                log err if err?

onStatusesUpdate =  (event, id) ->
    log "#{event} > #{id}"
    MesInfosIntegrator.getConfig (err, integrator) ->
        if err?
            log err
        else
            # Sends the statuses to the data processor
            retriever = require '../lib/retriever'
            retriever.init integrator.password
            retriever.sendStatus integrator.getRegistrationStatuses()

            # Also check notifications
            updateNotifications integrator.getRegistrationStatuses()

onInstanceAction =  (event, id) ->
    CozyInstance.getInstance (err, instance) ->

        log err if err?

        mesInfosHelpURL = "http://www.enov.fr/mesinfos/"
        if instance and instance.helpUrl isnt mesInfosHelpURL
            attr =
                helpUrl: mesInfosHelpURL
                locale: 'fr'
            instance.updateAttributes attr, (err, instance) ->
                if err?
                    log "realtime # An error occurred while " + \
                                "updating CozyInstance: #{err}"
