group_id = 0

last_scroll = -1
last_direction = ''

static_interval = null

# :)
stack =
  offsets: {}
  stickyNodes: []
  contentNodes: []
  contentNodes_length: 0

# cached
win = $(window)
win_height = win.height()

# use for directions
body = $(document.body)

set_classes = (name) ->
  unless body.hasClass(name)
    body.removeClass('backward forward static').addClass(name)
    last_direction = name

test_on_scroll = (offset) ->
  unless offset
    body.removeClass('on-scroll') if body.hasClass('on-scroll')
  else
    body.addClass('on-scroll') unless body.hasClass('on-scroll')

  set_classes if offset < last_scroll
    'backward'
  else if offset > last_scroll
    'forward'
  else
    'static'

  clearTimeout static_interval
  static_interval = setTimeout ->
    set_classes('static')
  , 200

update_offsets = (node) ->
  # store a jQuery reference due its usefulness D:
  node.el = $(node) unless node.el

  # liveNodes are also providing live storage for free!
  node.offset =
    top: node.el.offset().top
    height: node.el.outerHeight(true)
    is_passing: node.offset and node.offset.is_passing

update_metrics = (i, node, scroll_top) ->
  fixed_bottom = (win_height - node.offset.top) + scroll_top

  if node.offset.top_from_bottom isnt fixed_bottom
    node.offset.index = i
    node.offset.top_from_bottom = fixed_bottom
    node.offset.top_from_top = node.offset.top - scroll_top
    node.offset.bottom_from_bottom = fixed_bottom - node.offset.height
    node.offset.bottom_from_top = (node.offset.height - scroll_top) + node.offset.top

    # return
    true

test_node_passing = (node) ->
  #console.log('on-content.passing', node) if node.offset.is_passing

test_node_scroll = (node) ->
  #console.log 'on-content.scroll', node

test_node_enter = (node) ->
  return if node.offset.is_passing
  return if node.offset.top_from_bottom <= 0
  return if node.offset.bottom_from_top <= 0

  node.offset.is_passing = true
  console.log 'on-content.enter', node

test_node_exit = (node) ->
  return unless node.offset.is_passing
  return unless (node.offset.top_from_bottom <= 0) or (node.offset.bottom_from_top <= 0)

  node.offset.is_passing = false
  console.log 'on-content.exit', node

test_all_offsets = (scroll_top) ->
  for node, i in stack.contentNodes
    if update_metrics(i, node, scroll_top)
      # im not sure if the order is right?
      test_node_scroll(node)
      test_node_enter(node)
      test_node_exit(node)
      test_node_passing(node)

calculate_all_offsets = ->
  update_offsets(node) for node in stack.contentNodes

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

initialize_sticky = (node) ->
  el = $(node)
  data = $.extend({}, el.data('sticky') or {})

  # used for internal stacks
  data.group or= 0

  parent = if data.parent
    el.closest(data.parent)
  else
    el.parent()

  # auto-grouping
  unless data.group
    unless parent.data('scrollKit_gid') > 0
      parent.data 'scrollKit_gid', group_id += 1

  data.group += '.' + (parent.data('scrollKit_gid') or 0)

  node.el = el
  node.data = data
  node.parent = parent
  node.offset = el.offset()
  node.position = el.position()
  node.display = el.css('display')
  node.isFloat = el.css('float') isnt 'none'
  node.isFixed = data.fixed or (el.css('position') is 'fixed')
  node.placeholder = placeholder(node) if update_sticky(node)

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

calculate_all_stickes = (scroll_top) ->
  for sticky in stack.stickyNodes
    continue if sticky.isFixed

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

  # detach destroyed stickies
  for sticky in stack.stickyNodes
    unless sticky.el
      initialize_sticky(sticky)
    else
      sticky.el.attr('style', '').removeClass 'fit stuck bottom'
      sticky.placeholder.remove()

      unless destroy
        update_sticky(sticky)
        sticky.placeholder = placeholder(sticky)

  # return
  undefined

test_for_scroll_and_offsets = ->
  test = win.scrollTop()
  calculate_all_stickes(test)
  test_all_offsets(test)
  test_on_scroll(test)
  last_scroll = test

update_everything = (destroy) ->
  # required for viewport testing
  win_height = win.height()

  refresh_all_stickies(destroy)

  calculate_all_offsets()
  test_for_scroll_and_offsets()

win.on 'touchmove scroll', ->
  if stack.stickyNodes_length isnt stack.stickyNodes.length
    stack.stickyNodes_length = stack.stickyNodes.length
    refresh_all_stickies()

  if stack.contentNodes_length isnt stack.contentNodes.length
    stack.contentNodes_length = stack.contentNodes.length
    calculate_all_offsets()

  test_for_scroll_and_offsets()

win.on 'resize', ->
  update_everything()

$.scrollKit = (params = {}) ->
  if params is 'destroy'
    update_everything(true)
  else
    unless params is 'update'
      sticky_className = params.stickyClassName or 'is-sticky'
      content_className = params.contentClassName or 'is-content'

      # we prefer to use a (native) live nodeList for avoiding re-scanning
      stack.stickyNodes = document.getElementsByClassName sticky_className
      stack.stickyNodes_length = stack.stickyNodes.length

      stack.contentNodes = document.getElementsByClassName content_className
      stack.contentNodes_length = stack.contentNodes.length

    update_everything()

  # return
  undefined
