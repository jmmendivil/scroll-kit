group_id = 0

# :)
stack =
  nodes: []
  offsets: {}

# cached
win = $(window)
win_height = win.height()

placeholder = (node) ->
  fixed =
    width: node.width
    height: node.orig_height
    float: node.el.css('float')
    position: node.el.css('position')
    verticalAlign: node.el.css('vertical-align')

  $('<div/>').css(fixed).css('display', 'none').insertBefore(node.el)

update_sticky = (node) ->
  unless stack.offsets[node.data.group]
    stack.offsets[node.data.group] = node.data.offset or 0

  node.offset_top = stack.offsets[node.data.group]

  # original value
  node.orig_height = node.el.outerHeight(true)

  # increment the node offset_top based on current group/stack
  stack.offsets[node.data.group] += node.orig_height unless node.isFloat

  return true if node.isFixed

  parent_top = node.parent.offset().top
  parent_height = node.parent.height()

  node.offset = node.el.offset()
  node.height = node.orig_height
  node.width = node.el.outerWidth()
  node.position = node.el.position()

  node.passing_top = node.offset.top - node.offset_top
  node.passing_height = node.orig_height + node.offset_top
  node.passing_bottom = parent_top + parent_height

  if node.data.fit
    if node.isFloat
      fixed_bottom = node.offset.top + node.orig_height
      node.fixed_bottom = node.passing_bottom - fixed_bottom
      node.passing_bottom = fixed_bottom

    if node.height >= win_height
      node.passing_height = win_height
      node.height = win_height - node.offset_top

  true

initialize_sticky = (node, params = {}) ->
  data = $.extend({}, params, node.data('sticky') or {})

  # used for internal stacks
  data.group or= 0

  parent = if data.parent
    node.closest(data.parent)
  else
    node.parent()

  # auto-grouping
  unless data.group
    unless parent.data('velcro_gid') > 0
      parent.data 'velcro_gid', group_id += 1

  data.group += '.' + (parent.data('velcro_gid') or 0)

  node =
    el: node
    data: data
    parent: parent
    offset: node.offset()
    position: node.position()
    display: node.css('display')
    isFloat: node.css('float') isnt 'none'
    isFixed: data.fixed or (node.css('position') is 'fixed')

  if update_sticky(node)
    node.placeholder = placeholder(node)
    stack.nodes.push(node)

check_if_fit = (sticky, scroll_top) ->
  if sticky.data.fit
    fitted_top = win_height + scroll_top - sticky.offset_top

    if fitted_top >= sticky.passing_top
      sticky.el.addClass('fit') unless sticky.el.hasClass('fit')
      sticky.el.css 'height', Math.min(fitted_top - sticky.passing_top, sticky.height)
    else
      sticky.el.removeClass('fit') if sticky.el.hasClass('fit')

check_if_can_stick = (sticky, scroll_top) ->
  unless sticky.el.hasClass('stuck')
    if sticky.placeholder
      sticky.placeholder.css('display', sticky.display)

    sticky.el.addClass('stuck').css
      position: 'fixed'
      width: sticky.width
      height: sticky.height
      left: sticky.offset.left
      top: sticky.offset_top
      bottom: 0 if sticky.data.fit

check_if_can_unstick = (sticky, scroll_top) ->
  if sticky.el.hasClass('stuck')
    if sticky.placeholder
      sticky.placeholder.css('display', 'none')

    sticky.el.removeClass('fit stuck bottom').attr 'style', ''

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

  stack.nodes.forEach (sticky) ->
    return if sticky.isFixed

    if scroll_top <= sticky.passing_top
      check_if_can_unstick(sticky, scroll_top)
    else
      check_if_can_stick(sticky, scroll_top)

      if (scroll_top + sticky.passing_height) >= sticky.passing_bottom
        check_if_can_bottom(sticky)
      else
        check_if_can_unbottom(sticky)

    check_if_fit(sticky, scroll_top)

  # return
  undefined

refresh_all_stickies = (destroy) ->
  # reindex
  stack.offsets = {}

  # forced update always!
  win_height = win.height()

  # filter out removed elements?
  stack.nodes = stack.nodes.filter (sticky) ->
    sticky.el.attr('style', '').removeClass 'fit stuck bottom'
    sticky.placeholder.remove()

    unless destroy
      update_sticky(sticky)
      sticky.placeholder = placeholder(sticky)
      return true

    false

update_everything = (destroy) ->
  refresh_all_stickies(destroy)
  calculate_all_stickes()

win.on 'touchmove scroll', ->
  calculate_all_stickes()

win.on 'resize', ->
  update_everything()

$.scrollKit = (selector, params = {}) ->
  if selector is 'destroy'
    update_everything(true)
  else
    unless selector is 'update'
      $(selector).each ->
        initialize_sticky $(this), params

    update_everything()

  # return
  undefined
