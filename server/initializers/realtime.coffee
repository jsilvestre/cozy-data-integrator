initializer = require('cozy-realtime-adapter')
User = require '../models/user'
MesInfosIntegrator = require '../models/mesinfosintegrator'
MesInfosStatuses = require '../models/mesinfosstatuses'

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
    google_oauth_registered:
        parent: 'privowny_oauth_registered'
        text: "N'oubliez pas de lier votre Cozy avec votre compte Google !"
        resource:
            app: "data-integrator"

# helper to check statuses x notification state
checkNotification = (statuses) ->
    console.log "Updating notifications..."
    for status, isOkay of statuses

        info = todos[status]
        if info?
            notifID = "mesinfos-status-#{status}"
            if isOkay
                Notifications.destroy notifID, (err, res, body) ->
                    console.log "Destroy Notif: #{err}" if err?
            else if (info.parent isnt null and statuses[info.parent]) \
                    or info.parent is null
                Notifications.createOrUpdatePersistent notifID,
                    text: todos[status].text
                    resource: todos[status].resource,
                    (err, res, body) ->
                        if err?
                            console.log "Error while updating notifications", err

# helper to check the statuses x notification state
checkStatuses = -> MesInfosIntegrator.getConfig (err, midi) ->
    if err?
        console.log "CheckStatuses: #{err}"
    else
        checkNotification midi.registration_status

module.exports = initRealtime = (app, server) ->

    watchedEvents = ['user.update', 'mesinfosstatuses.update']
    realtime = initializer server: server, watchedEvents

    # Adds the notification the first time
    checkStatuses()
    # Adds the notification again if the user dimisses it
    setInterval checkStatuses, 1000 * 60 * 60 # 1h

    # Detect the COZY status
    realtime.on 'user.update', (event, id) ->
        console.log "#{event} > #{id}"
        User.find id, (err, user) ->
            console.log "An error occurrend during user retrieval" if err?
            MesInfosStatuses.getStatuses (err, mis) ->
                if err?
                    console.log err
                else
                    attr = cozy_registered: user.activated
                    mis.updateAttributes attr, (err, mis) ->
                        console.log err if err?

    realtime.on 'mesinfosstatuses.update', (event, id) ->
        console.log "#{event} > #{id}"
        MesInfosIntegrator.getConfig (err, midi) ->
            if err?
                console.log err
            else
                # Sends the statuses to the data processor
                retriever = require '../lib/retriever'
                retriever.init app.get('processor_url'), midi.password
                retriever.sendStatus midi.registration_status

                # Also check notifications
                checkNotification midi.registration_status
