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
    isFloat: node.css('float') isnt 'none'
    isFixed: node.css('position') is 'fixed'

  unless stack[data.group]
    # TODO: reuse another stack for initial offsets
    stack[data.group] = stack.all or 0

  node.offset_top = stack[data.group]

  # may be skip them while computing offsets | stack | bottom
  stack[data.group] += node.height unless node.isFloat

  return if node.isFixed

  parent_top = parent.offset().top
  parent_height = parent.outerHeight(true)

  node.passing_top = node.offset.top - node.offset_top
  node.passing_height = node.height + node.offset_top
  node.passing_bottom = parent_top + parent_height

  node.placeholder = placeholder(node, data)

  # when bottoming the stack's offset should be subtracted
  # otherwise restore it initial height for

  if node.isFloat
    # all floated stickies should fit to the viewport
    fixed_bottom = node.offset.top + node.height
    node.fixed_bottom = node.passing_bottom - fixed_bottom
    node.passing_bottom = fixed_bottom

    if node.height >= height
      node.height = height - node.offset_top
      node.passing_height = height

  stickies.push node

calculate_all_stickes = ->
  scrollTop = win.scrollTop()

  stickies.forEach (sticky) ->
    if scrollTop <= sticky.passing_top
      if sticky.el.hasClass('stuck')
        if sticky.placeholder
          sticky.placeholder.css('display', 'none')
        sticky.el.removeClass('stuck bottom').css position: 'static'

      if sticky.isFloat
        fitted_top = height + scrollTop - sticky.offset_top

        if fitted_top >= sticky.passing_top
          sticky.el.css 'height', fitted_top - sticky.passing_top
    else
      unless sticky.el.hasClass('stuck')
        if sticky.placeholder
          sticky.placeholder.css('display', sticky.display)

        sticky.el.addClass('stuck').css
          position: 'fixed'
          width: sticky.width
          height: if sticky.isFloat then 'auto' else sticky.height
          left: sticky.offset.left
          top: sticky.offset_top
          bottom: 0 if sticky.isFloat
      else
        if (scrollTop + sticky.passing_height) >= sticky.passing_bottom
          unless sticky.el.hasClass('bottom')
            sticky.el.addClass('bottom').css
              position: 'absolute'
              left: sticky.position.left
              bottom: sticky.fixed_bottom or 0
              top: 'auto'
              height: sticky.height if sticky.isFloat
        else
          if sticky.el.hasClass('bottom')
            sticky.el.removeClass('bottom').css
              position: 'fixed'
              left: sticky.offset.left
              top: sticky.offset_top

win.on 'touchmove', calculate_all_stickes
win.on 'scroll', calculate_all_stickes

$.fn.velcro = (params = {}) ->
  @each ->
    initialize_sticky $(this), params

  setTimeout(calculate_all_stickes, 0)
  @
