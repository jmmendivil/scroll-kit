VERSION = '0.3.4'

offsets = {}
group_id = 0

last_scroll = null
last_direction = 'initial'

event_handler = null
static_interval = null

ticking = false

# :)
state =
  gap:
    offset: -1
    nearest: null

  classes: {}

  offsetTop: 0
  references: {}

  stickyNodes: []
  contentNodes: []

  visibleIndexes: []

# cached
win = $(window)
win_height = win.height()

# required for scrolling
html = $('html,body')
body = $(document.body)

# ;-)
debug =
  is_enabled: false

  element: $('''
    <div id="scroll-kit-info">
      <span class="gap"></span>
      <label>Indexes: <span class="keys"></span></label>
      <label>ScrollY: <span class="scroll"></span></label>
      <label>ScrollTo: <select class="jump"></select></label>
      <label>Direction: <span class="from_to"></span></label>
    </div>
  ''').hide().appendTo body

  cached: {}

  style: '''
    #scroll-kit-info {
      border-radius: 0 0 5px 0;
      background: rgba(0, 0, 0, .6);
      color: #FFFFFF;
      text-shadow: 1px 1px 1px #000000;
      position: fixed;
      padding: 10px;
      left: 0;
      top: 0;
      z-index: 2147483647;
      font-size: 13px;
    }

    #scroll-kit-info .gap {
      top: -1;
      left: 0;
      width: 100%;
      position: fixed;
      z-index: 2147483647;
    }

    #scroll-kit-info .gap:before {
      border-bottom: 1px dotted red;
      position: absolute;
      content: ' ';
      width: 100%;
      top: -1px;
    }

    #scroll-kit-info label {
      line-height: 20px;
      display: block;
    }
  '''

  info: (key) ->
    debug.cached[key] or (debug.cached[key] = debug.element.find(".#{key}"))

style = document.createElement 'style'
style.appendChild(document.createTextNode(debug.style))

document.head.appendChild style

debug.info('jump').on 'change', (e) ->
  return unless debug.is_enabled
  $.scrollKit.scrollTo(e.target.selectedIndex)

prevent_scroll = (e) ->
  delta = if (e.type is 'mousewheel') then e.originalEvent.wheelDelta else (e.originalEvent.detail * -40)
  if (delta < 0 and (@scrollHeight - @offsetHeight - @scrollTop) <= 0)
    @scrollTop = @scrollHeight
    e.preventDefault()
  else if (delta > 0 and delta > @scrollTop)
    @scrollTop = 0
    e.preventDefault()

trigger = (type, params) ->
  return unless event_handler

  # common values
  params ?= {}
  params.type = type
  params.from = last_direction
  params.scrollY = last_scroll

  event_handler(params)

set_classes = (name) ->
  unless body.hasClass(name)
    body.removeClass('backward forward static').addClass(name)

    if debug.is_enabled
      debug.info('from_to').text(last_direction + ' / ' + name)

    trigger 'direction', { to: name }
    last_direction = name
  return

test_on_scroll = ->
  scroll_top = win.scrollTop()

  return if last_scroll is scroll_top
  return if scroll_top < 0

  unless scroll_top
    body.removeClass('has-scroll') if body.hasClass('has-scroll')
  else
    body.addClass('has-scroll') unless body.hasClass('has-scroll')

  set_classes if scroll_top < last_scroll
    'backward'
  else if scroll_top > last_scroll
    'forward'
  else
    'static'

  clearTimeout static_interval
  static_interval = setTimeout ->
    set_classes('static')
  , 360

  if debug.is_enabled
    debug.info('scroll').text(scroll_top)

  last_scroll = scroll_top
  trigger 'tick'
  true

update_margins = (node) ->
  node.margin =
    top: parseInt(node.el.css('margin-top'), 10)
  return

update_offsets = (node) ->
  # store a jQuery reference due its usefulness D:
  node.el = $(node) unless node.el

  # liveNodes are also providing live storage for free!
  node.offset =
    top: node.el.offset().top
    height: node.el.outerHeight()
    is_passing: node.offset and node.offset.is_passing

  # used for additional calculations
  update_margins(node)
  return

update_metrics = (i, node) ->
  update_offsets(node) unless node.el

  fixed_bottom = (win_height - node.offset.top) + last_scroll
  should_update = node.offset.top_from_bottom isnt fixed_bottom or node.offset.index isnt i

  if should_update
    node.offset.index = i

    node.offset.top_from_bottom = fixed_bottom
    node.offset.top_from_top = node.offset.top - last_scroll

    node.offset.bottom_from_bottom = fixed_bottom - node.offset.height
    node.offset.bottom_from_top = (node.offset.height - last_scroll) + node.offset.top

    node.offset.top_from_gap = state.gap.offset - node.offset.top_from_top
    node.offset.bottom_from_gap = node.offset.top_from_top - state.gap.offset + node.offset.height

    test_bottom = node.offset.bottom_from_top >= state.gap.offset
    test_top = node.offset.top_from_top <= state.gap.offset

    node.offset.is_nearest = test_top and test_bottom
    true

test_node_passing = (node) ->
  return unless node.offset.is_passing

  if node.offset.is_nearest and (state.gap.nearest isnt node.offset.index)
    state.gap.nearest = node.offset.index

    if debug.is_enabled
      debug.info('jump').val(node.offset.index)

  trigger 'passing', { node }

test_node_scroll = (node) ->
  trigger 'scroll', { node }

test_node_enter = (node) ->
  return if node.offset.is_passing
  return if node.offset.top_from_bottom <= 0
  return if node.offset.bottom_from_top <= node.margin.top

  node.offset.is_passing = true

  if state.visibleIndexes.indexOf(node.offset.index) is -1
    state.visibleIndexes.push node.offset.index
    state.visibleIndexes.sort()

  if debug.is_enabled
    debug.info('keys').text(state.visibleIndexes.join(', '))

  trigger 'enter', { node }

test_node_exit = (node) ->
  return unless node.offset.is_passing
  return unless (node.offset.top_from_bottom <= 0) or (node.offset.bottom_from_top <= node.margin.top)

  node.offset.is_passing = false

  state.visibleIndexes = state.visibleIndexes
    .filter((old) -> old isnt node.offset.index)
    .sort()

  if debug.is_enabled
    debug.info('keys').text(state.visibleIndexes.join(', '))

  trigger 'exit', { node }

test_all_offsets = (scroll) ->
  for node, i in state.contentNodes
    if update_metrics(i, node)
      # im not sure if the order is right?
      test_node_scroll(node)
      test_node_enter(node)
      test_node_exit(node)
      test_node_passing(node)
  return

calculate_all_offsets = ->
  update_offsets(node) for node in state.contentNodes
  return

placeholder = (node) ->
  fixed =
    width: node.width
    height: node.orig_height
    float: node.el.css('float')
    position: node.el.css('position')
    verticalAlign: node.el.css('vertical-align')

  $('<div/>').css(fixed).css('display', 'none').insertBefore(node.el)

update_sticky = (node) ->
  unless offsets[node.data.group]
    offsets[node.data.group] = node.data.offset or 0

  node.offset_top = offsets[node.data.group]

  # original value
  node.orig_height = node.data.fixed_height || node.el.outerHeight()

  # increment the node offset_top based on current group/stack
  offsets[node.data.group] += node.orig_height if (!node.isFloat && node.isFixed)

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

  if data.fit
    el.on 'DOMMouseScroll mousewheel', prevent_scroll

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

  # persists id-reference
  state.references[data.id] = node if data.id?

  return

destroy_sticky = (node) ->
  node.el.attr('style', '').removeClass 'fit stuck bottom'
  node.placeholder.remove()
  return

init_sticky = (node) ->
  update_sticky(node)
  node.placeholder = placeholder(node)
  return

check_if_fit = (sticky) ->
  fitted_top = win_height + last_scroll - sticky.offset_top

  if fitted_top >= sticky.passing_top
    sticky.el.addClass('fit') unless sticky.el.hasClass('fit')
    sticky.el.css 'height', Math.min(fitted_top - sticky.passing_top, sticky.height)
  else
    sticky.el.removeClass('fit') if sticky.el.hasClass('fit')

check_if_carry = (sticky) ->

  ## Forward - Sit
  if body.hasClass('forward')

    ## Normal Sticky - float
    if sticky.el.hasClass('stuck')
      sticky.el.removeClass('stuck')
        .addClass('sit') ## pretend was Sit
      check_if_can_float sticky

    _offset = sticky.el.offset()
    passing_bottom = (sticky.height - win_height + _offset.top)

    if last_scroll >= passing_bottom
      return if sticky.el.hasClass 'bottom'
      check_if_can_sit sticky

    ## Hold on, boy!
    if (last_scroll + win_height) >= sticky.passing_bottom
      check_if_can_bottom sticky

  ## Backward - Sticky top
  else if body.hasClass('backward')
    check_if_can_float sticky

    ## Sticky start - reset pos
    if sticky.el.hasClass('bottom')
      sticky.el.removeClass('bottom')
      update_sticky sticky

    ## Sticky
    if last_scroll <= sticky.passing_top
      check_if_can_stick sticky
      if last_scroll <= sticky.parent.offset().top
        check_if_can_unstick sticky
        update_sticky sticky

check_if_can_sit = (sticky) ->
  unless sticky.el.hasClass('sit')
    sticky.el.addClass('sit')
      .attr('style', '').css
        position: 'fixed'
        width: sticky.width
        height: sticky.height
        left: sticky.offset.left
        bottom: 0

check_if_can_float = (sticky) ->
  if sticky.el.hasClass('sit')
    _offset = sticky.el.offset()
    sticky.el.removeClass('sit')
      .attr('style', '').css
        position: 'absolute'
        width: sticky.width
        top: _offset.top - sticky.parent.offset().top
        left: sticky.position.left
    update_sticky sticky

check_if_can_stick = (sticky) ->
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

check_if_can_unstick = (sticky) ->
  if sticky.el.hasClass('stuck')
    if sticky.placeholder
      sticky.placeholder.css('display', 'none')

    sticky.el.removeClass('fit stuck bottom sit').attr 'style', ''

check_if_can_bottom = (sticky) ->
  unless sticky.el.hasClass('bottom')
    sticky.el.removeClass('sit').addClass('bottom').css
      position: 'absolute'
      left: sticky.position.left
      bottom: sticky.fixed_bottom or 0
      top: 'auto'
      width: sticky.width
      height: sticky.height if sticky.data.fit

check_if_can_unbottom = (sticky) ->
  if sticky.el.hasClass('bottom')
    sticky.el.removeClass('bottom').css
      position: 'fixed'
      left: sticky.offset.left
      top: sticky.offset_top

calculate_all_stickes = ->
  for sticky in state.stickyNodes
    continue if sticky.isFixed or sticky.data.disabled

    if sticky.data.carry or sticky.el.hasClass('is-sticky--carry')
      check_if_carry sticky
    else if last_scroll <= sticky.passing_top
      check_if_can_unstick sticky
    else
      check_if_can_stick sticky

      if sticky.data.bottoming isnt false
        if (last_scroll + sticky.passing_height) >= sticky.passing_bottom
          check_if_can_bottom(sticky)
        else
          check_if_can_unbottom(sticky)

    check_if_fit(sticky) if sticky.data.fit
  return

refresh_all_stickies = (destroy) ->
  # reindex
  offsets = {}

  # detach destroyed stickies
  for sticky in state.stickyNodes
    continue if sticky.data and sticky.data.disabled

    unless sticky.el
      initialize_sticky(sticky)
    else
      destroy_sticky(sticky)
      init_sticky(sticky) unless destroy
  return

test_for_scroll_and_offsets = ->
  if test_on_scroll()
    test_all_offsets()
    calculate_all_stickes()
    return

update_everything = (destroy) ->
  # force update
  last_scroll = null

  # required for viewport testing
  win_height = win.height()

  refresh_all_stickies(destroy)

  calculate_all_offsets()
  test_for_scroll_and_offsets()

  if debug.is_enabled
    debug.info('jump')
      .html(("<option>#{i - 1}</option>" for i in [1..state.contentNodes.length]))
      .val state.gap.nearest
  return

## not sure about this...
## also, will not work for new img/iframe created elems
$('img, iframe').on 'load error', ->
  update_everything()

win.on 'touchmove scroll', ->
  unless ticking
    requestAnimationFrame ->
      test_for_scroll_and_offsets()
      ticking = false
  ticking = true

win.on 'resize', ->
  clearTimeout static_interval
  static_interval = setTimeout ->
    update_everything()
  , 260

$.scrollKit = (params) ->
  if typeof params is 'function'
    event_handler = params
    params = {}

  if params.debug
    $.scrollKit.debug(params.debug)

  state.offsetTop = if params.top then parseInt(params.top, 10) else 0
  state.gap.offset = if params.gap then parseInt(params.gap, 10) else 0

  if debug.is_enabled
    debug.info('gap').css 'top', state.gap.offset

  sticky_className = state.classes.stickyClassName = params.stickyClassName or 'is-sticky'
  content_className = state.classes.contentClassName = params.contentClassName or 'is-content'

  # we prefer to use a (native) live nodeList for avoiding re-scanning
  state.stickyNodes = document.getElementsByClassName sticky_className
  state.contentNodes = document.getElementsByClassName content_className

  update_everything()

$.scrollKit.version = VERSION

$.scrollKit.on = (node) ->
  if node.data.disabled
    init_sticky(node)
    node.data.disabled = false
    refresh_all_stickies()
    calculate_all_stickes()
  return

$.scrollKit.off = (node) ->
  unless node.data.disabled
    destroy_sticky(node)
    node.data.disabled = true
  return

$.scrollKit.add = (node, options) ->
  unless node.hasClass(state.classes.stickyClassName)
    node.data(sticky: options).addClass(state.classes.stickyClassName)
  node[0]

$.scrollKit.pop = (node, stuck) ->
  return if node.data.disabled

  if stuck isnt false
    unless node.data.bottoming
      check_if_can_bottom(node)
      node.data.bottoming = true
  else if node.data.bottoming isnt false
    check_if_can_unbottom(node)
    node.data.bottoming = false
  return

$.scrollKit.find = (id) ->
  if typeof id isnt 'function'
    state.references[id]
  else
    # TODO: unify sticky/content nodes
    Array::filter.call(state.contentNodes, id)

$.scrollKit.debug = (enabled = true) ->
  debug.is_enabled = !!enabled
  debug.element[if enabled then 'show' else 'hide']()

  if debug.is_enabled
    update_everything()
    debug.info('gap').css('top', state.gap.offset)
  return

$.scrollKit.recalc = ->
  update_everything()

$.scrollKit.destroy = (node) ->
  return update_everything(true) unless node
  node.el.remove()
  update_everything()
  # TODO: detach all content-nodes

$.scrollKit.scrollTo = (index, callback) ->
  contentNode  = state.contentNodes[index]
  _offset = $(contentNode).offset()
  html.animate
    scrollTop: _offset.top - state.offsetTop
  , 260, 'swing', callback
  return

# convenience method
$.scrollKit.eventHandler = (callback) ->
  old_handler = event_handler
  event_handler = callback if typeof callback is 'function'
  old_handler

$.scrollKit.updateOffsets = (params) ->
  state.offsetTop = +params.top if params.top?
  state.gap.offset = +params.gap if params.gap?
  update_everything()
