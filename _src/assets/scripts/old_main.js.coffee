# $('.is-sticky:not(.fixed)').each (i, el) ->
#   console.log $(this).offset()

# allStickies = []

# updateStickies = ->
#   added = 0

#   for node in document.getElementsByClassName('is-sticky')
#     unless node.classList.contains('section')
#       node.classList.add 'section'
#       allStickies.push node
#       added += 1

#   viewport.reset() if added

# updateStickies()

# window.addEventListener 'scroll', ->
#   console.log 'ALL', allStickies
# , false


# initStickies = (cherry) ->
#   body = $(document.body)

#   fixed = false
#   offsets = {}
#   stickies = []

#   $('.is-sticky').each (i, el) ->
#     $el = $(el)

#     params = $el.data('sticky') or {}
#     params.sticky_class = 'stuck'

#     offsets[params.group] = 0 unless offsets[params.group]?

#     params.offset_top = offsets[params.group]

#     offsets[params.group] += $el.outerHeight()

#     isFixed = params.fixed is true

#     delete params.fixed
#     delete params.group

#     stickies.push
#       node: $el
#       params: params
#       responsive: isFixed

#     if isFixed
#       # TODO: must be aware on resize?
#       nodeTop = $el.offset().top
#       $el.css 'height', window.innerHeight - nodeTop

#     $el.stick_in_parent params

#   debounce = (fn) ->
#     ->
#       clearTimeout fn.t
#       fn.t = setTimeout fn, 200

#   detachStickies = ->
#     for sticky in stickies
#       if sticky.responsive
#         sticky.detached = true
#         console.log 'DETACH?'
#         sticky.node.trigger('sticky_kit:detach')

#   attachStickies = ->
#     for sticky in stickies
#       if sticky.detached
#         delete sticky.detached
#         sticky.node.stick_in_parent sticky.params

#   recalcStickies = ->
#     console.log 'RECALC IF?', fixed is on
#     body.trigger('sticky_kit:recalc') if fixed

#   checkViewportWidth = ->
#     # TODO: make this configurable via data-* attrs?
#     if not fixed and window.innerWidth > 768
#       cherry.events.publish 'on-attach'
#       attachStickies()
#       fixed = true

#     if fixed and window.innerWidth < 768
#       cherry.events.publish 'on-detach'
#       detachStickies()
#       fixed = false

#   $('iframe, img').on 'load', debounce(recalcStickies)

#   $(window)
#     .on('resize', checkViewportWidth)

#   checkViewportWidth()

# oh.require ['jquery', 'sticky-kit/jquery.sticky-kit', 'cherry'], initStickies
