win = $(window)
doc = $(document.documentElement)

currentState =
  stack: {}
  stickies: []

debounce = (fn, n) ->
  ->
    clearTimeout fn.t
    fn.t = setTimeout fn, n

placeholder = (node, params) ->
  css =
    position: node.el.position()
    cssFloat: node.el.css('float')
    cssDisplay: node.el.css('display')
    cssPosition: node.el.css('position')

  fixed =
    width: node.width
    height: node.height
    float: css.cssFloat
    position: css.cssPosition

  el = $('<div/>').css(fixed)
    .css('display', 'none')
    .insertBefore(node.el)

  { el, css }

init_stickies = ->
  $('.is-sticky').each ->
    node = $(@)

    data = node.data('sticky') or {}
    data.group or= 'all'

    parent = node.parent()

    node =
      el: node
      data: data
      offset: node.offset()
      width: node.outerWidth()
      height: node.outerHeight()
      isFixed: node.hasClass('fixed')

    unless node.isFixed
      node.placeholder = placeholder(node, data)

    unless currentState.stack[data.group]
      # TODO: reuse another stack for initial offsets
      currentState.stack[data.group] = currentState.stack.all or 0

    node.offset.fixed = currentState.stack[data.group]

    currentState.stack[data.group] += node.height

    currentState.stickies.push {
      node

      parent:
        el: parent
        offset: parent.offset()
        height: parent.outerHeight()
    }

lastScroll = -1

onScroll = ->
  scrollTop = win.scrollTop()

  currentState.stickies.forEach (sticky) ->
    return if sticky.node.isFixed

    if scrollTop <= (sticky.node.offset.top - sticky.node.offset.fixed)
      if sticky.node.el.hasClass('stuck')
        sticky.node.placeholder.el.hide() if sticky.node.placeholder
        sticky.node.el.removeClass('stuck').css position: 'static'
        # TODO: how to reset it dimensions?
    else
      offsetBottom = scrollTop + sticky.node.height + sticky.node.offset.fixed

      if offsetBottom >= (sticky.parent.offset.top + sticky.parent.height)
        unless sticky.node.el.hasClass('bottom')
          sticky.node.el.addClass('bottom').css
            position: 'absolute'
            left: 'auto'
            top: 'auto'
      else
        if sticky.node.el.hasClass('bottom')
          sticky.node.el.removeClass('bottom').css
            position: 'fixed'
            left: sticky.node.offset.left
            top: sticky.node.offset.fixed

      unless sticky.node.el.hasClass('stuck')
        sticky.node.placeholder.el.show() if sticky.node.placeholder
        sticky.node.el.addClass('stuck').css
          position: 'fixed'
          width: sticky.node.width
          height: sticky.node.height
          left: sticky.node.offset.left
          top: sticky.node.offset.fixed

win.on 'scroll', onScroll

init_stickies()
