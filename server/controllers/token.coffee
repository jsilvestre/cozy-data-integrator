MesInfosIntegrator = require '../models/mesinfosintegrator'

# Manage the DI token
module.exports = (app) ->

    set: (req, res) ->
        token = req.params.token
        MesInfosIntegrator.getConfig (err, midi) ->

            return res.error 500, 'Internal server error', err if err

            midi.updateAttributes password: token, (err) ->
                res.error 500, 'Error while setting the token', err if err
                res.send token