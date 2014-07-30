function groupExamplesPerLanguage() {
  $('pre:has(code)').filter(function () {
    return $(this).next('pre:has(code)').length > 0;
  }).each(function () {
    var $codes = $(this).nextUntil(':not(pre:has(code))').addBack();
    var $tabs = $("<ul class='nav nav-tabs'></ul>");
    $codes.each(function (index) {
      var lang = $(this).find('code').attr('class')
      var className = lang.replace('lang-', '');
      if (className==='javascript') {
        className = 'JavaScript';
      } else if (className==='coffeescript') {
        className = 'CoffeeScript';
      }
      var $li = $("<li><a data-examples-group='" + lang + "'>" + className + "</a></li>");
      if (index==0) {
        $li.addClass('active');
      }
      $tabs.append($li);
    });
    var $panes = $codes.wrap("<div class='tab-pane'></div>").parent().wrapAll("<div class='tab-content'></div>");
    $panes.first().addClass('active').parent().wrapAll("<div class='examples-group'></div>").parent().prepend($tabs);
  });
}

function selectLanguage(lang) {
  if (!lang) {
    return;
  }
  localStorage.setItem('lastLang', lang);
  $('.examples-group').find('li,.tab-pane').removeClass('active');
  $('.examples-group').find("a[data-examples-group='" + lang + "']").closest('li').addClass('active');
  $('.examples-group').find("code." + lang).closest('.tab-pane').addClass('active');
}

groupExamplesPerLanguage();
selectLanguage(localStorage.getItem('lastLang'));
$('[data-examples-group]').click(function (event) {
  event.preventDefault();
  selectLanguage($(event.target).attr('data-examples-group'));
});
