win = $(window)
doc = $(document.documentElement)

_ =
  all:
    offsets: {}
    stickies: []
  win:
    height: win.outerHeight()
  doc:
    height: doc.outerHeight()

debounce = (fn) ->
  ->
    clearTimeout fn.t
    fn.t = setTimeout fn, 300

update_stickies = ->
  _.all.stickies = []

  $('.is-sticky').each ->
    node = $(@)

    data = node.data('sticky') or {}
    data.group = data.group or '_default'

    parent = node.parent()

    node =
      el: node
      data: data
      offset: node.offset()
      width: node.outerWidth()
      height: node.outerHeight()
      isFixed: isFixed = node.hasClass('fixed')
      isInline: isInline = node.hasClass('inline')

    unless isFixed
      node.placeholder = $('<div/>')
        .insertBefore(node.el)
        .hide()
        .css
          width: node.width
          height: node.height
          float: node.el.css('float')

    # TODO: consider starting the stack from another stack if desired, otherwise use zero
    _.all.offsets[data.group] = (_.all.offsets._default or 0) unless _.all.offsets[data.group]?

    node.data.offset_top = _.all.offsets[data.group]

    _.all.offsets[data.group] += node.height

    _.all.stickies.push {
      node

      parent:
        el: parent
        offset: parent.offset()
        height: parent.outerHeight()
    }

lastScroll = -1

stuck = ->
  scrollTop = win.scrollTop()

  _.all.stickies.forEach (sticky) ->
    return if sticky.node.isFixed

    if scrollTop <= (sticky.node.offset.top - sticky.node.data.offset_top)
      if sticky.node.el.hasClass('stuck')
        sticky.node.placeholder.hide()
        sticky.node.el.removeClass('stuck').css position: 'static'
        # TODO: how to reset it dimensions?
    else
      offsetBottom = scrollTop + sticky.node.height + sticky.node.data.offset_top

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
            top: sticky.node.data.offset_top

      unless sticky.node.el.hasClass('stuck')
        sticky.node.placeholder.show()
        sticky.node.el.addClass('stuck').css
          position: 'fixed'
          width: sticky.node.width
          height: sticky.node.height
          left: sticky.node.offset.left
          top: sticky.node.data.offset_top

  update_stickies() if lastScroll is -1

  lastScroll = scrollTop

win.on 'scroll', stuck

stuck()
