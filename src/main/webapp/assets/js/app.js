/**
 * Java Servlet サンプル集 : サイト共通の JavaScript
 *
 *  - ソースコードのシンタックスハイライト (highlight.js)
 *  - コードのコピーボタン
 *  - タブの状態を URL に残す (#pane-code など)
 */
(function () {
  'use strict';

  document.addEventListener('DOMContentLoaded', function () {
    highlightSourceCode();
    setupCopyButtons();
    setupTabHash();
  });

  /** ソースコード表示にシンタックスハイライトを適用する。 */
  function highlightSourceCode() {
    if (typeof window.hljs === 'undefined') {
      return;
    }
    var blocks = document.querySelectorAll('.code-block__code code');
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
    });
  }
})();
