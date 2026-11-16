(function () {
  var SUPPORTED = ['en', 'ar', 'de', 'es', 'fr', 'he', 'it', 'ja', 'ko', 'pt-BR', 'zh-Hans'];
  var STORAGE_KEY = 'community-lists-language';

  function supportedLanguage(tag) {
    var lower = String(tag || '').toLowerCase();
    var language = lower.split('-')[0];
    var match = null;
    if (language === 'zh') {
      match = /hant|-tw|-hk|-mo/.test(lower) ? null : 'zh-Hans';
    } else if (language === 'pt') {
      match = 'pt-BR';
    } else if (language === 'iw') {
      match = 'he';
    } else if (SUPPORTED.indexOf(language) >= 0) {
      match = language;
    }
    return match;
  }

  var lang = supportedLanguage(new URLSearchParams(location.search).get('lang'));
  if (!lang) {
    try { lang = supportedLanguage(localStorage.getItem(STORAGE_KEY)); } catch (e) {}
  }
  var preferred = navigator.languages && navigator.languages.length ? navigator.languages : [navigator.language];
  for (var i = 0; !lang && i < preferred.length; i++) {
    lang = supportedLanguage(preferred[i]);
  }
  lang = lang || 'en';

  var base = document.currentScript.src.replace(/assets\/i18n-boot\.js(\?.*)?$/, '');
  window.I18N_BOOT = { lang: lang, storageKey: STORAGE_KEY };
  window.STRINGS = {};
  document.write('<script src="' + base + 'strings/en.js"><\/script>');
  if (lang !== 'en') {
    document.write('<script src="' + base + 'strings/' + lang + '.js"><\/script>');
  }
  document.write('<script src="' + base + 'assets/i18n.js"><\/script>');
})();
