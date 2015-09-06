_ = require 'lodash'
React = require 'react'
moment = require 'moment'

{DOM} = React

module.exports = React.createFactory React.createClass
  getInitialState: ->
    createdAt: ''

  componentDidMount: ->
    createdAt = moment @props.notification.createdAt
      .format 'H:mma'
    @setState
      createdAt: createdAt

  render: ->
    unread = if @props.notification.read then '' else 'unread'
    content = if @props.notification.component
      component = @props.getComponent @props.notification.component
      component _.extend {}, @props
    else
      @props.notification.text

    DOM.div
      className: "notification #{unread}"
    ,
      DOM.div
        className: 'timestamp'
      , @state.createdAt
      DOM.a
        onClick: @props.pushState
        href: @props.notification.navUrls[0]
      , content

###
<div class="notification<%= (notification.read ? "" : " unread") %>">
  <div class="timestamp" data-moment-timestamp="<%= notification.createdAt.getTime() %>">
  </div>
  <div class="timestamp">
    (<%= notification.urgency %>) -&nbsp;
  </div>
  <%
  if (notification.data.template && (template = Kerplunk.getTemplate(notification.data.template))) {
    %>
    <a href="<%= notification.navUrls[0] %>">
      <%= template(_.merge(notification, {Kerplunk: Kerplunk})) %>
    </a>
  <% } else {
    console.log('no template?', notification.data.template);
    console.log(Kerplunk.getTemplate(notification.data.template));
    %>
    <pre><a href="<%= notification.navUrls[0] %>"><%= JSON.stringify(notification, null, 2) %></a></pre>
  <% } %>
</div>
###
