$(function() {
  // make result of marked for pretty print
  $('pre code[class^="lang-"]').addClass('.prettyprint');
  window.prettyPrint && prettyPrint()
});

$('body').on('click', '.showcode', function () {
  $(this).parent().find('pre.sourcecode').toggle();
  $('body').scrollspy('refresh');
});

var $options_private = $('#options-private');
function updatePrivate() {
  if ($options_private.is(':checked')) {
    $('.private').show();
  } else {
    $('.private').hide();
  }
  $('body').scrollspy('refresh');
}
$options_private.on('click', updatePrivate);
updatePrivate();
