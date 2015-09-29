win = $(window)

currentState =
  stack: {}
  stickies: []

placeholder = (node, params) ->
  fixed =
    width: node.width
    height: node.height
    float: node.el.css('float')
    position: node.el.css('position')

  $('<div/>').css(fixed).css('display', 'none').insertBefore(node.el)

init_stickies = ->
  $('.is-sticky').each ->
    node = $(@)

    data = node.data('sticky') or {}
    data.group or= 'all'

    parent = if data.parent
      $(data.parent)
    else
      node.parent()

    node =
      el: node
      data: data
      offset: node.offset()
      position: node.position()
      width: node.outerWidth()
      height: node.outerHeight()
      display: node.css('display')
      isFixed: node.hasClass('fixed')

    unless node.isFixed
      node.placeholder = placeholder(node, data)

    unless currentState.stack[data.group]
      # TODO: reuse another stack for initial offsets
      currentState.stack[data.group] = currentState.stack.all or 0

    node.offset_top = currentState.stack[data.group]

    currentState.stack[data.group] += node.height

    currentState.stickies.push {
      node

      parent:
        el: parent
        offset: parent.offset()
        height: parent.outerHeight()
    }

onScroll = ->
  scrollTop = win.scrollTop()

  currentState.stickies.forEach (sticky) ->
    return if sticky.node.isFixed

    if scrollTop <= (sticky.node.offset.top - sticky.node.offset_top)
      if sticky.node.el.hasClass('stuck')
        if sticky.node.placeholder
          sticky.node.placeholder.css('display', 'none')
        sticky.node.el.removeClass('stuck').css position: 'static'
    else
      unless sticky.node.el.hasClass('stuck')
        if sticky.node.placeholder
          sticky.node.placeholder.css('display', sticky.node.display)

        sticky.node.el.addClass('stuck').css
          position: 'fixed'
          width: sticky.node.width
          height: sticky.node.height
          left: sticky.node.offset.left
          top: sticky.node.offset_top

      offsetBottom = scrollTop + sticky.node.height + sticky.node.offset_top

      if offsetBottom >= (sticky.parent.offset.top + sticky.parent.height)
        unless sticky.node.el.hasClass('bottom')
          sticky.node.el.addClass('bottom').css
            position: 'absolute'
            left: sticky.node.position.left
            bottom: 0
            top: 'auto'
      else
        if sticky.node.el.hasClass('bottom')
          sticky.node.el.removeClass('bottom').css
            position: 'fixed'
            left: sticky.node.offset.left
            top: sticky.node.offset_top

win.on 'scroll', onScroll

init_stickies()
