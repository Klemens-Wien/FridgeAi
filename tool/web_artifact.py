"""Packages build/web as a claude.ai artifact page (inline scripts, files beside it).

Usage: flutter build web --release --no-web-resources-cdn --no-source-maps
       python3 tool/web_artifact.py build/web <out-dir>
"""
import os, shutil, sys
src, out = sys.argv[1], sys.argv[2]
shutil.rmtree(out, ignore_errors=True)
os.makedirs(out)
main_js = open(f'{src}/main.dart.js').read()
ck_js = open(f'{src}/canvaskit/canvaskit.js').read()
assert 'export default CanvasKitInit;' in ck_js
ck_js = ck_js.replace('export default CanvasKitInit;', '')
for js in (main_js, ck_js):
    assert '</script' not in js and '<!--' not in js

page = '''<title>FridgeChef</title>
<style>
:root { --bg: #f6faf3; --fg: #1a1c19; --muted: #5d6459; --accent: #2e7d32; }
@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) { --bg: #10140f; --fg: #e0e4dc; --muted: #a3ab9e; --accent: #81c784; color-scheme: dark; } }
:root[data-theme="dark"] { --bg: #10140f; --fg: #e0e4dc; --muted: #a3ab9e; --accent: #81c784; color-scheme: dark; }
html, body { height: 100%; }
body { background: var(--bg); color: var(--fg); overflow: hidden; }
#app { position: relative; width: 100%; height: 100%; }
#loading { position: absolute; inset: 0; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 12px; font: 15px/1.4 system-ui, sans-serif; color: var(--muted); padding-inline: 16px; text-align: center; }
#loading b { font-size: 22px; color: var(--accent); }
#loading[data-error] { color: var(--fg); }
</style>
<div id="app"><div id="loading"><b>FridgeChef</b><span id="loading-text">Wird geladen …</span></div></div>
<script>
(function () {
  var init = null, ckReady = false, started = false;
  function fail(e) {
    console.error(e);
    var l = document.getElementById('loading');
    if (l) { l.setAttribute('data-error', ''); document.getElementById('loading-text').textContent = 'Die App konnte nicht starten: ' + (e && e.message || e); }
  }
  window.__fridgeStart = async function () {
    if (started || !init || !ckReady) return;
    started = true;
    try {
      var runner = await init.initializeEngine({ hostElement: document.getElementById('app'), canvasKitVariant: 'full' });
      await runner.runApp();
      var l = document.getElementById('loading'); if (l) l.remove();
    } catch (e) { fail(e); }
  };
  window.__fridgeCanvasKitReady = function () { ckReady = true; window.__fridgeStart(); };
  window.__fridgeFail = fail;
  window._flutter = { loader: { didCreateEngineInitializer: function (i) { init = i; window.__fridgeStart(); } } };
})();
</script>
<script>
''' + main_js + '''
</script>
<script type="module">
''' + ck_js + '''
var wasmUrl = new URL('canvaskit/canvaskit.wasm', document.baseURI).href;
window.flutterCanvasKitLoaded = CanvasKitInit({
  instantiateWasm: function (imports, done) {
    fetch(wasmUrl)
      .then(function (r) { if (!r.ok) throw new Error('canvaskit.wasm: HTTP ' + r.status); return r.arrayBuffer(); })
      .then(function (buf) { return WebAssembly.instantiate(buf, imports); })
      .then(function (res) { done(res.instance, res.module); }, window.__fridgeFail);
    return {};
  }
})
  .then(function (ck) { window.flutterCanvasKit = ck; return ck; });
window.flutterCanvasKitLoaded.then(function () { window.__fridgeCanvasKitReady(); }, window.__fridgeFail);
</script>
'''
open(f'{out}/fridgechef.html', 'w').write(page)
os.makedirs(f'{out}/canvaskit')
shutil.copy(f'{src}/canvaskit/canvaskit.wasm', f'{out}/canvaskit/canvaskit.wasm')
shutil.copytree(f'{src}/assets', f'{out}/assets')
print(os.path.getsize(f'{out}/fridgechef.html'))
