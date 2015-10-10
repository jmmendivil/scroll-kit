'use strict';

/* global $ */

$(function() {
  var stack = {},
      visible = [];

  var output = $('#stats'),
      jump = output.find('.jump'),
      keys = output.find('.keys');

  var offset_top = $('main').offset().top;

  jump.on('change', function() {
    var node = stack.contentNodes[jump.val()];

    $(window).scrollTop(node.offset.top - offset_top);
  });

  function render() {
    var indexes = visible.map(function(node) {
      return node.offset.index;
    }).sort();

    keys.text(indexes.join(', '));
    jump.val(indexes[0]);
  }

  $.scrollKit(function(e) {
    if (e.type === 'update') {
      jump.empty();

      stack = e.stack;

      var index = 0,
          length = e.stack.contentNodes.length;

      while (index < length) {
        jump.append('<option value="' + index + '">' + index + '</option>');
        index += 1;
      }
    }

    if (e.type === 'enter') {
      visible.push(e.node);
      render();
    }

    if (e.type === 'exit') {
      visible = visible.filter(function(old) {
        return old.offset.index !== e.node.offset.index;
      });
      render();
    }
  });
});
