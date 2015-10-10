'use strict';

/* global $ */

$(function() {
  var visible = [];

  var output = $('#stats');

  function render() {
    var indexes = visible.map(function(node) {
      return node.offset.index;
    });

    output.html([
      '<h3>Visible content</h3>',
      '<ul>',
      '<li>Indexes: ', indexes.join(', '), '</li>',
      '<li>Elements: ', indexes.length, '</li>',
      '</ul>'
    ].join(''));
  }

  $.scrollKit(function(evt, node) {
    if (evt === 'enter') {
      visible.push(node);
      render();
    }

    if (evt === 'exit') {
      visible = visible.filter(function(old) {
        return old.offset.index !== node.offset.index;
      });
      render();
    }
  });
});
