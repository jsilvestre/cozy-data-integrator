MesInfosIntegrator = require '../models/integrator'

# Manage the DI token
module.exports = (app) ->

    set: (req, res) ->
        token = req.params.token
        MesInfosIntegrator.getConfig (err, integrator) ->
            return res.error 500, 'Internal server error', err if err

            if integrator?.token? and integrator.token isnt ""
                res.send 403, error: "token alread set"
            else
                integrator.updateAttributes token: token, (err) ->
                    res.error 500, 'Error while setting the token', err if err
                    res.send token: token
