// The pages the till serves to tablets, TVs and second monitors. Plain
// HTML and JavaScript, no internet needed: each page asks the till for its
// state every second, and the fonts come from the till too (/f/...).
//
// Styled from the Aby brand guide: chalk ground, midnight panels, lime only
// where money moves or something is waiting. Sizes are in rem, and the root
// size follows the screen, so one page reads on a tablet and on a TV.

/// Fonts the till serves at /f/<name>, from the app's bundled fonts.
const displayFonts = {
  'figtree-400.ttf': 'fonts/Figtree-Regular.ttf',
  'figtree-600.ttf': 'fonts/Figtree-SemiBold.ttf',
  'figtree-700.ttf': 'fonts/Figtree-Bold.ttf',
  'figtree-800.ttf': 'fonts/Figtree-ExtraBold.ttf',
  'figtree-900.ttf': 'fonts/Figtree-Black.ttf',
  'mono-400.ttf': 'fonts/JetBrainsMono-Regular.ttf',
  'mono-700.ttf': 'fonts/JetBrainsMono-Bold.ttf',
};

const _head = r'''
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="theme-color" content="#101322">
<style>
  @font-face { font-family:Figtree; src:url(/f/figtree-400.ttf); font-weight:400; font-display:swap; }
  @font-face { font-family:Figtree; src:url(/f/figtree-600.ttf); font-weight:600; font-display:swap; }
  @font-face { font-family:Figtree; src:url(/f/figtree-700.ttf); font-weight:700; font-display:swap; }
  @font-face { font-family:Figtree; src:url(/f/figtree-800.ttf); font-weight:800; font-display:swap; }
  @font-face { font-family:Figtree; src:url(/f/figtree-900.ttf); font-weight:900; font-display:swap; }
  @font-face { font-family:"JetBrains Mono"; src:url(/f/mono-400.ttf); font-weight:400; font-display:swap; }
  @font-face { font-family:"JetBrains Mono"; src:url(/f/mono-700.ttf); font-weight:700; font-display:swap; }
  :root {
    --surface:#f6f7f2; --raised:#fff; --sunken:#ecede6; --line:#dfe1d8;
    --ink:#101322; --muted:#5a5e6b;
    --midnight:#101322; --midnight-raised:#1a1e33; --midnight-line:#2a2f47; --on-midnight:#f6f7f2; --on-midnight-muted:#a9adbd;
    --lime:#c8f560; --on-lime:#101322; --lime-soft:#ecfbc9; --lime-ink:#3f5a00;
    --primary:#101322; --on-primary:#f6f7f2;
    --blue:#3446e0; --blue-soft:#e6e9ff;
    --warning:#8a5300; --warning-soft:#fdf0d7; --danger:#c2361b; --danger-soft:#ffe6df;
    --r-sm:8px; --r-md:14px; --r-lg:24px;
    --shadow-sm:0 1px 2px rgb(16 19 34 / .06), 0 1px 3px rgb(16 19 34 / .08);
    --ease:cubic-bezier(.2,.8,.2,1);
  }
  /* Pages with a midnight panel stay on chalk (class="light"), so the two never blend. */
  @media (prefers-color-scheme: dark) {
    :root:not(.light) {
      --surface:#0b0d17; --raised:#161929; --sunken:#06070e; --line:#262a3d;
      --ink:#f1f3ea; --muted:#9ea2b3;
      --lime-soft:#1f2a0a; --lime-ink:#c8f560;
      --primary:#f1f3ea; --on-primary:#101322;
      --blue:#9aa5ff; --blue-soft:#1b2152;
      --warning:#f5b950; --warning-soft:#3a2a0b; --danger:#ff8a70; --danger-soft:#3b1510;
      --shadow-sm:none;
    }
  }
  * { box-sizing:border-box; margin:0; padding:0; }
  html { font-size:clamp(13px, 2.1vmin, 30px); }
  body { font-family:Figtree, system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; background:var(--surface); color:var(--ink);
    min-height:100vh; -webkit-font-smoothing:antialiased; overflow-x:hidden; }
  .money, .num { font-variant-numeric:tabular-nums; }
  .mono { font-family:"JetBrains Mono", ui-monospace, monospace; }
  .label { font-size:.8125rem; line-height:1.25; font-weight:700; letter-spacing:.05em; text-transform:uppercase; }
  .muted { color:var(--muted); }
  .hide { display:none !important; }
  .icon { width:1.25em; height:1.25em; flex:none; vertical-align:-.2em; }
  .mark { display:block; flex:none; }
  .mark .a { fill:currentColor; }
  .dot { display:inline-block; width:10px; height:10px; border-radius:50%; background:var(--lime); flex:none; }
  .pulse { animation:pulse 1.6s ease-out infinite; }
  @keyframes pulse { 0% { box-shadow:0 0 0 0 rgb(200 245 96 / .7); } 100% { box-shadow:0 0 0 .7em rgb(200 245 96 / 0); } }
  .powered { display:flex; align-items:center; gap:.5rem; font-size:.8125rem; }
  .lost { position:fixed; left:50%; bottom:1.5rem; transform:translateX(-50%); display:flex; align-items:center; gap:.5rem;
    background:var(--warning-soft); color:var(--warning); padding:.6rem 1.1rem; border-radius:999px; font-weight:700; font-size:.9rem; }
  @media (prefers-reduced-motion: reduce) {
    *, *::before, *::after { animation-duration:1ms !important; animation-iteration-count:1 !important; transition-duration:1ms !important; }
    .pulse { animation:none; }
  }
</style>
''';

// The waiting-dot a. The body follows CSS colour; the dot is always lime.
const _mark =
    r'''<svg class="mark" viewBox="5.25 18 100 100" aria-hidden="true"><path class="a" d="M44.78 30.86 A37.5 37.5 0 1 1 13.32 75.80 A10.5 10.5 0 0 1 33.86 71.43 A16.5 16.5 0 1 0 47.70 51.66 A10.5 10.5 0 0 1 44.78 30.86 Z M77 48.5 A10.5 10.5 0 0 1 98 48.5 L98 95.5 A10.5 10.5 0 0 1 77 95.5 Z"/><path fill="#c8f560" d="M18.38 52.51 a9.5 9.5 0 1 0 19.0 0 a9.5 9.5 0 1 0 -19.0 0 Z"/></svg>''';

// Lucide icons from the brand set.
const _svg =
    '<svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">';
const _iconTag =
    '$_svg<path d="M12.586 2.586A2 2 0 0 0 11.172 2H4a2 2 0 0 0-2 2v7.172a2 2 0 0 0 .586 1.414l8.704 8.704a2.426 2.426 0 0 0 3.42 0l6.58-6.58a2.426 2.426 0 0 0 0-3.42z"/><circle cx="7.5" cy="7.5" r=".5" fill="currentColor"/></svg>';
const _iconClock = '$_svg<circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/></svg>';
const _iconSmartphone = '$_svg<rect width="14" height="20" x="5" y="2" rx="2" ry="2"/><path d="M12 18h.01"/></svg>';
const _iconCheck = '$_svg<path d="M20 6 9 17l-5-5"/></svg>';
const _iconBell =
    '$_svg<path d="M10.268 21a2 2 0 0 0 3.464 0"/><path d="M3.262 15.326A1 1 0 0 0 4 17h16a1 1 0 0 0 .74-1.673C19.41 13.956 18 12.499 18 8A6 6 0 0 0 6 8c0 4.499-1.411 5.956-2.738 7.326"/></svg>';
const _iconAlert =
    '$_svg<path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3"/><path d="M12 9v4"/><path d="M12 17h.01"/></svg>';

const _js = r'''
function money(p) {
  const neg = p < 0; p = Math.abs(p);
  const whole = Math.floor(p / 100).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
  return (neg ? '-' : '') + 'GH₵ ' + whole + '.' + String(p % 100).padStart(2, '0');
}
function esc(s) { return String(s ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }
const $ = id => document.getElementById(id);
function show(id, on) { $(id).classList.toggle('hide', !on); }
// Only touch the DOM when something changed, so nothing flickers or replays.
function put(id, html) { const el = $(id); if (el._html !== html) { el._html = html; el.innerHTML = html; return true; } return false; }
function clock() {
  const d = new Date(), h = d.getHours();
  return ((h + 11) % 12 + 1) + ':' + String(d.getMinutes()).padStart(2, '0') + ' ' + (h < 12 ? 'am' : 'pm');
}
// After two missed checks in a row, say so quietly; the page keeps trying.
let misses = 0;
function reached(ok) { misses = ok ? 0 : misses + 1; const el = $('lost'); if (el) el.classList.toggle('hide', misses < 2); }
''';

/// The customer-facing display (SEL-12).
const customerPage =
    '<!doctype html><html lang="en" class="light"><head><title>Aby</title>$_head'
    r'''
<style>
  body { overflow:hidden; }
  .stage { position:fixed; inset:0; display:flex; }
  .stage.in { animation:fade .2s var(--ease); }
  @keyframes fade { from { opacity:0; } to { opacity:1; } }

  /* Idle: a midnight welcome panel. */
  #idle { background:var(--midnight); color:var(--on-midnight); flex-direction:column; padding:4vh 5vw; }
  #idle .top { display:flex; justify-content:space-between; align-items:center; }
  #idle .middle { flex:1; display:flex; flex-direction:column; align-items:center; justify-content:center; text-align:center; gap:2.5rem; }
  #logoCard { background:var(--on-midnight); border-radius:var(--r-lg); padding:1.25rem; }
  #logo { display:block; max-width:28vw; max-height:22vh; }
  .welcome { color:var(--on-midnight-muted); }
  #shop { font-size:4.5rem; line-height:1; font-weight:900; letter-spacing:-.035em; margin-top:.75rem; max-width:80vw; overflow-wrap:anywhere; }
  #promoBox { display:flex; flex-direction:column; align-items:center; gap:.75rem; min-height:6rem; }
  #promoBox .label { display:flex; align-items:center; gap:.5rem; color:var(--on-midnight-muted); }
  #promo { font-size:2.25rem; line-height:1.2; font-weight:800; color:var(--lime); letter-spacing:-.01em; max-width:70vw; transition:opacity .2s var(--ease); }
  #promo.out { opacity:0; }
  .clock { font-size:1.25rem; font-weight:700; color:var(--on-midnight-muted); }
  #idle .powered { color:var(--on-midnight-muted); align-self:center; }
  #idle .powered .mark { width:1.25rem; height:1.25rem; color:var(--on-midnight); }

  /* Cart: the lines on chalk, the total on a midnight bar. */
  #cart { display:grid; grid-template-columns:minmax(0, 1fr) minmax(20rem, 38%); }
  .order { display:flex; flex-direction:column; min-height:0; padding:4vh 3vw 0 4vw; }
  .order h1 { display:flex; align-items:center; gap:.75rem; font-size:2rem; line-height:1.1; font-weight:800; letter-spacing:-.02em; margin-bottom:1.25rem; }
  .count { background:var(--lime); color:var(--on-lime); font-size:1rem; font-weight:800; min-width:2rem; height:2rem; padding:0 .6rem;
    border-radius:999px; display:inline-flex; align-items:center; justify-content:center; }
  #lines { flex:1; overflow-y:auto; scrollbar-width:none; padding-bottom:4vh;
    mask-image:linear-gradient(to bottom, #000 calc(100% - 4vh), transparent); }
  #lines::-webkit-scrollbar { display:none; }
  .line { display:grid; grid-template-columns:auto 1fr auto; gap:1rem; align-items:start; background:var(--raised); box-shadow:var(--shadow-sm);
    border-radius:var(--r-md); padding:1rem 1.25rem; margin-bottom:.75rem; font-size:1.375rem; line-height:1.3; }
  .line.new { animation:slide .2s var(--ease); }
  @keyframes slide { from { opacity:0; transform:translateY(.75rem); } to { opacity:1; transform:none; } }
  .qty { background:var(--sunken); border-radius:var(--r-sm); min-width:2.25rem; padding:.15rem .5rem; text-align:center; font-weight:800; }
  .what b { font-weight:600; display:block; }
  .what small { display:block; font-size:1rem; color:var(--muted); margin-top:.15rem; }
  .deal { display:inline-flex; align-items:center; gap:.35rem; margin-top:.5rem; background:var(--lime-soft); color:var(--lime-ink);
    font-size:.9rem; font-weight:700; padding:.25rem .65rem; border-radius:999px; }
  .line .money { font-weight:800; }
  .empty { color:var(--muted); font-size:1.25rem; padding:2rem 0; }

  .bar { background:var(--midnight); color:var(--on-midnight); display:flex; flex-direction:column; padding:4vh 3vw; gap:1.5rem; min-height:0; }
  .bar .shopline { display:flex; align-items:center; gap:.6rem; font-weight:700; color:var(--on-midnight-muted); }
  .bar .shopline .mark { width:1.75rem; height:1.75rem; color:var(--on-midnight); }
  .totalbox { margin-top:auto; }
  .totalbox .label { color:var(--on-midnight-muted); }
  #total { display:block; font-size:4.25rem; line-height:1.05; font-weight:900; letter-spacing:-.03em; margin-top:.4rem; overflow-wrap:anywhere; }
  #saved { margin-top:.75rem; color:var(--lime); font-weight:700; font-size:1.125rem; }
  #pay { background:var(--midnight-raised); border:1px solid var(--midnight-line); border-radius:var(--r-lg); padding:1.5rem;
    display:flex; flex-direction:column; align-items:center; gap:1rem; text-align:center; animation:slide .2s var(--ease); }
  #qr { background:#fff; border-radius:var(--r-md); padding:.75rem; width:min(16rem, 30vh); aspect-ratio:1; }
  #qr svg { display:block; width:100%; height:100%; }
  #pay .how { display:flex; align-items:center; gap:.5rem; color:var(--on-midnight-muted); }
  #payName { font-size:1.25rem; font-weight:700; }
  #payNumber { font-size:2rem; font-weight:700; letter-spacing:.02em; white-space:nowrap; }
  .bar .powered { color:var(--on-midnight-muted); }
  .bar .powered .mark { width:1.25rem; height:1.25rem; color:var(--on-midnight); }

  /* Done: thank you, change and the order number. */
  #done { background:var(--midnight); color:var(--on-midnight); flex-direction:column; align-items:center; justify-content:center; text-align:center;
    gap:1.5rem; padding:4vh 5vw; }
  .check { width:7rem; height:7rem; }
  .check circle { fill:var(--lime); }
  .check path { fill:none; stroke:var(--on-lime); stroke-width:3; stroke-linecap:round; stroke-linejoin:round;
    stroke-dasharray:30; stroke-dashoffset:0; animation:draw .3s var(--ease) .1s backwards; }
  @keyframes draw { from { stroke-dashoffset:30; } }
  #done h1 { font-size:3rem; line-height:1; font-weight:900; letter-spacing:-.03em; }
  #changeLabel { color:var(--on-midnight-muted); margin-top:.5rem; }
  #change { font-size:5.5rem; line-height:1; font-weight:900; letter-spacing:-.03em; }
  #paid { font-size:1.75rem; font-weight:700; color:var(--on-midnight-muted); }
  #orderCard { background:var(--on-midnight); color:var(--ink); border-radius:var(--r-lg); padding:1.5rem 3rem 1.75rem; margin-top:1rem; }
  #orderCard .label { color:#5a5e6b; }
  #order { font-size:4.5rem; line-height:1; font-weight:900; letter-spacing:-.03em; margin-top:.5rem; color:#101322; }
  #orderCard p { color:#5a5e6b; font-size:1rem; margin-top:.75rem; }

  @media (max-aspect-ratio: 1/1) {
    #cart { grid-template-columns:1fr; grid-template-rows:minmax(0, 1fr) auto; }
    .bar { padding:3vh 5vw; }
    .bar .shopline, .bar .powered { display:none; }
    .order { padding:4vh 5vw 0; }
    #pay { flex-direction:row; text-align:left; }
    #qr { width:min(12rem, 40vw); }
    #payNumber { font-size:1.5rem; }
  }
</style></head><body>
<section id="idle" class="stage">
  <div class="top"><span></span><span class="clock" id="clock1"></span></div>
  <div class="middle">
    <div id="logoCard" class="hide"><img id="logo" alt=""></div>
    <div><div class="label welcome">Welcome to</div><div id="shop"></div></div>
    <div id="promoBox" class="hide"><div class="label">'''
    '$_iconTag'
    r''' Today</div><div id="promo"></div></div>
  </div>
  <div class="powered">'''
    '$_mark'
    r'''Powered by Aby</div>
</section>
<section id="cart" class="stage hide">
  <div class="order">
    <h1>Your order <span class="count num" id="count"></span></h1>
    <div id="lines"></div>
  </div>
  <aside class="bar">
    <div class="shopline">'''
    '$_mark'
    r'''<span id="shop2"></span></div>
    <div id="pay" class="hide">
      <div id="qr"></div>
      <div>
        <div class="how label">'''
    '$_iconSmartphone'
    r''' Pay by MoMo</div>
        <div id="payName"></div>
        <div id="payNumber" class="mono"></div>
      </div>
    </div>
    <div class="totalbox">
      <div class="label" id="totalLabel">Total</div>
      <span id="total" class="money"></span>
      <div id="saved" class="hide"></div>
    </div>
    <div class="powered">'''
    '$_mark'
    r'''Powered by Aby</div>
  </aside>
</section>
<section id="done" class="stage hide">
  <svg class="check" viewBox="0 0 48 48" aria-hidden="true"><circle cx="24" cy="24" r="24"/><path d="M14 24.5l6.5 6.5L34 17.5"/></svg>
  <h1>Thank you</h1>
  <div id="changeBox"><div class="label" id="changeLabel">Your change</div><div id="change" class="money"></div></div>
  <div id="paid" class="money"></div>
  <div id="orderCard" class="hide"><div class="label">Your order number</div><div id="order" class="num"></div><p>Keep this number to collect your order.</p></div>
</section>
<script>'''
    '$_js'
    r'''
let stage = '', promos = [], promoAt = 0, lineCount = 0;
function setStage(s) {
  const id = s === 'paying' ? 'cart' : s;
  for (const k of ['idle', 'cart', 'done']) {
    const el = $(k), on = k === id;
    if (on && el.classList.contains('hide')) { el.classList.remove('in'); void el.offsetWidth; el.classList.add('in'); }
    el.classList.toggle('hide', !on);
  }
  // The check draws once each time a sale completes.
  if (s === 'done' && stage !== 'done') { const c = $('done').querySelector('.check'); const n = c.cloneNode(true); c.replaceWith(n); }
  stage = s;
}
function setPromo(text) {
  const el = $('promo');
  if (el.textContent === text) return;
  el.classList.add('out');
  setTimeout(() => { el.textContent = text; el.classList.remove('out'); }, 200);
}
setInterval(() => { if (promos.length > 1) { promoAt = (promoAt + 1) % promos.length; setPromo(promos[promoAt]); } }, 6000);
setInterval(() => { $('clock1').textContent = clock(); }, 1000);
async function tick() {
  try {
    const s = await (await fetch(location.pathname + '/state', {cache:'no-store'})).json();
    setStage(s.stage);
    $('shop').textContent = s.shop || 'our shop';
    $('shop2').textContent = s.shop || '';
    if (s.logo && $('logo').getAttribute('src') !== s.logo) $('logo').src = s.logo;
    show('logoCard', !!s.logo);
    promos = s.promotions || [];
    show('promoBox', promos.length > 0);
    if (promos.length) { promoAt = Math.min(promoAt, promos.length - 1); if (!$('promo').textContent || !promos.includes($('promo').textContent)) setPromo(promos[promoAt]); }
    if (s.lines) {
      const html = s.lines.map((l, i) =>
        '<div class="line' + (i >= lineCount && lineCount > 0 ? ' new' : '') + '"><span class="qty num">' + esc(l.quantity) + '</span>' +
        '<div class="what"><b>' + esc(l.title) + '</b>' + (l.options ? '<small>+ ' + esc(l.options) + '</small>' : '') +
        (l.deal ? '<span class="deal">'''
    '$_iconTag'
    r'''' + esc(l.deal) + '</span>' : '') + '</div>' +
        '<div class="money">' + money(l.amount) + '</div></div>').join('') || '<div class="empty">Your items show here.</div>';
      if (put('lines', html) && s.lines.length > lineCount) $('lines').scrollTop = $('lines').scrollHeight;
      lineCount = s.lines.length;
      $('count').textContent = s.lines.length;
      show('count', s.lines.length > 0);
      $('total').textContent = money(s.stage === 'paying' && s.due != null ? s.due : s.total);
      $('totalLabel').textContent = s.stage === 'paying' ? 'To pay' : 'Total';
      show('saved', s.discount > 0);
      $('saved').textContent = s.discount > 0 ? 'You save ' + money(s.discount) : '';
    } else { lineCount = 0; }
    const momo = s.stage === 'paying' && !!s.payToNumber;
    show('pay', momo);
    if (momo) {
      put('qr', s.qr || '');
      $('payName').textContent = s.payToName || '';
      $('payNumber').textContent = s.payToNumber;
    }
    if (s.stage === 'done') {
      show('changeBox', s.change > 0);
      $('change').textContent = s.change > 0 ? money(s.change) : '';
      $('paid').textContent = s.change > 0 ? money(s.paid) + ' paid' : money(s.paid) + ' paid. All settled.';
      show('orderCard', !!s.order);
      $('order').textContent = s.order || '';
    }
  } catch (e) {}
}
tick(); setInterval(tick, 800);
</script></body></html>''';

/// The prep screen (SEL-11): New, Preparing, Ready, with buttons.
const prepPage =
    '<!doctype html><html lang="en"><head><title>Orders</title>$_head'
    r'''
<style>
  html { font-size:clamp(14px, 1.8vmin, 24px); }
  body { display:flex; flex-direction:column; height:100vh; overflow:hidden; }
  .appbar { display:flex; align-items:center; gap:.75rem; padding:1rem 1.5rem; border-bottom:1px solid var(--line); background:var(--raised); }
  .appbar .mark { width:2rem; height:2rem; color:var(--ink); }
  .appbar h1 { font-size:1.5rem; font-weight:800; letter-spacing:-.02em; }
  .appbar .shop { color:var(--muted); font-weight:600; }
  .appbar .clock { margin-left:auto; font-size:1.25rem; font-weight:700; }
  main { flex:1; min-height:0; display:grid; grid-template-columns:repeat(3, minmax(0, 1fr)); }
  section { display:flex; flex-direction:column; min-height:0; border-right:1px solid var(--line); }
  section:last-child { border-right:0; background:var(--sunken); }
  section h2 { display:flex; align-items:center; gap:.5rem; padding:1.25rem 1.5rem .75rem; font-size:1.25rem; font-weight:700; }
  section h2 .icon { color:var(--muted); }
  #h-ready .icon { color:var(--lime-ink); }
  .tally { margin-left:auto; min-width:2rem; height:2rem; padding:0 .6rem; border-radius:999px; background:var(--sunken); color:var(--ink);
    display:inline-flex; align-items:center; justify-content:center; font-size:1rem; font-weight:800; }
  section:last-child .tally { background:var(--raised); }
  #h-fresh .tally.some { background:var(--lime); color:var(--on-lime); }
  .col { flex:1; overflow-y:auto; padding:.25rem 1.5rem 1.5rem; display:flex; flex-direction:column; gap:.75rem; }
  .card { background:var(--raised); border:1px solid var(--line); border-radius:var(--r-lg); padding:1.25rem; box-shadow:var(--shadow-sm); }
  .card.enter { animation:enter .2s var(--ease); }
  @keyframes enter { from { opacity:0; transform:translateY(.75rem) scale(.98); } to { opacity:1; transform:none; } }
  .card.ready { border-color:transparent; background:var(--lime-soft); }
  .card .head { display:flex; align-items:center; gap:.6rem; }
  .card .num { font-size:2.25rem; line-height:1; font-weight:900; letter-spacing:-.03em; }
  .age { margin-left:auto; display:inline-flex; align-items:center; gap:.35rem; font-size:.95rem; font-weight:700; color:var(--muted);
    padding:.3rem .65rem; border-radius:999px; }
  .age.slow { background:var(--warning-soft); color:var(--warning); }
  .age.late { background:var(--danger-soft); color:var(--danger); }
  .who { margin-top:.35rem; color:var(--muted); font-weight:600; }
  ul { list-style:none; margin-top:1rem; display:flex; flex-direction:column; gap:.6rem; }
  li { display:grid; grid-template-columns:auto 1fr; gap:.75rem; align-items:start; font-size:1.125rem; line-height:1.3; }
  .qty { background:var(--sunken); border-radius:var(--r-sm); min-width:2rem; padding:.1rem .45rem; text-align:center; font-weight:800; }
  .card.ready .qty { background:var(--raised); }
  li b { font-weight:600; }
  li small { display:block; color:var(--muted); font-size:.95rem; margin-top:.1rem; }
  li small.lnote { color:var(--warning); font-weight:600; }
  .note { display:flex; gap:.5rem; align-items:flex-start; margin-top:1rem; background:var(--warning-soft); color:var(--warning);
    border-radius:var(--r-md); padding:.65rem .85rem; font-weight:600; }
  .note .icon { margin-top:.1em; }
  button { font:inherit; width:100%; min-height:max(56px, 3rem); margin-top:1.25rem; border:0; border-radius:var(--r-md); font-size:1.125rem; font-weight:700;
    cursor:pointer; display:flex; align-items:center; justify-content:center; gap:.5rem; transition:transform .1s var(--ease), opacity .15s; }
  button:active { transform:scale(.98); }
  button:disabled { opacity:.5; }
  button:focus-visible { outline:3px solid var(--blue); outline-offset:3px; }
  .go { background:var(--primary); color:var(--on-primary); }
  .quiet { background:var(--raised); color:var(--ink); border:1px solid var(--line); }
  .none { border:2px dashed var(--line); border-radius:var(--r-lg); padding:1.75rem 1.25rem; text-align:center; color:var(--muted); }
  .none b { display:block; color:var(--ink); font-size:1.125rem; margin-bottom:.25rem; }
  @media (max-width: 760px) {
    .appbar .shop { display:none; }
    main { grid-template-columns:repeat(3, 88vw); overflow-x:auto; scroll-snap-type:x mandatory; }
    section { scroll-snap-align:start; }
  }
</style></head><body>
<header class="appbar">'''
    '$_mark'
    r'''<h1>Orders</h1><span class="shop">{{shop}}</span><span class="clock" id="clock"></span></header>
<main>
  <section><h2 id="h-fresh">'''
    '$_iconBell'
    r'''New<span class="tally num"></span></h2><div class="col" id="fresh"></div></section>
  <section><h2 id="h-preparing">'''
    '$_iconClock'
    r'''Preparing<span class="tally num"></span></h2><div class="col" id="preparing"></div></section>
  <section><h2 id="h-ready">'''
    '$_iconCheck'
    r'''Ready<span class="tally num"></span></h2><div class="col" id="ready"></div></section>
</main>
<div class="lost hide" id="lost">'''
    '$_iconAlert'
    r''' Can't reach the till. Trying again…</div>
<script>'''
    '$_js'
    r'''
const next = { fresh: ['preparing', 'Start', 'go'], preparing: ['ready', 'Ready', 'go'], ready: ['collected', 'Collected', 'quiet'] };
const empty = { fresh: ['No new orders', 'New orders show here as they come in.'], preparing: ['Nothing in the works', 'Tap Start on a new order.'],
  ready: ['Nothing waiting', 'Ready orders wait here until collected.'] };
const seen = new Set(); let first = true;
document.addEventListener('click', async e => {
  const b = e.target.closest('button[data-id]'); if (!b) return;
  b.disabled = true;
  try { await fetch(location.pathname + '/orders/' + encodeURIComponent(b.dataset.id) + '/' + b.dataset.to, { method: 'POST' }); }
  catch (err) { b.disabled = false; }
  tick();
});
function card(o, col) {
  const mins = Math.max(0, Math.floor((Date.now() - o.at) / 60000));
  const pace = col === 'ready' ? '' : mins >= 20 ? ' late' : mins >= 10 ? ' slow' : '';
  const key = col + ':' + o.id, fresh = !first && !seen.has(key); seen.add(key);
  return '<article class="card' + (col === 'ready' ? ' ready' : '') + (fresh ? ' enter' : '') + '"><div class="head">' +
    (col === 'fresh' ? '<span class="dot pulse" aria-hidden="true"></span>' : '') +
    '<span class="num">' + esc(o.number) + '</span><span class="age' + pace + '">'''
    '$_iconClock'
    r'''' + (mins < 1 ? 'Just now' : mins + ' min') + (pace === ' late' ? ' · late' : '') + '</span></div>' +
    (o.customer ? '<div class="who">' + esc(o.customer) + '</div>' : '') +
    '<ul>' + o.lines.map(l => '<li><span class="qty num">' + esc(l.quantity) + '</span><div><b>' + esc(l.title) + '</b>' +
      (l.options ? '<small>+ ' + esc(l.options) + '</small>' : '') +
      (l.note ? '<small class="lnote">“' + esc(l.note) + '”</small>' : '') + '</div></li>').join('') + '</ul>' +
    (o.note ? '<div class="note">'''
    '$_iconAlert'
    r'''<span>' + esc(o.note) + '</span></div>' : '') +
    '<button class="' + next[col][2] + '" data-id="' + esc(o.id) + '" data-to="' + next[col][0] + '">' + next[col][1] + '</button></article>';
}
async function tick() {
  $('clock').textContent = clock();
  try {
    const orders = await (await fetch(location.pathname + '/orders', {cache:'no-store'})).json();
    reached(true);
    for (const col of ['fresh', 'preparing', 'ready']) {
      const mine = orders.filter(o => o.status === col);
      put(col, mine.map(o => card(o, col)).join('') || '<div class="none"><b>' + empty[col][0] + '</b>' + empty[col][1] + '</div>');
      const t = $('h-' + col).querySelector('.tally');
      t.textContent = mine.length; t.classList.toggle('some', mine.length > 0);
    }
    first = false;
  } catch (e) { reached(false); }
}
tick(); setInterval(tick, 1500);
</script></body></html>''';

/// "Now serving": order numbers being prepared and ready to collect.
const servingPage =
    '<!doctype html><html lang="en" class="light"><head><title>Now serving</title>$_head'
    r'''
<style>
  body { overflow:hidden; }
  main { display:grid; grid-template-columns:minmax(0, 1fr) minmax(0, 1.5fr); height:100vh; }
  section { display:flex; flex-direction:column; min-height:0; padding:5vh 3.5vw; }
  .top { display:flex; align-items:center; gap:.75rem; min-height:2.75rem; margin-bottom:4vh; }
  .top .mark { width:2.5rem; height:2.5rem; }
  .shop { font-size:1.5rem; font-weight:800; letter-spacing:-.02em; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
  h2 { display:flex; align-items:center; gap:.6rem; font-size:2.25rem; line-height:1.1; font-weight:900; letter-spacing:-.03em; margin-bottom:3vh; }
  .grid { flex:1; min-height:0; overflow:hidden; display:grid; align-content:start; gap:1rem; }
  #preparing { grid-template-columns:repeat(auto-fill, minmax(8rem, 1fr)); }
  #preparing .tile { background:var(--raised); border:1px solid var(--line); border-radius:var(--r-lg); padding:1.25rem .75rem; text-align:center;
    font-size:2.75rem; line-height:1; font-weight:800; color:var(--muted); letter-spacing:-.02em; }
  .left .powered { color:var(--muted); margin-top:auto; padding-top:2vh; }
  .left .powered .mark { width:1.25rem; height:1.25rem; color:var(--ink); }

  .right { background:var(--midnight); color:var(--on-midnight); }
  .right .top { justify-content:flex-end; }
  .clock { font-size:1.5rem; font-weight:700; color:var(--on-midnight-muted); }
  .right h2 .icon { color:var(--lime); }
  .lede { color:var(--on-midnight-muted); font-size:1.125rem; margin:-2vh 0 3vh; }
  #ready { grid-template-columns:repeat(auto-fill, minmax(14rem, 1fr)); gap:1.25rem; }
  #ready .tile { position:relative; background:var(--midnight-raised); border:2px solid var(--midnight-line); border-radius:var(--r-lg);
    padding:2rem 2rem; text-align:center; font-size:4.5rem; line-height:1; font-weight:900; letter-spacing:-.035em; }
  #ready .tile .dot { position:absolute; top:.85rem; right:.85rem; width:14px; height:14px; }
  #ready .tile.fresh { border-color:var(--lime); animation:pop .25s var(--ease); }
  @keyframes pop { from { opacity:0; transform:scale(.9); } to { opacity:1; transform:none; } }
  .none { color:var(--on-midnight-muted); font-size:1.5rem; font-weight:600; max-width:22ch; line-height:1.35; }
  .left .none { color:var(--muted); font-size:1.25rem; }

  @media (max-aspect-ratio: 1/1) {
    main { grid-template-columns:1fr; grid-template-rows:1.6fr 1fr; }
    .right { order:-1; }
    .right .top { justify-content:space-between; }
    .left .top { display:none; }
  }
</style></head><body><main>
  <section class="left">
    <div class="top">'''
    '$_mark'
    r'''<span class="shop">{{shop}}</span></div>
    <h2>Preparing</h2>
    <div class="grid" id="preparing"></div>
    <div class="powered">'''
    '$_mark'
    r'''Powered by Aby</div>
  </section>
  <section class="right">
    <div class="top"><span class="clock" id="clock"></span></div>
    <h2>'''
    '$_iconCheck'
    r'''Ready to collect</h2>
    <p class="lede">Show your receipt at the counter.</p>
    <div class="grid" id="ready"></div>
  </section>
</main>
<div class="lost hide" id="lost">'''
    '$_iconAlert'
    r''' Can't reach the till. Trying again…</div>
<script>'''
    '$_js'
    r'''
// Numbers that turned ready in the last minute get a lime ring and a pulsing dot.
const readyAt = new Map(); let first = true;
async function tick() {
  $('clock').textContent = clock();
  try {
    const orders = await (await fetch(location.pathname + '/orders', {cache:'no-store'})).json();
    reached(true);
    const now = Date.now(), ready = orders.filter(o => o.status === 'ready'), making = orders.filter(o => o.status !== 'ready');
    for (const o of ready) if (!readyAt.has(o.id)) readyAt.set(o.id, first ? 0 : now);
    for (const id of [...readyAt.keys()]) if (!ready.some(o => o.id === id)) readyAt.delete(id);
    first = false;
    // Newest ready first, so a fresh number is never pushed off the screen.
    ready.sort((a, b) => readyAt.get(b.id) - readyAt.get(a.id));
    put('ready', ready.map(o => {
      const fresh = now - readyAt.get(o.id) < 60000;
      return '<div class="tile num' + (fresh ? ' fresh' : '') + '"><span class="dot' + (fresh ? ' pulse' : '') + '"></span>' + esc(o.number) + '</div>';
    }).join('') || '<p class="none">Your number shows here when it\'s ready.</p>');
    put('preparing', making.map(o => '<div class="tile num">' + esc(o.number) + '</div>').join('') || '<p class="none">No orders being made right now.</p>');
  } catch (e) { reached(false); }
}
tick(); setInterval(tick, 2000);
</script></body></html>''';
