db = require '../db/cozy-adapter'
module.exports = ReceiptDetail = db.define 'receiptdetail',
    'id': String
    'origin': String
    'order': Number
    'barcode': String
    'label': String
    'family': String
    'familyLabel': String
    'section': String
    'sectionLabel': String
    'amount': Number
    'price': Number
    'type': String
    'typeLabel': String
    'ticketId': String
    'intermarcheShopId': String
    'timestamp': Date
    'isOnlineBuy': Boolean

ReceiptDetail.allLike = (detail, callback) ->
    key = [detail.ticketId, detail.order, detail.barcode]

    ReceiptDetail.request 'allLike', key: key, (err, receiptDetails) ->
        callback err, receiptDetails