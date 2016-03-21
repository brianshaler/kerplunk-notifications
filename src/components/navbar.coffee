_ = require 'lodash'
React = require 'react'

Notification = require './notification'

{DOM} = React

diffArrays = (arr1 = [], arr2 = []) ->
  return false if arr1.length != arr2.length
  for item, index in arr1
    if arr1[index] != arr2[index]
      return false
  true

module.exports = React.createFactory React.createClass
  getInitialState: ->
    expanded: false

  componentDidMount: ->
    @socket = @props.getSocket 'kerplunk'
    @markRead()

  componentDidUpdate: (prevProps, prevState) ->
    changed = false
    # console.log 'nav did update',
    #   prevProps.currentUrl
    #   @props.currentUrl
    #   prevProps.notifications?.length ? 0
    #   @props.notifications?.length ? 0
    if prevProps.currentUrl != @props.currentUrl
      changed = true
      @setState
        expanded: false
    else
      prevIds = _.map (prevProps.notifications ? []), '_id'
      newIds = _.map (@props.notifications ? []), '_id'
      if !diffArrays prevIds, newIds
        changed = true
    if changed
      @markRead()

  markRead: (url = @props.currentUrl) ->
    return unless url?.length > 0
    return unless @props.notifications?.length > 0
    for notification in @props.notifications
      for navUrl in notification?.navUrls
        if navUrl == url
          @socket?.write
            currentUrl: url
          return

  toggle: (e) ->
    e.preventDefault()
    @setState
      expanded: !@state.expanded

  goToNotifications: (e) ->
    @setState
      expanded: false
    @props.pushState e

  render: ->
    notifications = @props.notifications ? []
    total = notifications.length

    classes = ['dropdown-menu']
    if @state.expanded
      classes.push 'show'

    DOM.li
      className: 'dropdown notifications-menu'
    ,
      DOM.a
        href: '#'
        className: 'dropdown-toggle'
        onClick: @toggle
      ,
        DOM.em className: 'fa fa-warning'
        DOM.span
          className: 'label label-warning notifications-count-nozero'
        ,
          if total > 0 then total else ''
      DOM.ul
        className: classes.join ' '
      ,
        DOM.li
          className: 'header'
        ,
          "You have #{total} notification#{if total == 1 then '' else 's'}"
        DOM.li null,
          DOM.ul
            className: 'menu'
          ,
            _.map notifications, (notification) =>
              Notification _.extend {}, @props,
                key: "navbar-notification-#{notification._id}"
                notification: notification

        DOM.li
          className: 'footer'
        ,
          DOM.a
            onClick: @goToNotifications
            href: '/admin/notifications'
          , 'View all'
