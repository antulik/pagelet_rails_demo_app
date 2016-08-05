function load_widget_url(elem_id) {
  var $el = $('#' + elem_id);
  var path = $el.data('widget-url');
  if (path) {
    $.ajax({
      url: path,
      data: {
        target_container: elem_id,
        original_pagelet_options: $el.data('pagelet-options')
      },
      dataType: 'script',
      headers: {
        'X-Pagelet': 'pagelet'
      }
    }).done(function(data) {
      // $el.html(data);
      $(document).trigger('pagelet-loaded');
    }).fail(function(){
      var html = JST['views/pagelet_load_failed']({
        pagelet_url: path,
        reload_function: "load_widget_url('" + elem_id + "');"
      });
      $el.html(html)
    });
  }
}

function process_elements() {

  $('form[data-remote]').each(function(index, elem){
    var $el = $(elem);
    var container = $el.closest('[data-pagelet-container]');

    if (!container) {
      return;
    }

    var hidden_field = $el.find('input[name=target_container]')[0];
    if (!hidden_field) {
      $("<input/>", {
        name: "target_container",
        type: "hidden",
        value: container.attr('id')
      }).appendTo($el);
    }

    hidden_field = $el.find('input[name=original_pagelet_options]')[0];
    if (!hidden_field) {
      $("<input/>", {
        name: "original_pagelet_options",
        type: "hidden",
        value: container.data('pagelet-options')
      }).appendTo($el);
    }
  });

  $('a[data-remote]').each(function(index, elem){
    var $el = $(elem);
    var container = $el.closest('[data-pagelet-container]');

    if (!container) {
      return;
    }

    var params = $el.data('params');
    if (!params) {
      var value = $.param({
        target_container: container.attr('id'),
        original_pagelet_options: container.data('pagelet-options')
      });
      $el.data('params', value);
    }
  });
}

$(document).on('pagelet-loaded', function() {
  process_elements();
});

document.addEventListener("turbolinks:load", function(){
  console.log('turbolinks:load');
  function randomStr() {
    return Math.random().toString(36).slice(2);
  }

  $('[data-widget-url],[data-pjax]').each(function(index, elem){
    var $el = $(elem);
    var id = $el.attr('id');
    if (id == undefined) {
      id = 'pjax_widget_' + randomStr();
      $el.attr('id', id);
    };
  });

  $('[data-widget-url]').each(function(index, elem){
    var $el = $(elem);
    load_widget_url($el.attr('id'));
  });


  process_elements();
});

