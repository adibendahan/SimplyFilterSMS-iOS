(function () {
  var RTL = ['ar', 'he'];
  var STORAGE_KEY = window.I18N_BOOT.storageKey;
  var strings = window.STRINGS;
  var lang = strings[window.I18N_BOOT.lang] ? window.I18N_BOOT.lang : 'en';

  function lookup(key) {
    var table = strings[lang] || {};
    var fallback = strings.en || {};
    return table[key] != null ? table[key] : (fallback[key] != null ? fallback[key] : key);
  }

  function menuPath(parts) {
    return '<span class="menu-path">' + parts.join('<span class="sep" aria-hidden="true"></span>') + '</span>';
  }

  var terms = null;
  function namedTerm(name) {
    if (!terms) {
      terms = {
        blockedTexts: lookup('app.blockedTexts'),
        allowedTexts: lookup('app.allowedTexts'),
        export: lookup('app.export'),
        sender: lookup('app.sender'),
        body: lookup('app.body'),
        exportPath: menuPath(['•••', lookup('app.filterTools'), lookup('app.exportFilters')]),
        subscribePath: menuPath([lookup('app.communityLists'), lookup('app.subscribeFromURL')])
      };
    }
    return terms[name];
  }

  function t(key, args) {
    return lookup(key).replace(/\{(\w+)\}/g, function (whole, name) {
      if (args && args[name] != null) return String(args[name]);
      var term = namedTerm(name);
      return term != null ? term : whole;
    });
  }

  function plural(key, count, args) {
    var category = new Intl.PluralRules(lang).select(count);
    var specific = key + '.' + category;
    var table = strings[lang] || {};
    var chosen = table[specific] != null ? specific : key + '.other';
    return t(chosen, args);
  }

  function list(keys) {
    var values = keys.map(function (key) { return lookup(key); });
    return new Intl.ListFormat(lang, { type: 'disjunction' }).format(values);
  }

  function languageName(code) {
    var name = new Intl.DisplayNames([lang], { type: 'language' }).of(code) || code;
    return name.charAt(0).toLocaleUpperCase(lang) + name.slice(1);
  }

  function apply() {
    document.querySelectorAll('[data-i18n]').forEach(function (node) {
      node.innerHTML = t(node.getAttribute('data-i18n'));
    });
    document.querySelectorAll('[data-i18n-attr]').forEach(function (node) {
      node.getAttribute('data-i18n-attr').split('|').forEach(function (pair) {
        var parts = pair.split(':');
        node.setAttribute(parts[0], t(parts[1]));
      });
    });
    document.querySelectorAll('[data-step]').forEach(function (node) {
      node.textContent = t('step', [node.getAttribute('data-step')]);
    });
    document.querySelectorAll('[data-author]').forEach(function (node) {
      node.textContent = t('app.byAuthor', [node.getAttribute('data-author')]);
    });
    document.querySelectorAll('[data-example-language]').forEach(function (node) {
      var parts = t('example.locale').split('-');
      var flag = String.fromCodePoint.apply(null, parts[1].split('').map(function (c) { return 0x1F1A5 + c.charCodeAt(0); }));
      node.textContent = flag + ' ' + languageName(parts[0]);
    });
    document.querySelectorAll('[data-language]').forEach(function (node) {
      node.textContent = node.getAttribute('data-flag') + ' ' + languageName(node.getAttribute('data-language'));
    });
    document.querySelectorAll('[data-list]').forEach(function (node) {
      node.textContent = list(node.getAttribute('data-list').split(','));
    });
    document.querySelectorAll('[data-updated]').forEach(function (node) {
      var date = new Date(2026, 10, 13, 9, 41);
      var formatted = new Intl.DateTimeFormat(lang, { dateStyle: 'short', timeStyle: 'short' }).format(date);
      node.textContent = t('app.lastUpdated', [formatted]) + '. ' + t('app.footer') + ' ';
    });
    document.querySelectorAll('[data-copyright]').forEach(function (node) {
      node.textContent = t('app.copyright', [new Date().getFullYear()]);
    });
    var picker = document.getElementById('language-select');
    if (picker) {
      picker.value = lang;
      picker.addEventListener('change', function () {
        try { localStorage.setItem(STORAGE_KEY, picker.value); } catch (e) {}
        var url = new URL(location.href);
        if (url.searchParams.has('lang')) {
          url.searchParams.set('lang', picker.value);
          location.href = url.toString();
        } else {
          location.reload();
        }
      });
    }
    document.documentElement.classList.remove('i18n-pending');
  }

  document.documentElement.lang = lang;
  document.documentElement.dir = RTL.indexOf(lang) >= 0 ? 'rtl' : 'ltr';
  document.documentElement.classList.add('i18n-pending');
  window.I18N = { lang: lang, t: t, plural: plural, list: list, languageName: languageName, apply: apply };
})();
