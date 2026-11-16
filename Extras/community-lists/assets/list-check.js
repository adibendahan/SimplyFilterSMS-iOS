/* Mirrors the app's checks: FilterExportPayload(data:), FilterListManager.missingField(in:), FilterTransferCandidate(record:). Change them together. */
(function () {
  var FORMAT = 'simply-filter-sms-filters';
  var CURRENT_VERSION = 2;
  var TYPES = ['deny', 'allow'];
  var FOLDERS = ['junk', 'transaction', 'promotion'];
  var TARGETS = ['all', 'sender', 'body'];
  var MATCHINGS = ['contains', 'exact', 'regex'];
  var CASES = ['insensitive', 'sensitive'];
  var RECORD_KEYS = ['text', 'type', 'folder', 'target', 'matching', 'case'];
  var t = window.I18N.t;
  var plural = window.I18N.plural;
  var languageNames = new Intl.DisplayNames(['en'], { type: 'language', fallback: 'none' });
  var regionNames = new Intl.DisplayNames(['en'], { type: 'region', fallback: 'none' });

  function el(tag, className, text) {
    var node = document.createElement(tag);
    if (className) node.className = className;
    if (text != null) node.textContent = text;
    return node;
  }

  function withAutoDirection(node) {
    node.dir = 'auto';
    return node;
  }

  function isBlank(value) {
    return typeof value !== 'string' || value.trim() === '';
  }

  function isOptionalString(value) {
    return value == null || typeof value === 'string';
  }

  function listLocale(identifier) {
    if (typeof identifier !== 'string') return null;
    var parts = identifier.trim().split(/[-_]/);
    var language = parts[0].toLowerCase();
    if (!/^[a-z]{2,3}$/.test(language)) return null;
    var languageName = languageNames.of(language);
    if (!languageName) return null;
    var region = parts.slice(1).find(function (part) { return /^([a-zA-Z]{2}|\d{3})$/.test(part); });
    var flag = '';
    if (region) {
      if (!regionNames.of(region.toUpperCase())) return null;
      if (/^[a-zA-Z]{2}$/.test(region)) {
        flag = String.fromCodePoint.apply(null, region.toUpperCase().split('').map(function (c) { return 0x1F1A5 + c.charCodeAt(0); }));
      }
    }
    return { label: (flag ? flag + ' ' : '') + window.I18N.languageName(language) };
  }

  function homepageURL(value) {
    if (typeof value !== 'string' || /\s/.test(value)) return null;
    var url;
    try { url = new URL(value); } catch (e) { return null; }
    if (url.protocol !== 'https:' || !url.hostname) return null;
    return url;
  }

  function decodeProblem(payload) {
    if (payload === null || typeof payload !== 'object' || Array.isArray(payload)) return t('check.notObject');
    if (typeof payload.format !== 'string') return t('check.formatMissing');
    if (typeof payload.version !== 'number' || !Number.isInteger(payload.version)) return t('check.versionMissing');
    if (typeof payload.exportedAt !== 'string' || !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(Z|[+-]\d{2}:?\d{2})$/.test(payload.exportedAt)) return t('check.exportedAtInvalid');
    if (typeof payload.appVersion !== 'string') return t('check.appVersionMissing');
    var textFields = ['name', 'description', 'author', 'homepage', 'locale'];
    for (var i = 0; i < textFields.length; i++) {
      if (!isOptionalString(payload[textFields[i]])) return t('check.fieldNotText', [textFields[i]]);
    }
    if (!Array.isArray(payload.filters)) return t('check.filtersMissing');
    for (var r = 0; r < payload.filters.length; r++) {
      var record = payload.filters[r];
      if (record === null || typeof record !== 'object' || Array.isArray(record)) return t('check.filterNotObject', [r + 1]);
      for (var k = 0; k < RECORD_KEYS.length; k++) {
        if (!isOptionalString(record[RECORD_KEYS[k]])) return t('check.filterFieldNotText', [r + 1, RECORD_KEYS[k]]);
      }
    }
    var clear = payload.forceClearBeforeImport;
    if (clear != null && (!Array.isArray(clear) || clear.some(function (item) { return typeof item !== 'string'; }))) return t('check.forceClearInvalid');
    if (payload.format !== FORMAT || payload.version < 1) return t('check.wrongFormat', [FORMAT]);
    if (payload.version > CURRENT_VERSION) return t('check.versionTooNew', [payload.version, CURRENT_VERSION]);
    return null;
  }

  function fieldProblem(field, value) {
    return value == null ? t('record.fieldMissing', [field]) : t('record.fieldUnknown', [field, value]);
  }

  function recordProblem(record) {
    var text = typeof record.text === 'string' ? record.text.trim() : '';
    if (text.length < 1) return t('record.noText');
    if (record.type === 'denyLanguage') return t('record.denyLanguage');
    if (TYPES.indexOf(record.type) < 0) return fieldProblem('type', record.type);
    if (record.type === 'deny' && FOLDERS.indexOf(record.folder) < 0) return fieldProblem('folder', record.folder);
    if (TARGETS.indexOf(record.target) < 0) return fieldProblem('target', record.target);
    if (MATCHINGS.indexOf(record.matching) < 0) return fieldProblem('matching', record.matching);
    if (record.matching !== 'regex' && CASES.indexOf(record.case) < 0) return fieldProblem('case', record.case);
    return null;
  }

  function recordLabel(record, index) {
    var text = typeof record.text === 'string' ? record.text.trim() : '';
    return text ? t('record.label', [index + 1, text]) : t('record.labelNoText', [index + 1]);
  }

  function check(level, text, detail, items) {
    return { level: level, text: text, detail: detail, items: items };
  }

  function validate(raw) {
    var checks = [];
    var payload;
    try {
      payload = JSON.parse(raw.replace(/^﻿/, ''));
    } catch (e) {
      checks.push(check('fail', t('check.invalidJSON'), e.message));
      return { checks: checks, needsFile: false };
    }
    var problem = decodeProblem(payload);
    if (problem) {
      checks.push(check('fail', t('check.cantRead'), problem));
      return { checks: checks, needsFile: false };
    }

    var locale = listLocale(payload.locale);
    var homepage = homepageURL(payload.homepage);
    var fields = [
      ['name', !isBlank(payload.name), t('check.fieldMissing', ['name'])],
      ['description', !isBlank(payload.description), t('check.fieldMissing', ['description'])],
      ['author', !isBlank(payload.author), t('check.fieldMissing', ['author'])],
      ['homepage', homepage != null, payload.homepage == null ? t('check.fieldMissing', ['homepage']) : t('check.homepageInvalid')],
      ['locale', locale != null, payload.locale == null ? t('check.fieldMissing', ['locale']) : t('check.localeInvalid')]
    ];
    fields.forEach(function (field) {
      if (!field[1]) {
        checks.push(check('fail', field[2], isBlank(payload[field[0]]) ? null : t('check.found', [payload[field[0]]])));
      }
    });

    var skipped = [];
    var duplicates = [];
    var seen = {};
    var counts = { deny: 0, allow: 0 };
    payload.filters.forEach(function (record, index) {
      var reason = recordProblem(record);
      if (reason) {
        skipped.push(t('record.reason', [recordLabel(record, index), reason]));
        return;
      }
      var text = record.text.trim();
      var filterCase = record.matching === 'regex' ? 'insensitive' : record.case;
      var key = [text, record.target, record.matching, filterCase].join('|');
      if (seen[key]) {
        duplicates.push(t('record.repeats', [recordLabel(record, index), seen[key]]));
      } else {
        seen[key] = index + 1;
      }
      counts[record.type] += 1;
    });

    var usable = counts.deny + counts.allow;
    if (usable === 0) {
      checks.push(check('warn', t('check.noFilters'), t('check.noFiltersDetail')));
    } else {
      checks.push(check('pass', plural('check.filterCount', usable, [usable, counts.deny, counts.allow])));
    }
    if (skipped.length) {
      checks.push(check('warn', plural('check.skipped', skipped.length, [skipped.length]), t('check.skippedDetail'), skipped));
    }
    if (duplicates.length) {
      checks.push(check('warn', plural('check.duplicates', duplicates.length, [duplicates.length]), t('check.duplicatesDetail'), duplicates));
    }

    return {
      checks: checks,
      payload: payload,
      needsFile: false,
      preview: { name: payload.name, author: payload.author, description: payload.description, locale: locale, homepage: homepage }
    };
  }

  var CHEVRON = '<svg class="chev" viewBox="0 0 10 10" aria-hidden="true"><path d="M3.5 1.5 7 5l-3.5 3.5" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/></svg>';

  function renderPreview(preview) {
    var stageEl = el('div', 'preview');
    var row = el('div', 'lrow open');
    var main = el('div', 'lrow-main');
    var title = el('div', 'lrow-title');
    title.insertAdjacentHTML('beforeend', CHEVRON);
    title.appendChild(isBlank(preview.name) ? el('span', 'p-name missing', t('result.noName')) : withAutoDirection(el('span', 'p-name', preview.name.trim())));
    if (!isBlank(preview.author)) title.appendChild(el('span', 'p-author', t('app.byAuthor', [preview.author.trim()])));
    main.appendChild(title);
    var info = el('div', 'lrow-info');
    if (preview.locale) info.appendChild(el('span', null, preview.locale.label));
    if (preview.locale && preview.homepage) info.appendChild(el('span', null, '·'));
    if (preview.homepage) {
      var link = el('a', 'p-home', preview.homepage.hostname.replace(/^www\./, ''));
      link.href = preview.homepage.href;
      link.target = '_blank';
      link.rel = 'noopener';
      info.appendChild(link);
    }
    if (info.childNodes.length) main.appendChild(info);
    main.appendChild(isBlank(preview.description) ? el('div', 'p-desc missing', t('result.noDescription')) : withAutoDirection(el('div', 'p-desc', preview.description.trim())));
    row.appendChild(main);
    row.appendChild(el('span', 'switch on'));
    stageEl.appendChild(row);
    return stageEl;
  }

  function renderVerdict(level, title, text) {
    var icons = { pass: '✓', warn: '!', fail: '✕' };
    var verdict = el('div', 'verdict ' + level);
    verdict.appendChild(el('span', 'verdict-icon', icons[level]));
    var body = el('div');
    body.appendChild(el('h3', null, title));
    body.appendChild(el('p', 'small', text));
    verdict.appendChild(body);
    return verdict;
  }

  function render(result, container) {
    container.textContent = '';
    var levels = result.checks.map(function (c) { return c.level; });
    var verdict = null;
    if (levels.indexOf('fail') >= 0) {
      verdict = renderVerdict('fail', t('result.failTitle'), t('result.failText'));
    } else if (!result.preview) {
      verdict = null;
    } else if (levels.indexOf('warn') >= 0) {
      verdict = renderVerdict('warn', t('result.warnTitle'), t('result.warnText'));
    } else {
      verdict = renderVerdict('pass', t('result.passTitle'), t('result.passText'));
    }
    if (verdict) container.appendChild(verdict);
    if (result.preview) container.appendChild(renderPreview(result.preview));

    var list = el('ul', 'issues');
    var icons = { pass: '✓', fail: '✕', warn: '!', info: 'i' };
    result.checks.forEach(function (c) {
      var item = el('li', c.level);
      item.appendChild(el('span', 'ic', icons[c.level]));
      var body = el('div');
      body.appendChild(document.createTextNode(c.text));
      if (c.detail) body.appendChild(el('span', 'd', c.detail));
      if (c.link) {
        var link = el('a', null, c.link.text);
        link.href = c.link.href;
        link.target = '_blank';
        link.rel = 'noopener';
        var line = el('span', 'd');
        line.appendChild(link);
        body.appendChild(line);
      }
      if (c.items && c.items.length) {
        var details = el('details');
        details.appendChild(el('summary', null, t('result.showThem')));
        var ul = el('ul');
        c.items.slice(0, 200).forEach(function (text) { ul.appendChild(el('li', null, text)); });
        if (c.items.length > 200) ul.appendChild(el('li', null, t('result.andMore', [c.items.length - 200])));
        details.appendChild(ul);
        body.appendChild(details);
      }
      item.appendChild(body);
      list.appendChild(item);
    });
    if (list.childNodes.length) container.appendChild(list);
  }

  function fileName(href) {
    return decodeURIComponent(new URL(href).pathname.split('/').pop() || href);
  }

  function dropFileCheck(text, downloadURL) {
    var info = check('info', t('url.dropToTest'), text);
    info.link = { text: t('url.download', [fileName(downloadURL)]), href: downloadURL };
    return info;
  }

  async function testGitHubRelease(owner, repo, assetName, checks) {
    var response;
    try {
      response = await fetch('https://api.github.com/repos/' + owner + '/' + repo + '/releases/latest', { headers: { Accept: 'application/vnd.github+json' } });
    } catch (e) {
      checks.push(check('warn', t('release.unreachable'), e.message));
      return null;
    }
    if (response.status === 404) {
      checks.push(check('fail', t('release.none', [owner + '/' + repo]), t('release.noneDetail')));
      return null;
    }
    if (!response.ok) {
      checks.push(check('warn', t('release.noAnswer', [response.status]), t('release.tryLater')));
      return null;
    }
    var release = await response.json();
    var assets = release.assets || [];
    var asset = assets.find(function (a) { return a.name === assetName; });
    if (!asset) {
      var names = assets.map(function (a) { return a.name; });
      checks.push(check('fail', t('release.missingFile', [release.tag_name, assetName]), names.length ? t('release.otherFiles', [names.join(', ')]) : t('release.noFiles')));
      return null;
    }
    checks.push(check('pass', t('release.hasFile', [release.tag_name, assetName])));
    checks.push(dropFileCheck(t('url.githubDownload'), asset.browser_download_url));
    return asset.browser_download_url;
  }

  async function checkURL(value) {
    var checks = [];
    var url;
    try { url = new URL(value.trim()); } catch (e) { url = null; }
    if (!url || url.protocol !== 'https:' || !url.hostname) {
      checks.push(check('fail', t('url.mustBeHTTPS')));
      return { checks: checks, needsFile: false };
    }
    var href = url.href;
    var latest = href.match(/^https:\/\/github\.com\/([^/]+)\/([^/]+)\/releases\/latest\/download\/([^/?#]+)$/);
    var pinned = href.match(/^https:\/\/github\.com\/([^/]+)\/([^/]+)\/releases\/download\/([^/]+)\/([^/?#]+)$/);
    if (/^https:\/\/github\.com\/[^/]+\/[^/]+\/(blob|tree)\//.test(href)) {
      checks.push(check('fail', t('url.githubPage'), t('url.useLatest')));
      return { checks: checks, needsFile: false };
    }
    if (latest) {
      var assetURL = await testGitHubRelease(latest[1], latest[2], decodeURIComponent(latest[3]), checks);
      return { checks: checks, needsFile: assetURL != null, downloadURL: assetURL };
    }
    if (pinned) {
      checks.push(check('warn', t('url.pinned', [decodeURIComponent(pinned[3])]), t('url.pinnedDetail')));
      checks.push(dropFileCheck(t('url.githubBlocksBrowsers'), href));
      return { checks: checks, needsFile: true, downloadURL: href };
    }
    var response;
    try {
      response = await fetch(href, { cache: 'no-store' });
    } catch (e) {
      var blocked = check('info', t('url.browserCantRead'), t('url.browserCantReadDetail'));
      blocked.link = { text: t('url.download', [fileName(href)]), href: href };
      checks.push(blocked);
      return { checks: checks, needsFile: true, downloadURL: href };
    }
    if (!response.ok) {
      checks.push(check('fail', t('url.httpStatus', [response.status]), t('url.needsFile')));
      return { checks: checks, needsFile: false };
    }
    var text = await response.text();
    if (/^\s*</.test(text)) {
      checks.push(check('fail', t('url.webPage'), t('url.useDownloadURL')));
      return { checks: checks, needsFile: false };
    }
    return validate(text);
  }

  function readFile(file) {
    return new Promise(function (resolve) {
      var reader = new FileReader();
      reader.onload = function () {
        resolve(validate(String(reader.result)));
      };
      reader.onerror = function () {
        resolve({ checks: [check('fail', t('url.cantReadFile', [file.name]))], needsFile: false });
      };
      reader.readAsText(file);
    });
  }

  function hasFailure(result) {
    return result.checks.some(function (c) { return c.level === 'fail'; });
  }

  function bindDrop(drop, fileInput, onFile) {
    fileInput.addEventListener('change', function () {
      if (fileInput.files[0]) onFile(fileInput.files[0]);
      fileInput.value = '';
    });
    ['dragenter', 'dragover'].forEach(function (name) {
      drop.addEventListener(name, function (event) { event.preventDefault(); drop.classList.add('over'); });
    });
    ['dragleave', 'drop'].forEach(function (name) {
      drop.addEventListener(name, function () { drop.classList.remove('over'); });
    });
    drop.addEventListener('drop', function (event) {
      event.preventDefault();
      if (event.dataTransfer.files[0]) onFile(event.dataTransfer.files[0]);
    });
  }

  window.ListCheck = { validate: validate, checkURL: checkURL, readFile: readFile, render: render, hasFailure: hasFailure, bindDrop: bindDrop, fileName: fileName };
})();
