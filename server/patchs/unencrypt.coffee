MesInfosIntegrator = require '../models/mesinfosintegrator'
Integrator = require '../models/integrator'

unencryptPassword = (callback) ->
    MesInfosIntegrator.getConfig (err, oldConfig) ->

        if err?
            msg = "error while retrieving old config -- #{err}"
            callback msg
        else if oldConfig?
            newConfig =
                token: ""
                isUpdating: oldConfig.isUpdating
                data_integrator_status: oldConfig.data_integrator_status

            Integrator.getConfig (err, config) ->
                if err?
                    msg = "error while creating new config -- #{err}"
                    callback msg
                else if config?
                    config.updateAttributes newConfig, (err) ->
                        if err? then callback err
                        else
                            oldConfig.destroy (err) ->
                                if err? then callback err
                                else callback()
                else
                    callback "> no config, shouldn't occur"
        else
            callback "> No need to patch"

module.exports.apply = ->

    unencryptPassword (err) ->
        if err? then console.log err
        else
            console.log "> Token reset with success"

