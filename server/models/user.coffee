db = require '../db/cozy-adapter'

# User defines user that can interact with the Cozy instance.
module.exports = User = db.define 'User',
    id: String
    email: String
    password: String
    timezone:
        type: String
        default: 'Europe/Paris'
    owner:
        type: Boolean
        default: false
    activated:
        type: Boolean
        default: false
