//= require_tree ./views
//= require pagelet_rails/jquery.ajaxprogress

var addParamsToUrl = function( url, data ) {
  if ( ! $.isEmptyObject(data) ) {
    url += ( url.indexOf('?') >= 0 ? '&' : '?' ) + $.param(data);
  }

  return url;
};

function load_widget_urls() {
  $('[data-widget-url]').each(function(index, elem){
    var $el = $(elem);
    load_widget_url($el.attr('id'));
  });
}

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
    }).fail(function(){
      var html = JST['views/pagelet_load_failed']({
        pagelet_url: path,
        reload_function: "load_widget_url('" + elem_id + "');"
      });
      $el.html(html)
    });
  }
}

function append_script_tag(text) {
  var script = document.createElement( "script" );
  script.type = "text/javascript";
  script.text = text
  $("body").append(script);
}

function load_pagelet_batch() {
  var urls = {};

  $('[data-widget-url]').each(function(index, elem){
    var $el = $(elem);
    var elem_id = $el.attr('id');

    var path = $el.data('widget-url');
    var group = $el.data('pagelet-group');

    var url = addParamsToUrl(path, {
      target_container: elem_id,
      original_pagelet_options: $el.data('pagelet-options')
    });

    urls[group] = urls[group] || [];
    urls[group].push(url);
  });

  for (var group in urls) {
    if (urls.hasOwnProperty(group)) {
      send_to_group(group, urls[group]);
    }
  }
}

function send_to_group(group_name, urls) {
  if (urls.length == 0) { return; }

  var prev_index = 0;

  $.ajax({
    url: '/pagelet_proxy',
    data: {
      urls: urls
    },
    dataType: 'text',
    cache: false,
    headers: {
      'X-Pagelet': 'pagelet'
    },
    progress: function(_, progressEvent) {
      var text = progressEvent.target.responseText;
      var end_index = -1;

      do {
        end_index = text.indexOf("\n\n//\n\n", prev_index);

        if (end_index != -1) {
          var new_text = text.substring(prev_index, end_index);

          eval(new_text);

          prev_index = end_index + 1;
          // console.log('found');
          // console.log(new_text);
        }

      } while (end_index != -1);
    }
  })
}

function load_pagelets() {
  // load_widget_urls();
  load_pagelet_batch();
}

function pagelet_place_into_container(id, content) {
  $('#' + id).html(content);
  $(document).trigger('pagelet-loaded');
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
      id = 'pagelet_' + randomStr();
      $el.attr('id', id);
    };
  });

  load_pagelets();

  process_elements();
});
