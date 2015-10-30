/* global $ */

$(function() {
  $.scrollKit({
    debug: true,
    gap: 140,
    top: $('main').offset().top
  });

  var sticky = $.scrollKit.find('x');

  $.scrollKit.eventHandler(function(e) {
    if (e.type === 'passing' && e.node.offset.is_nearest) {
      $.scrollKit.pop(sticky, e.node.offset.index > 6);
    }
  });
});
