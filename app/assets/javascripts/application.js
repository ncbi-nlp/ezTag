// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require handlebars/handlebars
//= require moment/moment
//= require lightbox
//= require_tree .
//= require semantic-ui

function updateCollectionStatus() {
  var $e = $(".collection-status");
  if ($e.length <= 0) {
    return;
  }
  var id = $e.data("id");
  $.getJSON("/collections/" + id + ".json", function(data) {
    $e.html(data.status_with_icon);
    $(".task-buttons-annotate").toggleClass("disabled", !data.task_available);
    $(".task-buttons-train").toggleClass("disabled", !data.task_available || !data.has_annotations);
  });
}
$(function() {
  $('.done-checker .checkbox').checkbox().checkbox({
    onChange: function() {
      var $e = $(this);
      var id = $e.data('id');
      var checked = $e.prop('checked');
      var $loader = $e.siblings('.loader');
      console.log(id, checked, $loader);
      $loader.addClass('active');
      $e.addClass
      $.ajax({
        url: '/documents/' + id + '/done',
        method: "POST",
        data: {value: checked}, 
        beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
        success: function(data) {
          location.reload();
          console.log(data);
        }, 
        error: function(err) {
          console.error(err);
        },
        complete: function() {
          $loader.removeClass('active');
        }
      });
    },
  });
});
