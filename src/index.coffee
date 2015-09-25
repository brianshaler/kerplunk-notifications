Promise = require 'when'

NotificationSchema = require './models/Notification'

module.exports = (System) ->
  Notification = System.registerModel 'Notification', NotificationSchema

  cachedNotifications = []
  notificationSocket = null

  showNotifications = (req, res, next) ->
    where =
      urgency:
        '$gt': 1
    Notification
    .where where
    .sort
      createdAt: -1
    .limit 20
    .find (err, notifications) ->
      return next err if err
      res.render 'list',
        allNotifications: notifications

  refreshNotifications = ->
    mpromise = Notification
    .where
      read: 0
    .sort
      createdAt: -1
    .find()
    Promise(mpromise).then (notifications) ->
      cachedNotifications = notifications
      console.log "refreshNotifications found #{notifications.length} unread notifications (#{cachedNotifications.length})"
      notifications

  postInit = ->
    refreshNotifications()
    .then ->

  broadcastNotification = (notification) ->
    notificationSocket.broadcast
      notifications: [notification]
      state:
        notifications: cachedNotifications
    notification

  broadcastNotifications = (data) ->
    notificationSocket.broadcast
      state:
        notifications: cachedNotifications
    data

  createNotification = (data) ->
    console.log 'new notification', data.navUrls[0]
    notification = new Notification data
    mpromise = notification.save()
    Promise(mpromise).then ->
      cachedNotifications.push notification
      notification

  flashMessage = (data) ->
    notificationSocket.broadcast
      flashMessage: data
    data

  readNotificationUrl = (data) ->
    {url} = data
    console.log 'marking url as read', url
    return data unless url.length > 0

    Promise.promise (resolve, reject) ->
      where =
        navUrls: url
        read: 0
      delta =
        read: 1
      options =
        multi: true
      Notification
      .update where, delta, options, (err, updateCount) ->
        return reject err if err
        console.log where, delta, options, updateCount
        console.log "updated #{JSON.stringify updateCount} notifications"
    .then refreshNotifications
    .then (notifications) ->
      # notificationSocket.broadcast
      #   clearNotificationsUrl: url
      #   # state:
      #   #   notifications: notifications
      broadcastNotifications()
      data

  # test = ->
  #   System.do

  routes:
    admin:
      '/admin/notifications': 'showNotifications'

  handlers:
    showNotifications: showNotifications

  globals:
    public:
      navbar:
        'kerplunk-notifications:navbar': true
      layout:
        preContent:
          flashNotification: 'kerplunk-notifications:flash'
      nav:
        Admin:
          Notifications: '/admin/notifications'
      css:
        'kerplunk-notifications:list': 'kerplunk-notifications/css/notifications.css'
        'kerplunk-notifications:navbar': 'kerplunk-notifications/css/notifications.css'
        'kerplunk-notifications:flash': 'kerplunk-notifications/css/notifications.css'
  events:
    notification:
      create:
        do: createNotification
        post: broadcastNotification
      read:
        do: readNotificationUrl
        post: broadcastNotifications
      flash:
        do: flashMessage
    init:
      post: postInit

  init: (next) ->
    notificationSocket = System.getSocket 'kerplunk'
    notificationSocket.on 'connection', (spark) ->
      spark.write
        state:
          notifications: cachedNotifications

    notificationSocket.on 'receive', (spark, data) ->
      if data.currentUrl
        System.do 'notification.read',
          url: data.currentUrl
      else if data.notificationTest
        System.do 'notification.create',
          text: 'testing ' + Math.floor Math.random() * 10000
          navUrls: ['/admin/irc/channel/irc.freenode.net/kerplunk/show']
          component: 'kerplunk-irc:notification'
          data:
            serverName: 'server.com'
            channelName: 'thechannel'
            message:
              nick: 'sender'
              message: 'sup'
      else if data.getNotifications
        spark.write
          state:
            notifications: cachedNotifications

    next()
