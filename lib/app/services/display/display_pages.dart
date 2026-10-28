// The pages the till serves to tablets, TVs and second monitors. Plain
// HTML and JavaScript, no internet needed: each page asks the till for its
// state every second.

const _style = r'''
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<style>
  :root { --ink:#101322; --muted:#5a5e6b; --bg:#f6f4ef; --card:#fff; --brand:#1f4fd8; --ok:#14804a; --warn:#b4570b; }
  * { box-sizing:border-box; margin:0; padding:0; }
  body { font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; background:var(--bg); color:var(--ink); min-height:100vh; }
  .money { font-variant-numeric: tabular-nums; }
  .muted { color:var(--muted); }
  .hide { display:none !important; }
</style>
''';

const _money = r'''
function money(p) {
  const neg = p < 0; p = Math.abs(p);
  const whole = Math.floor(p / 100).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
  return (neg ? '-' : '') + 'GH₵ ' + whole + '.' + String(p % 100).padStart(2, '0');
}
function esc(s) { return String(s ?? '').replace(/[&<>"]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c])); }
''';

/// The customer-facing display (SEL-12).
const customerPage = '''<!doctype html><html><head><title>Aby</title>$_style
<style>
  main { display:flex; flex-direction:column; min-height:100vh; padding:4vh 4vw; }
  #idle { flex:1; display:flex; flex-direction:column; align-items:center; justify-content:center; text-align:center; gap:4vh; }
  #idle img { max-width:40vw; max-height:30vh; }
  #shop { font-size:7vh; font-weight:900; }
  #promo { font-size:4.5vh; color:var(--brand); font-weight:700; min-height:6vh; }
  #cart { flex:1; display:flex; flex-direction:column; }
  #lines { flex:1; font-size:3.4vh; }
  .line { display:flex; justify-content:space-between; gap:2vw; padding:1.2vh 0; border-bottom:1px solid #e3e0d8; }
  .line small { display:block; font-size:2.4vh; color:var(--muted); }
  .deal { color:var(--ok); font-size:2.4vh; font-weight:700; }
  #totals { font-size:6vh; font-weight:900; display:flex; justify-content:space-between; padding-top:2vh; }
  #pay { display:flex; gap:4vw; align-items:center; margin-top:3vh; background:var(--card); border-radius:2vh; padding:3vh; }
  #pay svg { width:28vh; height:28vh; }
  #payto { font-size:3.4vh; } #payto b { display:block; font-size:6vh; }
  #done { flex:1; display:flex; flex-direction:column; align-items:center; justify-content:center; gap:3vh; text-align:center; }
  #done h1 { font-size:9vh; } #change { font-size:6vh; font-weight:900; } #order { font-size:12vh; font-weight:900; color:var(--brand); }
</style></head><body><main>
  <section id="idle"><img id="logo" class="hide" alt=""><div id="shop"></div><div id="promo"></div></section>
  <section id="cart" class="hide">
    <div id="lines"></div>
    <div id="totals"><span>Total</span><span id="total" class="money"></span></div>
    <div id="pay" class="hide"><div id="qr"></div><div id="payto"></div></div>
  </section>
  <section id="done" class="hide"><h1>Thank you!</h1><div id="change" class="money"></div><div id="ordertitle" class="muted"></div><div id="order"></div></section>
</main><script>
$_money
let promos = [], promoAt = 0;
setInterval(() => { if (promos.length) { promoAt = (promoAt + 1) % promos.length; document.getElementById('promo').textContent = promos[promoAt]; } }, 5000);
async function tick() {
  try {
    const s = await (await fetch(location.pathname + '/state', {cache:'no-store'})).json();
    const show = (id, on) => document.getElementById(id).classList.toggle('hide', !on);
    show('idle', s.stage === 'idle'); show('cart', s.stage === 'cart' || s.stage === 'paying'); show('done', s.stage === 'done');
    document.getElementById('shop').textContent = s.shop;
    const logo = document.getElementById('logo'); if (s.logo) { logo.src = s.logo; logo.classList.remove('hide'); }
    promos = s.promotions || []; if (!promos.length) document.getElementById('promo').textContent = '';
    else if (!document.getElementById('promo').textContent) document.getElementById('promo').textContent = promos[0];
    if (s.lines) {
      document.getElementById('lines').innerHTML = s.lines.map(l =>
        '<div class="line"><div>' + esc(l.quantity) + ' × ' + esc(l.title) + (l.options ? '<small>+ ' + esc(l.options) + '</small>' : '') +
        (l.deal ? '<div class="deal">' + esc(l.deal) + '</div>' : '') + '</div><div class="money">' + money(l.amount) + '</div></div>').join('');
      document.getElementById('total').textContent = money(s.total);
    }
    show('pay', s.stage === 'paying' && !!s.payToNumber);
    if (s.stage === 'paying' && s.payToNumber) {
      document.getElementById('qr').innerHTML = s.qr || '';
      document.getElementById('payto').innerHTML = 'Pay ' + money(s.due) + ' to ' + esc(s.payToName) + '<b>' + esc(s.payToNumber) + '</b>';
    }
    if (s.stage === 'done') {
      document.getElementById('change').textContent = s.change > 0 ? 'Your change: ' + money(s.change) : money(s.paid) + ' paid';
      document.getElementById('ordertitle').textContent = s.order ? 'Your order number' : '';
      document.getElementById('order').textContent = s.order || '';
    }
  } catch (e) {}
}
tick(); setInterval(tick, 800);
</script></body></html>''';

/// The prep screen (SEL-11): New, Preparing, Ready, with buttons.
const prepPage = '''<!doctype html><html><head><title>Orders</title>$_style
<style>
  main { display:grid; grid-template-columns:repeat(3, 1fr); gap:1.5vw; padding:1.5vw; min-height:100vh; }
  h2 { font-size:2.6vh; letter-spacing:.08em; color:var(--muted); margin-bottom:1vh; }
  .card { background:var(--card); border-radius:1.5vh; padding:1.6vh; margin-bottom:1.5vh; box-shadow:0 1px 3px #0002; }
  .num { font-size:5vh; font-weight:900; } .age { float:right; color:var(--muted); font-size:2.2vh; }
  .item { font-size:2.8vh; font-weight:700; margin-top:.6vh; } .item small { display:block; font-weight:400; color:var(--muted); }
  .note { color:var(--warn); font-size:2.4vh; }
  button { width:100%; margin-top:1.2vh; font-size:2.6vh; padding:1.4vh; border:0; border-radius:1.2vh; background:var(--brand); color:#fff; font-weight:700; }
</style></head><body><main>
  <section><h2>NEW</h2><div id="fresh"></div></section>
  <section><h2>PREPARING</h2><div id="preparing"></div></section>
  <section><h2>READY</h2><div id="ready"></div></section>
</main><script>
$_money
const next = { fresh: ['preparing', 'Start'], preparing: ['ready', 'Ready'], ready: ['collected', 'Collected'] };
async function move(id, status) { await fetch(location.pathname + '/orders/' + id + '/' + status, { method: 'POST' }); tick(); }
async function tick() {
  try {
    const orders = await (await fetch(location.pathname + '/orders', {cache:'no-store'})).json();
    for (const col of ['fresh', 'preparing', 'ready']) {
      document.getElementById(col).innerHTML = orders.filter(o => o.status === col).map(o => {
        const mins = Math.max(0, Math.round((Date.now() - o.at) / 60000));
        return '<div class="card"><span class="age">' + mins + ' min</span><div class="num">' + esc(o.number) + '</div>' +
          o.lines.map(l => '<div class="item">' + l.quantity + ' × ' + esc(l.title) + (l.options ? '<small>+ ' + esc(l.options) + '</small>' : '') +
            (l.note ? '<small>“' + esc(l.note) + '”</small>' : '') + '</div>').join('') +
          (o.note ? '<div class="note">' + esc(o.note) + '</div>' : '') +
          '<button onclick="move(\\'' + o.id + '\\', \\'' + next[col][0] + '\\')">' + next[col][1] + '</button></div>';
      }).join('');
    }
  } catch (e) {}
}
tick(); setInterval(tick, 1500);
</script></body></html>''';

/// "Now serving": order numbers being prepared and ready to collect.
const servingPage = '''<!doctype html><html><head><title>Now serving</title>$_style
<style>
  main { display:grid; grid-template-columns:1fr 1.4fr; min-height:100vh; }
  section { padding:4vh 3vw; } section + section { background:var(--brand); color:#fff; }
  h2 { font-size:4.5vh; margin-bottom:3vh; }
  .nums { display:flex; flex-wrap:wrap; gap:2vh 3vw; }
  .nums div { font-size:9vh; font-weight:900; }
  #preparing div { font-size:6vh; color:var(--muted); }
</style></head><body><main>
  <section><h2>Preparing</h2><div class="nums" id="preparing"></div></section>
  <section><h2>Ready to collect</h2><div class="nums" id="ready"></div></section>
</main><script>
$_money
async function tick() {
  try {
    const orders = await (await fetch(location.pathname + '/orders', {cache:'no-store'})).json();
    document.getElementById('preparing').innerHTML = orders.filter(o => o.status !== 'ready').map(o => '<div>' + esc(o.number) + '</div>').join('');
    document.getElementById('ready').innerHTML = orders.filter(o => o.status === 'ready').map(o => '<div>' + esc(o.number) + '</div>').join('');
  } catch (e) {}
}
tick(); setInterval(tick, 2000);
</script></body></html>''';
