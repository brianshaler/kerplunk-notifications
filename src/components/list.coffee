_ = require 'lodash'
React = require 'react'

Notification = require './notification'

{DOM} = React

module.exports = React.createFactory React.createClass
  getInitialState: ->
    notifications: @props.allNotifications ? []

  componentDidMount: ->
    @socket = @props.getSocket 'kerplunk'
    @socket.on 'data', @onData

  componentWillUnmount: ->
    @socket.off 'data', @onData

  componentWillReceiveProps: (newProps) ->
    return unless newProps.notification or newProps.notifications or newProps.allNotifications
    obj = {}
    for n in @state.notifications
      obj[n._id] = n
    for n in (newProps.notifications ? [])
      obj[n._id] = n
    for n in (newProps.allNotifications ? [])
      obj[n._id] = n
    if newProps.notification?._id
      obj[newProps.notification._id] = newProps.notification

    notifications = _ obj
      .sortByOrder 'createdAt', 'desc'
      .value()
    @setState
      notifications: notifications

  onData: (data) ->
    return console.log 'stahp', data unless @isMounted()
    if data.clearNotificationsUrl
      @clearNotificationsUrl data.clearNotificationsUrl
    else if data.notification
      @onNotification data.notification
    else
      console.log 'ignore', data
    #@setState data

  onNotification: (obj) ->
    console.log 'notification', obj
    newNotifications = _([obj].concat @state.notifications)
      .uniq '_id'
      .value()

    @setState
      notifications: newNotifications

  clearNotificationsUrl: (url) ->
    console.log 'clearNotificationsUrl', obj
    @setState
      notifications: _.filter @state.notifications, (notification) ->
        return false if -1 < notification.navUrls?.indexOf url
        true

  fakeNotification: (e) ->
    e.preventDefault()
    url = @refs.fakeUrl.getDOMNode().value
    text = @refs.fakeText.getDOMNode().value
    @socket.write
      echo:
        notification:
          _id: String Math.floor Math.random() * 1000000
          navUrls: [url]
          text: text
          read: 0
          urgency: 1
    return

  clearFakeNotification: (e) ->
    e.preventDefault()
    url = @refs.fakeUrl.getDOMNode().value
    # @clearNotification url
    @socket.write
      echo:
        clearNotification: url
    return

  create: (e) ->
    e.preventDefault()
    @socket.write
      notificationTest: true
    return

  render: ->
    DOM.section
      className: 'content admin-panel'
    ,
      DOM.h2 null, 'Notifications'
      DOM.div null,
        DOM.input
          ref: 'fakeText'
          placeholder: 'text'
        DOM.input
          ref: 'fakeUrl'
          placeholder: 'url'
      DOM.div null,
        DOM.a
          href: '#'
          onClick: @fakeNotification
          className: 'btn btn-default'
        , 'fake notification'
        ' '
        DOM.a
          href: '#'
          onClick: @clearFakeNotification
          className: 'btn btn-default'
        , 'clear notification'
        ' '
        DOM.a
          href: '#'
          onClick: @create
          className: 'btn btn-default'
        , 'create'
      DOM.div null,
        _.map @state.notifications, (notification) =>
          Notification _.extend {}, @props,
            key: "notification-#{notification._id}"
            notification: notification
