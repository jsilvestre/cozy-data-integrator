async = require "async"

NotificationHelper = require 'cozy-notifications-helper'
Notifications = new NotificationHelper 'collecteur-mesinfos'
MesInfosIntegrator = require '../models/mesinfosintegrator'

log = ->
    if process.env.SILENT? and process.env.SILENT is "false"
        console.log.apply console, arguments

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

module.exports.startNotificationChecker = ->
    module.exports.checkNotifications()
    setInterval module.exports.checkNotifications, 1000 * 60 * 60 # 1h

module.exports.checkNotifications = (callback) ->
    callback ?= ->
    MesInfosIntegrator.getConfig (err, integrator) ->
        if err?
            msg = "CheckStatuses: #{err}"
            log msg
            callback msg
        else if not integrator?
            msg = "CheckStatuses: couldn't retrieve integrator config"
            log msg
            callback msg
        else
            statuses = integrator.getRegistrationStatuses()
            module.exports.updateNotifications statuses, callback

# helper to check statuses x notification state
module.exports.updateNotifications = (statuses, callback) ->
    log "Updating notifications..."
    callback ?= ->
    process = (status, callback) ->
        isOkay = statuses[status]
        info = todos[status]
        if info?
            notifID = "mesinfos-status-#{status}"
            if isOkay
                Notifications.destroy notifID, (err) ->
                    if err?
                        msg = "Destroy Notif: #{err}"
                        log msg
                        callback msg
                    else
                        callback()
            else if (info.parent isnt null and statuses[info.parent]) \
                    or info.parent is null
                log "Create notif: #{status}"
                Notifications.createOrUpdatePersistent notifID,
                    text: todos[status].text
                    resource: todos[status].resource,
                , (err) ->
                    if err?
                        msg = "Error while updating notifications -- #{err}"
                        log msg
                        callback msg
                    else
                        callback()
            else
                callback()
        else
            callback()

    async.eachSeries Object.keys(statuses), process, callback
