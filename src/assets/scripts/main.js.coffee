win = $(window)

stack = {}
stickies = []

debounce = (fn, n) ->
  ->
    clearTimeout fn.t
    fn.t = setTimeout fn, n

placeholder = (node, params) ->
  fixed =
    width: node.width
    height: node.height
    float: node.el.css('float')
    position: node.el.css('position')

  $('<div/>').css(fixed).css('display', 'none').insertBefore(node.el)

initialize_sticky = (node, params = {}) ->
  data = $.extend({}, params, node.data('sticky') or {})
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

  unless data.fixed
    node.placeholder = placeholder(node, data)

  unless stack[data.group]
    # TODO: reuse another stack for initial offsets
    stack[data.group] = stack.all or 0

  node.offset_top = stack[data.group]

  stack[data.group] += node.height

  stickies.push {
    node

    parent:
      el: parent
      offset: parent.offset()
      height: parent.outerHeight()
  }

calculate_all_stickes = ->
  scrollTop = win.scrollTop()

  stickies.forEach (sticky) ->
    return if sticky.node.data.fixed

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

win.on 'touchmove', calculate_all_stickes
win.on 'scroll', calculate_all_stickes

$.fn.velcro = (params = {}) ->
  @each ->
    initialize_sticky $(this), params
    calculate_all_stickes()
