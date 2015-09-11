###
# Notifications schema
###

_ = require 'lodash'

urgencyLevels = [
  'Ignore'
  'Very Low'
  'Low'
  'Medium'
  'High'
  'Very High'
]
urgencyByLabel = {}
_.each urgencyLevels, (label, key) => urgencyByLabel[label] = key

module.exports = (mongoose) ->
  Schema = mongoose.Schema
  ObjectId = Schema.ObjectId

  NotificationSchema = new Schema
    navUrls: [String]
    data: {}
    text:
      type: String
      required: true
    urgency:
      type: Number
      default: 2
    read:
      type: Number # mongoose was having trouble setting read:true.. :(
      default: 0
      index: true
    component:
      type: String
    createdAt:
      type: Date
      default: Date.now
      index: true

  mongoose.model 'Notification', NotificationSchema
