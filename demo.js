'use strict';

/* global $ */

$(function() {
  $.scrollKit({
    debug: true,
    gap: 200,
    top: $('main').offset().top
  });
});
