win = $(window)
height = win.height()

stack = {}
stickies = []

get_computed = (node) ->
  computed = getComputedStyle node[0]

  (name) ->
    parseFloat computed.getPropertyValue(name)

fix_outer_size = (node, width) ->
  if getComputedStyle
    prop = get_computed(node)

    x = if width then 'left' else 'top'
    y = if width then 'right' else 'bottom'

    z = prop(if width then 'width' else 'height') + prop('margin-' + x) + prop('margin-' + y)

    if prop('box-sizing') isnt 'border-box'
      z += prop('border-' + x + '-width') + prop('border-' + y + '-width') + prop('padding-' + x) + prop('padding-' + y)
    z
  else
    node[if width then 'outerWidth' else 'outerHeight'] true

placeholder = (node) ->
  fixed =
    width: node.width
    height: node.height
    float: node.el.css('float')
    position: node.el.css('position')
    verticalAlign: node.el.css('vertical-align')

  $('<div/>').css(fixed).css('display', 'none').insertBefore(node.el)

update_sticky = (node) ->
  node.offset = node.el.offset()
  node.position = node.el.position()
  node.width = fix_outer_size(node.el, true)
  node.height = fix_outer_size(node.el)

  unless stack[node.data.group]
    stack[node.data.group] = unless node.data.stack is false
      stack[node.data.stack or 'all'] or 0
    else
      0

  node.offset_top = unless node.data.stack is false
    stack[node.data.group]
  else
    0

  node.offset_height = node.height

  stack[node.data.group] += node.offset_height unless node.isFloat

  return if node.isFixed

  border_top = parseInt(node.parent.css('border-top-width'), 10)
  padding_top = parseInt(node.parent.css('padding-top'), 10)
  padding_bottom = parseInt(node.parent.css('padding-bottom'), 10)

  parent_top = node.parent.offset().top + border_top + padding_top
  parent_height = fix_outer_size(node.parent)

  offset_top = node.offset.top - (parseInt(node.el.css('margin-top'), 10) or 0)

  node.passing_top = offset_top - node.offset_top
  node.passing_height = node.offset_height + node.offset_top
  node.passing_bottom = parent_top + parent_height

  if node.data.fit
    fixed_bottom = offset_top + node.offset_height
    node.fixed_bottom = node.passing_bottom - fixed_bottom
    node.passing_bottom = fixed_bottom

    if node.height >= height
      node.height = height - node.offset_top
      node.passing_height = height

  true

initialize_sticky = (node, params = {}) ->
  data = $.extend({}, params, node.data('sticky') or {})
  data.group or= 'all'

  parent = if data.parent
    node.closest(data.parent)
  else
    node.parent()

  node =
    el: node
    data: data
    parent: parent
    offset: node.offset()
    position: node.position()
    display: node.css('display')
    isFixed: node.css('position') is 'fixed'
    isFloat: node.css('float') isnt 'none'

  if update_sticky(node)
    node.placeholder = placeholder(node)
    stickies.push(node)

check_if_can_stick = (sticky) ->
  if sticky.placeholder
    sticky.placeholder.css('display', sticky.display)

  sticky.el.addClass('stuck').css
    position: 'fixed'
    width: sticky.width
    height: if sticky.data.fit then 'auto' else sticky.height
    left: sticky.offset.left
    top: sticky.offset_top
    bottom: 0 if sticky.data.fit

check_if_can_unstick = (sticky, scroll_top) ->
  if sticky.el.hasClass('stuck')
    if sticky.placeholder
      sticky.placeholder.css('display', 'none')

    sticky.el.removeClass('stuck bottom').css position: 'static'

  if sticky.data.fit
    fitted_top = height + scroll_top - sticky.offset_top

    if fitted_top >= sticky.passing_top
      fitted_height = Math.min(fitted_top - sticky.passing_top, sticky.height)
      sticky.el.css 'height', fitted_height

check_if_can_bottom = (sticky) ->
  unless sticky.el.hasClass('bottom')
    sticky.el.addClass('bottom').css
      position: 'absolute'
      left: sticky.position.left
      bottom: sticky.fixed_bottom or 0
      top: 'auto'
      height: sticky.height if sticky.data.fit

check_if_can_unbottom = (sticky) ->
  if sticky.el.hasClass('bottom')
    sticky.el.removeClass('bottom').css
      position: 'fixed'
      left: sticky.offset.left
      top: sticky.offset_top

calculate_all_stickes = ->
  scroll_top = win.scrollTop()

  stickies.forEach (sticky) ->
    if scroll_top <= sticky.passing_top
      check_if_can_unstick(sticky, scroll_top)
    else
      unless sticky.el.hasClass('stuck')
        check_if_can_stick(sticky)

      if (scroll_top + sticky.passing_height) >= sticky.passing_bottom
        check_if_can_bottom(sticky)
      else
        check_if_can_unbottom(sticky)

refresh_all_stickies = (destroy) ->
  stack = {}
  stickies = stickies.filter (sticky) ->
    sticky.el.attr('style', '').removeClass 'stuck bottom'
    sticky.placeholder.remove()

    unless destroy
      update_sticky(sticky)
      sticky.placeholder = placeholder(sticky)
      return true

    false

win.on 'touchmove', -> calculate_all_stickes()
win.on 'scroll', -> calculate_all_stickes()
win.on 'resize', ->
  height = win.height()
  refresh_all_stickies()
  calculate_all_stickes()

$.velcro = (selector, params = {}) ->
  if selector is 'destroy'
    refresh_all_stickies(true)

  else if selector is 'update'
    refresh_all_stickies()

  else
    $(selector).each ->
      initialize_sticky $(this), params

  calculate_all_stickes()
