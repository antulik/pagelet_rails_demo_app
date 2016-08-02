document.addEventListener("turbolinks:load", function(){

  // Enable pjax regardless of it's support and disable pushstate
  // pjax is used for widget loading rather than page loading by default
  $.pjax.enable();
  $.pjax.defaults.push = false;

  $('[data-pjax]').each(function(index, elem){
    var $el = $(elem);
    var id = $el.attr('id');

    var container_selector = '#' + id;

    var options = {
      timeout: 0,
      push: false
    };

    $el.pjax('a:not([data-remote]):not([data-behavior]):not([data-skip-pjax])', container_selector, options);

    $el.on('submit', 'form:not([data-remote]):not([data-skip-pjax])', function (event) {
      $.pjax.submit(event, container_selector, options);
    });

    $el.on('pjax:error', function(xhr, textStatus, error, options){
      console.log(textStatus, error)
      $(this).text('Error occurred during loading');
      return false;
    });
  });

  $('[data-pjax-scroll]').on('pjax:start', function(options, xhr){
    var $el = $(options.target);
    var container, new_value;

    if ($('.app-header').length > 0) {
      container = $('.app-body');
      new_value = $el.offset().top - $('.waterfall').offset().top;
    } else {
      container = $('.content-app');
      new_value = $el.offset().top - $('.app-body').offset().top - 10;
    }

    if (container.scrollTop() > new_value) {
      container.animate({
        scrollTop: new_value
      }, 600);
    }
  });

  $(document).on('pjax:start', function(e){
    var html = JST['views/pagelet_loading_overlay']();
    var el = $(html);

    $(e.target).append(el);
    el.transition({opacity: 1}, 500, 'easeOutCubic');
  })

});
