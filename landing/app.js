/* AppRelease — landing behaviour: menu, sticky header, reveals, tabs,
   copy buttons, the release console animation, pricing toggle, docs search
   and the docs table of contents. No framework, no build step. */
(function () {
  'use strict';

  var reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  /* ---------------------------------------------------------------- menu */

  var burger = document.getElementById('burger');
  var menu = document.getElementById('menu');
  if (burger && menu) {
    burger.addEventListener('click', function () {
      var open = !menu.classList.contains('is-open');
      menu.classList.toggle('is-open', open);
      burger.setAttribute('aria-expanded', String(open));
    });
    menu.querySelectorAll('a').forEach(function (a) {
      a.addEventListener('click', function () {
        menu.classList.remove('is-open');
        burger.setAttribute('aria-expanded', 'false');
      });
    });
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && menu.classList.contains('is-open')) {
        menu.classList.remove('is-open');
        burger.setAttribute('aria-expanded', 'false');
        burger.focus();
      }
    });
  }

  /* -------------------------------------------------------- sticky header */

  var header = document.getElementById('header');
  if (header) {
    var onScroll = function () { header.classList.toggle('is-stuck', window.scrollY > 8); };
    onScroll();
    window.addEventListener('scroll', onScroll, { passive: true });
  }

  /* -------------------------------------------------------------- reveals */

  var reveals = document.querySelectorAll('.reveal, .rise');
  if (!('IntersectionObserver' in window) || reduceMotion) {
    reveals.forEach(function (el) { el.classList.add('is-in'); });
  } else {
    var observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add('is-in');
          observer.unobserve(entry.target);
        }
      });
    }, { rootMargin: '0px 0px -8% 0px', threshold: 0.08 });
    reveals.forEach(function (el) { observer.observe(el); });
  }

  /* ----------------------------------------------------------------- tabs */

  document.querySelectorAll('[data-tabs]').forEach(function (root) {
    var buttons = root.querySelectorAll('[role="tab"]');
    var panes = root.querySelectorAll('[role="tabpanel"]');
    function select(index) {
      buttons.forEach(function (b, i) {
        var on = i === index;
        b.setAttribute('aria-selected', String(on));
        b.tabIndex = on ? 0 : -1;
      });
      panes.forEach(function (p, i) { p.classList.toggle('is-active', i === index); });
    }
    buttons.forEach(function (b, i) {
      b.addEventListener('click', function () { select(i); });
      b.addEventListener('keydown', function (e) {
        if (e.key === 'ArrowRight') { select((i + 1) % buttons.length); buttons[(i + 1) % buttons.length].focus(); }
        if (e.key === 'ArrowLeft')  { select((i - 1 + buttons.length) % buttons.length); buttons[(i - 1 + buttons.length) % buttons.length].focus(); }
      });
    });
    select(0);
  });

  /* ----------------------------------------------------------------- copy */

  document.querySelectorAll('.code').forEach(function (block) {
    block.querySelectorAll('.code-pane, pre').forEach(function (pane) {
      if (pane.tagName === 'PRE' && pane.parentElement.classList.contains('code-pane')) return;
      var pre = pane.tagName === 'PRE' ? pane : pane.querySelector('pre');
      if (!pre || !navigator.clipboard) return;
      var host = pane.tagName === 'PRE' ? block : pane;
      if (getComputedStyle(host).position === 'static') host.style.position = 'relative';
      var btn = document.createElement('button');
      btn.type = 'button'; btn.className = 'copy'; btn.textContent = 'Copy';
      btn.addEventListener('click', function () {
        navigator.clipboard.writeText(pre.innerText).then(function () {
          btn.textContent = 'Copied'; btn.classList.add('is-done');
          setTimeout(function () { btn.textContent = 'Copy'; btn.classList.remove('is-done'); }, 1600);
        });
      });
      host.appendChild(btn);
    });
  });

  /* -------------------------------------------------------- release console */

  var consoleEl = document.querySelector('[data-console]');
  if (consoleEl) {
    var body = consoleEl.querySelector('.console-body');
    var status = consoleEl.querySelector('.console-status');
    var runs = [
      {
        title: 'Android · production',
        lines: [
          ['Checking out <span class="console-cmd">main</span> @ 4f2e1c9', 1.1],
          ['Flutter 3.41.2 · stable · Dart 3.11', 0.6],
          ['<span class="console-cmd">flutter pub get</span>', 1.4],
          ['Build number from Google Play: 56 → <b>57</b>', 0.9],
          ['<span class="console-cmd">flutter build appbundle --release</span>', 3.2],
          ['Signed with upload key · <span class="console-cmd">release.jks</span>', 0.8],
          ['Uploading app-release.aab · 38.4 MB', 1.9],
          ['Rolled out to <span class="console-cmd">internal</span> track', 0.6]
        ],
        done: 'Released 1.4.0 (57) to Google Play'
      },
      {
        title: 'iOS · TestFlight',
        lines: [
          ['Checking out <span class="console-cmd">release/1.4</span> @ b91a0ff', 1.0],
          ['Xcode 26.0 · Flutter 3.41.2 · stable', 0.6],
          ['Fetched signing files from App Store Connect', 1.2],
          ['Build number from App Store Connect: 88 → <b>89</b>', 0.9],
          ['<span class="console-cmd">flutter build ipa --release --export-options-plist</span>', 3.6],
          ['Uploading Runner.ipa · 61.2 MB', 2.1],
          ['Waiting for processing… done', 1.6],
          ['Submitted to <span class="console-cmd">Beta testers</span> group', 0.5]
        ],
        done: 'Build 1.4.0 (89) is on TestFlight'
      }
    ];
    var runIndex = 0;

    function fmt(seconds) { return seconds < 60 ? seconds.toFixed(1) + 's' : Math.floor(seconds / 60) + 'm ' + Math.round(seconds % 60) + 's'; }

    function play() {
      var run = runs[runIndex % runs.length];
      runIndex += 1;
      body.innerHTML = '';
      status.textContent = 'BUILDING'; status.classList.remove('is-live');
      consoleEl.querySelector('.console-title').textContent = run.title;

      var i = 0;
      function step() {
        if (i < run.lines.length) {
          var line = document.createElement('div');
          line.className = 'console-line is-running';
          line.innerHTML = '<span class="tick"></span><span>' + run.lines[i][0] + '</span><span class="t"></span>';
          body.appendChild(line);
          requestAnimationFrame(function () { line.classList.add('is-in'); });
          var took = run.lines[i][1] * (reduceMotion ? 0.3 : 1);
          var started = Date.now();
          var ticker = setInterval(function () {
            line.querySelector('.t').textContent = fmt((Date.now() - started) / 1000 / (reduceMotion ? 0.3 : 1));
          }, 100);
          setTimeout(function () {
            clearInterval(ticker);
            line.querySelector('.t').textContent = fmt(run.lines[i][1]);
            line.classList.remove('is-running'); line.classList.add('is-done');
            i += 1; step();
          }, took * 1000 * (reduceMotion ? 1 : 0.55));
        } else {
          var final = document.createElement('div');
          final.className = 'console-line is-final';
          final.innerHTML = '<span class="tick"></span><span>' + run.done + '</span>';
          body.appendChild(final);
          requestAnimationFrame(function () { final.classList.add('is-in'); });
          status.textContent = 'LIVE'; status.classList.add('is-live');
          setTimeout(play, 4200);
        }
      }
      step();
    }
    play();
  }

  /* ---------------------------------------------------------------- stage */

  var stage = document.querySelector('[data-stage]');
  if (stage) {
    var nodes = stage.querySelectorAll('.stage-node');
    var fill = stage.querySelector('.stage-fill');
    var parcel = stage.querySelector('.parcel');
    var logEl = stage.querySelector('[data-stage-log]');
    var timeEl = stage.querySelector('[data-stage-time]');
    var track = stage.querySelector('.stage-track');
    var script = [
      ['Checking out main @ 4f2e1c9', 1.6],
      ['flutter build appbundle --release --build-number=57', 3.4],
      ['Signed with upload_keystore · keys wiped after the build', 1.4],
      ['Build number from Google Play: 56 → 57 · uploading 38.4 MB', 2.2],
      ['Released 1.4.0 (57) · Google Play internal · TestFlight', 3.2]
    ];
    var isWide = function () { return window.innerWidth >= 900; };

    function placeParcel(index) {
      if (!isWide()) return;
      var node = nodes[index];
      var ico = node.querySelector('.stage-ico') || node;
      var a = ico.getBoundingClientRect(), b = track.getBoundingClientRect();
      parcel.style.left = (a.left + a.width / 2 - b.left) + 'px';
    }

    function runStage() {
      var i = 0;
      nodes.forEach(function (n) { n.classList.remove('is-active', 'is-done'); });
      stage.classList.remove('is-live');
      if (isWide()) { fill.style.width = '0%'; } else { fill.style.height = '0%'; }
      parcel.classList.remove('is-hidden');
      placeParcel(0);

      function step() {
        if (i > 0) nodes[i - 1].classList.replace('is-active', 'is-done');
        if (i === nodes.length - 1) parcel.classList.add('is-hidden');
        if (i >= nodes.length) {
          stage.classList.add('is-live');
          setTimeout(runStage, 3600);
          return;
        }
        nodes[i].classList.add('is-active');
        var pct = (i / (nodes.length - 1)) * 100;
        if (isWide()) { fill.style.width = pct + '%'; } else { fill.style.height = pct + '%'; }
        placeParcel(i);
        logEl.textContent = script[i][0];
        var took = script[i][1] * (reduceMotion ? 0.5 : 1);
        var started = Date.now();
        var tick = setInterval(function () { timeEl.textContent = ((Date.now() - started) / 1000).toFixed(1) + 's'; }, 100);
        setTimeout(function () {
          clearInterval(tick);
          timeEl.textContent = script[i][1].toFixed(1) + 's';
          i += 1; step();
        }, took * 1000 * 0.6);
      }
      step();
    }
    runStage();
    window.addEventListener('resize', function () { placeParcel(Math.max(0, Array.prototype.findIndex.call(nodes, function (n) { return n.classList.contains('is-active'); }))); });
  }

  /* ----------------------------------------------------------------- tilt */

  if (!reduceMotion && window.matchMedia('(hover: hover)').matches) {
    document.querySelectorAll('.tilt').forEach(function (card) {
      card.addEventListener('mousemove', function (e) {
        var r = card.getBoundingClientRect();
        var x = (e.clientX - r.left) / r.width - 0.5;
        var y = (e.clientY - r.top) / r.height - 0.5;
        card.style.transform = 'perspective(900px) rotateX(' + (-y * 5) + 'deg) rotateY(' + (x * 5) + 'deg) translateY(-2px)';
      });
      card.addEventListener('mouseleave', function () { card.style.transform = ''; });
    });
  }

  /* ----------------------------------------------------------- time calc */

  var calc = document.querySelector('[data-calc]');
  if (calc) {
    var out = document.querySelector('[data-calc-out]');
    var hours = document.querySelector('[data-calc-hours]');
    var days = document.querySelector('[data-calc-days]');
    function update() {
      var n = parseInt(calc.value, 10);
      var h = Math.round(n * 70 / 60);
      var d = Math.max(1, Math.round(h / 8));
      out.textContent = n;
      hours.textContent = h + ' h';
      days.textContent = d + (d === 1 ? ' working day' : ' working days');
    }
    calc.addEventListener('input', update);
    update();
  }

  /* -------------------------------------------------------- pricing toggle */

  var toggle = document.querySelector('[data-cycle]');
  if (toggle) {
    var buttons = toggle.querySelectorAll('button');
    function cycle(mode) {
      buttons.forEach(function (b) { b.classList.toggle('is-active', b.dataset.mode === mode); });
      document.querySelectorAll('[data-yearly]').forEach(function (el) {
        el.textContent = mode === 'yearly' ? el.dataset.yearly : el.dataset.monthly;
      });
      document.querySelectorAll('[data-cycle-note]').forEach(function (el) {
        el.textContent = mode === 'yearly' ? el.dataset.noteYearly : el.dataset.noteMonthly;
      });
    }
    buttons.forEach(function (b) { b.addEventListener('click', function () { cycle(b.dataset.mode); }); });
    cycle('monthly');
  }

  /* ------------------------------------------------------------ docs: toc */

  var toc = document.querySelector('.docs-toc ol');
  var article = document.querySelector('.docs-article');
  if (toc && article) {
    var heads = article.querySelectorAll('h2[id]');
    heads.forEach(function (h) {
      var li = document.createElement('li');
      var a = document.createElement('a');
      a.href = '#' + h.id; a.textContent = h.textContent;
      li.appendChild(a); toc.appendChild(li);
    });
    var links = toc.querySelectorAll('a');
    if ('IntersectionObserver' in window && heads.length) {
      var current = null;
      var spy = new IntersectionObserver(function (entries) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting) current = entry.target.id;
        });
        if (current) links.forEach(function (l) { l.classList.toggle('is-active', l.getAttribute('href') === '#' + current); });
      }, { rootMargin: '-80px 0px -70% 0px', threshold: 0 });
      heads.forEach(function (h) { spy.observe(h); });
    }
  }

  var sideToggle = document.querySelector('.docs-side-toggle');
  var sideNav = document.querySelector('.docs-nav');
  if (sideToggle && sideNav) {
    sideToggle.addEventListener('click', function () { sideNav.classList.toggle('is-open'); });
  }

  /* --------------------------------------------------------- docs: search */

  var search = document.querySelector('.docs-search');
  if (search) {
    var input = search.querySelector('input');
    var list = search.querySelector('ul');
    var index = [];
    document.querySelectorAll('.docs-nav a[href]').forEach(function (a) {
      if (a.classList.contains('soon')) return;
      var section = a.closest('.docs-nav') ? (a.previousElementSibling && a.previousElementSibling.tagName === 'H4' ? a.previousElementSibling.textContent : '') : '';
      index.push({ title: a.textContent.trim(), href: a.getAttribute('href'), section: section });
    });
    if (article) {
      article.querySelectorAll('h2[id], h3[id]').forEach(function (h) {
        index.push({ title: h.textContent.trim(), href: '#' + h.id, section: 'On this page' });
      });
    }
    function render(q) {
      list.innerHTML = '';
      var needle = q.trim().toLowerCase();
      if (!needle) { list.classList.remove('is-open'); return; }
      var hits = index.filter(function (e) { return e.title.toLowerCase().indexOf(needle) !== -1; }).slice(0, 8);
      if (!hits.length) {
        list.innerHTML = '<li><a><small>No results</small></a></li>';
      } else {
        hits.forEach(function (e) {
          var li = document.createElement('li');
          li.innerHTML = '<a href="' + e.href + '">' + e.title + (e.section ? '<small>' + e.section + '</small>' : '') + '</a>';
          list.appendChild(li);
        });
      }
      list.classList.add('is-open');
    }
    input.addEventListener('input', function () { render(input.value); });
    input.addEventListener('focus', function () { render(input.value); });
    document.addEventListener('click', function (e) { if (!search.contains(e.target)) list.classList.remove('is-open'); });
    input.addEventListener('keydown', function (e) {
      var hot = list.querySelector('.is-hot') || list.querySelector('a');
      if (e.key === 'Enter' && hot && hot.getAttribute('href')) { window.location.href = hot.getAttribute('href'); }
      if (e.key === 'Escape') { list.classList.remove('is-open'); input.blur(); }
    });
    document.addEventListener('keydown', function (e) {
      if (e.key === '/' && document.activeElement !== input && !/input|textarea/i.test(document.activeElement.tagName)) {
        e.preventDefault(); input.focus();
      }
    });
  }

  /* --------------------------------------------------------- branch rules
     Pick a branch, watch which rule matches and where the build lands.
     Plays through the branches by itself until someone clicks. */
  var br = document.querySelector('[data-branches]');
  if (br) {
    var PLANS = {
      'develop': { rule: 'develop', out: [['android #58', 'internal'], ['ios #58', 'TestFlight']], dests: ['internal', 'testflight'] },
      'release/2.1': { rule: 'release/*', out: [['android #59', 'beta'], ['ios #59', 'TestFlight']], dests: ['beta', 'testflight'] },
      'main': { rule: 'main', out: [['android #60', 'production'], ['ios #60', 'App Store review']], dests: ['production', 'appStore'] },
      'v1.5.0': { rule: 'tag', out: [['android #61', 'production · 1.5.0'], ['ios #61', 'App Store review · 1.5.0']], dests: ['production', 'appStore'] },
      'feature/login': { rule: null, out: [], dests: [] }
    };
    var order = ['develop', 'release/2.1', 'main', 'v1.5.0', 'feature/login'];
    var buttons = br.querySelectorAll('[data-push]'), rules = br.querySelectorAll('[data-rule]'), dests = br.querySelectorAll('[data-dest]');
    var outEl = br.querySelector('[data-sim-out]'), branchEl = br.querySelector('[data-sim-branch]');
    var timers = [], auto = null, idx = 0;
    function later(fn, ms) { timers.push(setTimeout(fn, reduceMotion ? 0 : ms)); }
    function line(text, cls) { var d = document.createElement('div'); if (cls) d.className = cls; d.textContent = text; outEl.appendChild(d); }
    function play(name) {
      timers.forEach(clearTimeout); timers = [];
      var plan = PLANS[name];
      buttons.forEach(function (b) { b.classList.toggle('is-on', b.getAttribute('data-push') === name); });
      rules.forEach(function (r) { r.classList.remove('is-hit', 'is-miss'); });
      dests.forEach(function (d) { d.classList.remove('is-hit'); });
      branchEl.textContent = /^v\d/.test(name) ? name + ' (tag)' : name;
      outEl.innerHTML = '';
      later(function () { line('webhook received · ' + (plan.rule ? 'rule ' + (plan.rule === 'tag' ? 'version tag' : plan.rule) : 'no rule'), 'dim'); }, 250);
      later(function () {
        rules.forEach(function (r) {
          var hit = r.getAttribute('data-rule') === plan.rule;
          r.classList.toggle('is-hit', hit); r.classList.toggle('is-miss', !hit);
        });
      }, 450);
      if (!plan.rule) { later(function () { line('nothing queued: feature branches stay on your machine', 'dim'); }, 700); return; }
      plan.out.forEach(function (o, i) { later(function () { line('queued ' + o[0] + ' → ' + o[1]); }, 750 + i * 350); });
      later(function () {
        dests.forEach(function (d) { d.classList.toggle('is-hit', plan.dests.indexOf(d.getAttribute('data-dest')) >= 0); });
        line('✓ signed with mekauto_upload_keystore · uploading', 'ok');
      }, 1500);
    }
    function stopAuto() { if (auto) { clearInterval(auto); auto = null; } }
    buttons.forEach(function (b) { b.addEventListener('click', function () { stopAuto(); play(b.getAttribute('data-push')); }); });
    var started = false;
    function start() {
      if (started) return; started = true; play(order[0]);
      if (!reduceMotion) auto = setInterval(function () { idx = (idx + 1) % order.length; play(order[idx]); }, 4200);
    }
    if ('IntersectionObserver' in window) {
      new IntersectionObserver(function (en, obs) { if (en[0].isIntersecting) { start(); obs.disconnect(); } }, { threshold: 0.3 }).observe(br);
    } else start();
  }
})();
