initializer = require('cozy-realtime-adapter')
User = require '../models/user'
MesInfosIntegrator = require '../models/mesinfosintegrator'
MesInfosStatuses = require '../models/mesinfosstatuses'
CozyInstance = require '../models/cozyinstance'

NotificationHelper = require('cozy-notifications-helper')
Notifications = new NotificationHelper('data-integrator')

todos =
    privowny_registered:
        parent: null
        text: "N'oubliez pas de vous inscrire sur Privowny !"
        resource:
            app: "privowny"
    privowny_oauth_registered:
        parent: 'privowny_registered'
        text: "N'oubliez pas de lier votre Cozy avec votre compte Privowny !"
        resource:
            app: "privowny"
###
    google_oauth_registered:
        parent: 'privowny_oauth_registered'
        text: "Importez vos contacts, agendas et photos depuis votre " +\
              "compte Google ou indiquez que vous n'en avez pas !"
        resource:
            app: "collecteur-mesinfos"
###
# helper to check statuses x notification state
checkNotification = (statuses) ->
    console.log "Updating notifications..."
    for status, isOkay of statuses

        info = todos[status]
        if info?
            notifID = "mesinfos-status-#{status}"
            if isOkay
                Notifications.destroy notifID, (err, res, body) ->
                    console.log "Destroy Notif: #{err} (does not exist)" if err?
            else if (info.parent isnt null and statuses[info.parent]) \
                    or info.parent is null
                console.log "Create notif: #{status}"
                Notifications.createOrUpdatePersistent notifID,
                    text: todos[status].text
                    resource: todos[status].resource,
                    (err, res, body) ->
                        if err?
                            errorMsg = "Error while updating notifications"
                            console.log errorMsg, err

# helper to check the statuses x notification state
checkStatuses = -> MesInfosIntegrator.getConfig (err, integrator) ->
    if err?
        console.log "CheckStatuses: #{err}"
    else
        checkNotification integrator.registrationStatuses

module.exports = initRealtime = (app, server) ->

    watchedEvents = ['user.*', 'mesinfosstatuses.update', 'cozyinstance.*']
    realtime = initializer server: server, watchedEvents

    # Adds the notification the first time
    checkStatuses()
    # Adds the notification again if the user dimisses it
    setInterval checkStatuses, 1000 * 60 * 60 # 1h

    # Detect the COZY status
    realtime.on 'user.create', (event, id) ->
        console.log "#{event} > #{id}"
        User.find id, (err, user) ->
            console.log "An error occurrend during user retrieval" if err?
            MesInfosStatuses.getStatuses (err, mis) ->
                if err?
                    console.log "RealtimeAdapter > #{err}"
                else
                    attr = cozy_registered: user.activated
                    mis.updateAttributes attr, (err, mis) ->
                        console.log err if err?

    realtime.on 'mesinfosstatuses.update', (event, id) ->
        console.log "#{event} > #{id}"
        MesInfosIntegrator.getConfig (err, integrator) ->
            if err?
                console.log err
            else
                # Sends the statuses to the data processor
                retriever = require '../lib/retriever'
                retriever.init app.get('processor_url'), integrator.password
                retriever.sendStatus integrator.registration_status

                # Also check notifications
                checkNotification integrator.registration_status

    realtime.on 'cozyinstance.*', (event, id) ->
        CozyInstance.getInstance (err, instance) ->

            console.log err if err?

            mesInfosHelpURL = "http://www.enov.fr/mesinfos/"
            if instance and instance.helpUrl isnt mesInfosHelpURL
                attr =
                    helpUrl: mesInfosHelpURL
                    locale: 'fr'
                instance.updateAttributes attr, (err, instance) ->
                    if err?
                        console.log "realtime # An error occurred while " + \
                                    "updating CozyInstance: #{err}"
