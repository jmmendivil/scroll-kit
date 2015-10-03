group_id = 0

# :)
stack = {}

# cached
win = $(window)

listen_to = (root) ->
  # support for isolated viewports/elements
  unless stack[root]
    is_win = root is 'window'
    element = unless is_win then $(root) else win

    stack[root] =
      el: element
      is_win: is_win

      # cache
      nodes: []
      offsets: {}

    on_refresh = ->
      stack[root].cached_top = unless is_win then element.offset().top else 0
      stack[root].cached_height = element.height()

    on_scroll = ->
      calculate_all_stickes(stack[root])

    on_refresh()

    # keep the reference for GC
    stack[root].update = on_refresh
    stack[root].callback = on_scroll

    element.on 'touchmove scroll', on_scroll

  stack[root]

placeholder = (node) ->
  fixed =
    width: node.width
    height: node.orig_height
    float: node.el.css('float')
    position: node.el.css('position')
    verticalAlign: node.el.css('vertical-align')

  $('<div/>').css(fixed).css('display', 'none').insertBefore(node.el)

update_sticky = (root, node) ->
  unless root.offsets[node.data.group]
    root.offsets[node.data.group] = root.cached_top

  node.offset_top = root.offsets[node.data.group]

  # original value
  node.orig_height = node.el.outerHeight(true)

  # avoid overflow on fixed-elements!
  unless (node.data.fit or root.is_win)
    node.orig_height = Math.min(root.cached_height, node.orig_height)

  # increment the node offset_top based on current group/stack
  root.offsets[node.data.group] += node.orig_height unless node.isFloat

  return if node.isFixed

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
    fixed_bottom = node.offset.top + node.orig_height
    node.fixed_bottom = node.passing_bottom - fixed_bottom
    node.passing_bottom = fixed_bottom

    if node.height >= root.cached_height
      node.passing_height = root.cached_height
      node.height = root.cached_height - node.offset_top

  true

initialize_sticky = (node, params = {}) ->
  data = $.extend({}, params, node.data('sticky') or {})

  # used for isolated scroll events
  root = listen_to(data.root or 'window')

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

  if update_sticky(root, node)
    node.placeholder = placeholder(node)
    root.nodes.push(node)

check_if_fit = (root, sticky, scroll_top) ->
  if sticky.data.fit
    fitted_top = root.cached_height + scroll_top - sticky.offset_top

    if fitted_top >= sticky.passing_top
      sticky.el.addClass('fit') unless sticky.el.hasClass('fit')
      sticky.el.css 'height', Math.min(fitted_top - sticky.passing_top, sticky.height)
    else
      sticky.el.removeClass('fit') if sticky.el.hasClass('fit')

check_if_can_stick = (root, sticky, scroll_top) ->
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

check_if_can_unstick = (root, sticky, scroll_top) ->
  if sticky.el.hasClass('stuck')
    if sticky.placeholder
      sticky.placeholder.css('display', 'none')

    sticky.el.removeClass('fit stuck bottom').attr 'style', ''

check_if_can_bottom = (root, sticky) ->
  unless sticky.el.hasClass('bottom')
    sticky.el.addClass('bottom').css
      position: 'absolute'
      left: sticky.position.left
      bottom: sticky.fixed_bottom or 0
      top: 'auto'
      height: sticky.height if sticky.data.fit

check_if_can_unbottom = (root, sticky) ->
  if sticky.el.hasClass('bottom')
    sticky.el.removeClass('bottom').css
      position: 'fixed'
      left: sticky.offset.left
      top: sticky.offset_top

calculate_all_stickes = (root) ->
  scroll_top = root.el.scrollTop()

  root.nodes.forEach (sticky) ->
    if scroll_top <= sticky.passing_top
      check_if_can_unstick(root, sticky, scroll_top)
    else
      check_if_can_stick(root, sticky, scroll_top)

      if (scroll_top + sticky.passing_height) >= sticky.passing_bottom
        check_if_can_bottom(root, sticky)
      else
        check_if_can_unbottom(root, sticky)

    check_if_fit(root, sticky, scroll_top)

refresh_all_stickies = (root, destroy) ->
  # reindex
  root.offsets = {}

  # forced update always!
  root.update()

  # filter out removed elements?
  root.nodes = root.nodes.filter (sticky) ->
    sticky.el.attr('style', '').removeClass 'fit stuck bottom'
    sticky.placeholder.remove()

    unless destroy
      update_sticky(root, sticky)
      sticky.placeholder = placeholder(sticky)
      return true

    false

update_everything = (destroy) ->
  for id, root of stack
    refresh_all_stickies(root, destroy)
    calculate_all_stickes(root)

win.on 'resize', ->
  update_everything()
  # TODO: root-elements are not being updated correctly unless its scrollTop() is 0
  undefined

$.velcro = (selector, params = {}) ->
  if selector is 'destroy'
    update_everything(true)
  else
    unless selector is 'update'
      $(selector).each ->
        initialize_sticky $(this), params

    update_everything()

  # return
  undefined
