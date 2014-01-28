db = require '../db/cozy-adapter'
module.exports = Receipt = db.define 'Receipt',
    'id': String
    'receiptId': String
    'transactionCode': String
    'transaction': String
    'transactionId': String
    'timestamp': Date
    'checkoutId': String
    'checkoutReceiptId': String
    'cashierId': String
    'articlesCount': Number
    'amount': Number
    'loyaltyBalance': Number
    'convertedPoints': Number
    'acquiredPoints': Number
    'intermarcheShopId': String
    'total': Number
    'paidAmound': Number
    'isOnline': Boolean
    'snippet': String

Receipt.allLike = (receipt, callback) ->
    key = receipt.receiptId

    Receipt.request 'allLike', key: key, (err, receipts) ->
        callback err, receipts