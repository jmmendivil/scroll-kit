'use strict';

/* global $ */

$(function() {
  var visible = [];

  var output = $('#stats'),
      jump = output.find('.jump'),
      keys = output.find('.keys'),
      scroll = output.find('.scroll'),
      from_to = output.find('.from_to');

  var offset_top = $('main').offset().top;

  jump.on('change', function() {
    $.scrollKit.scrollTo(jump.val(), offset_top);
  });

  function render() {
    var indexes = visible.map(function(node) {
      return node.offset.index;
    }).sort();

    keys.text(indexes.join(', '));
    jump.val(indexes[0]);
  }

  $.scrollKit(function(e) {
    if (e.type === 'direction') {
      from_to.text(e.from + ' / ' + e.to);
    }

    if (e.type === 'tick') {
      scroll.text(e.scrollY);
    }

    if (e.type === 'update') {
      jump.empty();

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
