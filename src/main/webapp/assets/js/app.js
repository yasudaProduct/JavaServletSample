/**
 * Java Servlet サンプル集 : サイト共通の JavaScript
 *
 *  - ソースコードのシンタックスハイライト (highlight.js)
 *  - コードのコピーボタン
 *  - タブの状態を URL に残す (#pane-code など)
 *  - 横に長い表に「横へスクロールできる」印を付ける (スマートフォン対策)
 */
(function () {
  'use strict';

  document.addEventListener('DOMContentLoaded', function () {
    highlightSourceCode();
    setupCopyButtons();
    setupTabHash();
    setupScrollableTables();
  });

  /** ソースコード表示にシンタックスハイライトを適用する。 */
  function highlightSourceCode() {
    if (typeof window.hljs === 'undefined') {
      return;
    }
    // ソースコード表示のほか、解説・デモ・座学メモに書いた短いコード片も色付けする
    // (座学メモの図は <pre class="topic-figure"> で <code> を持たないため対象外になる)
    var blocks = document.querySelectorAll(
      '.code-block__code code, .sample-note pre code, pre.code-snippet code, '
      + '.topic-body pre code');
    Array.prototype.forEach.call(blocks, function (block) {
      window.hljs.highlightElement(block);
    });
  }

  /** 「コピー」ボタンでソースコードをクリップボードへコピーする。 */
  function setupCopyButtons() {
    var buttons = document.querySelectorAll('[data-code-copy]');
    Array.prototype.forEach.call(buttons, function (button) {
      button.addEventListener('click', function () {
        var container = button.closest('.code-block');
        var code = container ? container.querySelector('.code-block__code code') : null;
        if (!code) {
          return;
        }
        copyToClipboard(code.textContent).then(function (succeeded) {
          showCopyResult(button, succeeded);
        });
      });
    });
  }

  /**
   * クリップボードへコピーする。
   * Clipboard API が使えない環境 (http 経由の古いブラウザなど) では
   * テキストエリアを作る昔ながらの方法にフォールバックする。
   */
  function copyToClipboard(text) {
    if (navigator.clipboard && window.isSecureContext) {
      return navigator.clipboard.writeText(text)
        .then(function () { return true; })
        .catch(function () { return legacyCopy(text); });
    }
    return Promise.resolve(legacyCopy(text));
  }

  function legacyCopy(text) {
    var textarea = document.createElement('textarea');
    textarea.value = text;
    textarea.setAttribute('readonly', '');
    textarea.style.position = 'fixed';
    textarea.style.opacity = '0';
    document.body.appendChild(textarea);
    textarea.select();
    var succeeded = false;
    try {
      succeeded = document.execCommand('copy');
    } catch (e) {
      succeeded = false;
    }
    document.body.removeChild(textarea);
    return succeeded;
  }

  function showCopyResult(button, succeeded) {
    var original = button.dataset.originalLabel || button.textContent;
    button.dataset.originalLabel = original;
    button.textContent = succeeded ? 'コピーしました' : 'コピーできません';
    button.classList.toggle('is-copied', succeeded);
    window.setTimeout(function () {
      button.textContent = original;
      button.classList.remove('is-copied');
    }, 1600);
  }

  /**
   * サンプルページのタブを URL のハッシュと連動させる。
   * (「ソースコードのタブを開いた状態」のリンクを共有できるようにするため)
   */
  function setupTabHash() {
    var tabLinks = document.querySelectorAll('.sample-tabs a[data-toggle="tab"]');
    if (tabLinks.length === 0 || !window.jQuery) {
      return;
    }

    var hash = window.location.hash;
    if (hash) {
      var target = document.querySelector('.sample-tabs a[href="' + hash + '"]');
      if (target) {
        window.jQuery(target).tab('show');
      }
    }

    window.jQuery(tabLinks).on('shown.bs.tab', function (event) {
      var href = event.target.getAttribute('href');
      if (href && window.history && window.history.replaceState) {
        // 画面がジャンプしないよう replaceState で URL だけ書き換える
        window.history.replaceState(null, '', href);
      }
      // 隠れていた表は幅が測れないため、表示されてから測り直す
      updateScrollableTables();
    });
  }

  /**
   * 横にはみ出している表 (.table-responsive) に印を付ける。
   *
   * Bootstrap の .table-responsive は、はみ出したら横スクロールになるだけなので、
   * スマートフォンでは「右にまだ列がある」ことに気づけません。
   * 実際にはみ出している枠にだけ is-scrollable を付け、
   * CSS 側で右端に影を出し、「横にスクロールできます」の案内を添えます。
   */
  function setupScrollableTables() {
    var areas = document.querySelectorAll('.table-responsive');
    if (areas.length === 0) {
      return;
    }

    // Ajax のデモのように、あとから行が増える表もあるので幅の変化も見張る
    var observer = (typeof window.ResizeObserver === 'function')
      ? new window.ResizeObserver(updateScrollableTables) : null;

    Array.prototype.forEach.call(areas, function (area) {
      // スクロールしきったら影を消す (まだ続きがあるときだけ出したいため)
      area.addEventListener('scroll', function () {
        var atEnd = area.scrollLeft + area.clientWidth >= area.scrollWidth - 1;
        area.classList.toggle('is-scroll-end', atEnd);
      });
      if (observer) {
        observer.observe(area);
        var table = area.querySelector('table');
        if (table) {
          observer.observe(table);
        }
      }
    });

    updateScrollableTables();
    window.addEventListener('resize', updateScrollableTables);
  }

  /** いまの幅ではみ出しているかどうかを測り直す。 */
  function updateScrollableTables() {
    var areas = document.querySelectorAll('.table-responsive');
    Array.prototype.forEach.call(areas, function (area) {
      var scrollable = area.scrollWidth > area.clientWidth + 1;
      area.classList.toggle('is-scrollable', scrollable);
      if (!scrollable) {
        area.classList.remove('is-scroll-end');
      }
      toggleScrollHint(area, scrollable);
      toggleScrollFocus(area, scrollable);
    });
  }

  /**
   * はみ出している表を、キーボードでも横にスクロールできるようにする。
   *
   * マウスやタッチが無いと、横スクロールする枠は動かせません。
   * tabindex="0" を付けると Tab で枠に入れるようになり、矢印キーでスクロールできます。
   * ただし Tab で止まる場所が増えるので、実際にはみ出しているときだけ付けます。
   *
   * 枠に入ったとき何の表なのかが分かるよう、role="region" と
   * aria-label (表の caption) もあわせて付けます。
   * 解説: /samples/a11y/accessible-table
   */
  function toggleScrollFocus(area, scrollable) {
    if (!scrollable) {
      area.removeAttribute('tabindex');
      area.removeAttribute('role');
      area.removeAttribute('aria-label');
      return;
    }
    if (area.getAttribute('tabindex') === '0') {
      return;
    }
    var caption = area.querySelector('table > caption');
    var title = caption ? caption.textContent.trim() : '';

    area.setAttribute('tabindex', '0');
    area.setAttribute('role', 'region');
    area.setAttribute('aria-label', title
      ? title + '（横にスクロールできます）'
      : '横にスクロールできる表');
  }

  /** 表のすぐ下に出す「横にスクロールできます」の案内を出し入れする。 */
  function toggleScrollHint(area, scrollable) {
    var next = area.nextElementSibling;
    var hint = (next && next.classList.contains('table-scroll-hint')) ? next : null;

    if (!scrollable) {
      if (hint) {
        hint.parentNode.removeChild(hint);
      }
      return;
    }
    if (hint) {
      return;
    }
    hint = document.createElement('p');
    hint.className = 'table-scroll-hint';
    hint.setAttribute('aria-hidden', 'true');
    hint.textContent = '← 表は横にスクロールできます →';
    area.parentNode.insertBefore(hint, area.nextSibling);
  }
})();
