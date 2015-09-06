_ = require 'lodash'
React = require 'react'
Bootstrap = require 'react-bootstrap'

{DOM} = React

Collapse = React.createFactory Bootstrap.Collapse
Alert = React.createFactory Bootstrap.Alert

BasicFlash = React.createFactory React.createClass
  render: ->
    message = @props.flashMessage?.message ? @props.flashMessage
    if typeof message is 'object'
      return DOM.pre null, JSON.stringify message
    p null, message

module.exports = React.createFactory React.createClass
  getInitialState: ->
    show: false
    data: null

  componentDidMount: ->
    @socket = @props.getSocket 'kerplunk'
    @socket.on 'data', @onData

  onData: (data) ->
    return console.log 'um.. why is the flash message not mounted?' unless @isMounted()
    return unless data?.flashMessage
    flashMessage = data.flashMessage
    @setState
      show: true
      flashMessage: flashMessage
    return unless data.dismissAfter > 0
    setTimeout =>
      return unless @isMounted()
      return unless @state.flashMessage == flashMessage
      @setState
        show: false
    , data.dismissAfter

  dismissFlashMessage: ->
    @setState
      show: false

  render: ->
    ContentComponent = if @state.flashMessage?.component
      @props.getComponent @state.flashMessage.component
    else
      BasicFlash

    Collapse
      in: @state.show
      onExited: => @setState flashMessage: null
    ,
      DOM.div
        className: 'col col-lg-12'
        style:
          marginTop: '1em'
      ,
        Alert
          bsStyle: 'warning'
          onDismiss: @dismissFlashMessage
          style:
            margin: 0
        ,
          if @state.flashMessage
            ContentComponent _.extend {}, @props, @state,
              dismissFlashMessage: @dismissFlashMessage
          else
            null
