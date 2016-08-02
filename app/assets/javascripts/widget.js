function load_widget_url(elem_id) {
  var $el = $('#' + elem_id);
  var path = $el.data('widget-url');
  if (path) {
    $.ajax({
      url: path,
      headers: {
      }
    }).done(function(data) {
      $el.html(data)
    }).fail(function(){
      var html = JST['views/pagelet_load_failed']({
        pagelet_url: path,
        reload_function: "load_widget_url('" + elem_id + "');"
      });
      $el.html(html)
    });
  }
}

document.addEventListener("turbolinks:load", function(){
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
});
