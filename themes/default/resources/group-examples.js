var languages = {};

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
      languages[className] = 1;
      var $li = $("<li><a data-examples-group='" + lang + "'>" + className + "</a></li>");
      if (index==0) {
        $li.addClass('active');
      }
      $tabs.append($li);
    });
    $tabs.append("<li><a data-examples-group='@all'>Show all</a></li>");
    var $panes = $codes.wrap("<div class='tab-pane'></div>").parent().wrapAll("<div class='tab-content'></div>");
    $panes.first().addClass('active').parent().wrapAll("<div class='examples-group panel panel-default'><div class='panel-body'></div></div>").parent().prepend($tabs);
  });
}

function selectLanguage(lang) {
  if (!lang) {
    return;
  }
  localStorage.setItem('lastLang', lang);

  $('.examples-group').find('li').removeClass('active');
  $('.examples-group').find("a[data-examples-group='" + lang + "']").closest('li').addClass('active');

  if (lang==='@all') {
    var count = Object.keys(languages).length;
    $('.examples-group').find('.tab-pane').addClass('active').css({float: 'left', width: Math.floor(100/count)+'%', 'padding-left': '5px', 'padding-right': '5px'});
  } else {
    $('.examples-group').find('.tab-pane').removeClass('active').css({float: '', width: '', 'padding-left': '', 'padding-right': ''});
    $('.examples-group').find("code." + lang).closest('.tab-pane').addClass('active');
  }
}

groupExamplesPerLanguage();
selectLanguage(localStorage.getItem('lastLang'));
$('[data-examples-group]').click(function (event) {
  event.preventDefault();
  selectLanguage($(event.target).attr('data-examples-group'));
});
