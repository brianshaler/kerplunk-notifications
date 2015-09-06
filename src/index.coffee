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
    deferred = Promise.defer()
    Notification
    .where
      read: 0
    .sort
      createdAt: -1
    .find (err, notifications) ->
      return deferred.reject err if err
      console.error err if err
      cachedNotifications = notifications
      console.log "refreshNotifications found #{notifications.length} unread notifications (#{cachedNotifications.length})"
      deferred.resolve notifications
    deferred.promise

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
    deferred = Promise.defer()
    console.log 'new notification', data.navUrls[0]
    notification = new Notification data
    notification.save (err) ->
      return deferred.reject err if err
      cachedNotifications.push notification
      deferred.resolve notification
    deferred.promise

  flashMessage = (data) ->
    notificationSocket.broadcast
      flashMessage: data
    data

  readNotificationUrl = (data) ->
    {url} = data
    console.log 'marking url as read', url
    return data unless url.length > 0

    deferred = Promise.defer()
    where =
      navUrls: url
      read: 0
    delta =
      read: 1
    options =
      multi: true
    Notification
    .update where, delta, options, (err, updateCount) ->
      return deferred.reject err if err
      console.log where, delta, options, updateCount
      console.log "updated #{JSON.stringify updateCount} notifications"
      refreshNotifications()
      .then (notifications) ->
        # notificationSocket.broadcast
        #   clearNotificationsUrl: url
        #   # state:
        #   #   notifications: notifications
        broadcastNotifications()
        deferred.resolve data
    deferred.promise

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
      styles:
        'kerplunk-notifications/css/notifications.css': ['/admin/**', '/admin/']
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
    # init:
    #   post: test

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

    refreshNotifications()
    .then ->
      next()
    # return next null, console.log 'skipping kerplunk-notifications stuff'

    ###
    Notification.remove {navUrls: url}, (err) ->
      console.error err if err
      notificationSocket.broadcast
        clearNotificationsUrl: url
      next err
    ###
