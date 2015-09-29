win = $(window)
height = win.height()

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
    verticalAlign: node.el.css('vertical-align')

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
    width: node.outerWidth(true)
    height: node.outerHeight(true)
    display: node.css('display')

  unless stack[data.group]
    # TODO: reuse another stack for initial offsets
    stack[data.group] = stack.all or 0

  parent_top = parent.offset().top
  parent_height = parent.outerHeight(true)

  node.offset_top = stack[data.group]
  node.passing_top = node.offset.top - node.offset_top
  node.passing_height = node.height + node.offset_top
  node.passing_bottom = parent_top + parent_height

  data.fixed = true if node.height >= parent_height

  stack[data.group] += node.height

  unless data.fixed
    node.placeholder = placeholder(node, data)

  stickies.push node

update_all_stickies = ->
  console.log 'REFRESH'

destroy_all_stickies = ->
  console.log 'ELIMINATE'

calculate_all_stickes = ->
  scrollTop = win.scrollTop()

  stickies.forEach (sticky) ->
    return if sticky.data.fixed

    if scrollTop <= sticky.passing_top
      if sticky.el.hasClass('stuck')
        if sticky.placeholder
          sticky.placeholder.css('display', 'none')
        sticky.el.removeClass('stuck').css position: 'static'
    else
      unless sticky.el.hasClass('stuck')
        if sticky.placeholder
          sticky.placeholder.css('display', sticky.display)

        sticky.el.addClass('stuck').css
          position: 'fixed'
          width: sticky.width
          height: sticky.height
          left: sticky.offset.left
          top: sticky.offset_top

      if (scrollTop + sticky.passing_height) >= sticky.passing_bottom
        unless sticky.el.hasClass('bottom')
          sticky.el.addClass('bottom').css
            position: 'absolute'
            left: sticky.position.left
            bottom: 0
            top: 'auto'
      else
        if sticky.el.hasClass('bottom')
          sticky.el.removeClass('bottom').css
            position: 'fixed'
            left: sticky.offset.left
            top: sticky.offset_top

win.on 'touchmove', calculate_all_stickes
win.on 'scroll', calculate_all_stickes

window._destroy = destroy_all_stickies
window._update = update_all_stickies

$.fn.velcro = (params = {}) ->
  @each ->
    initialize_sticky $(this), params

  setTimeout(calculate_all_stickes, 0)
  @
