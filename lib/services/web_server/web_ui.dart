const String webUiHtml = r'''<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Cope X Studio - Web</title>
<style>
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap');

* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

body {
  font-family: 'Inter', system-ui, -apple-system, sans-serif;
  background-color: #0b0c10;
  background-image: radial-gradient(circle at 50% 0%, #1a2230 0%, #0b0c10 80%);
  color: #adbac7;
  height: 100vh;
  height: 100dvh;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  -webkit-font-smoothing: antialiased;
}

header {
  background: rgba(18, 20, 28, 0.85);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border-bottom: 1px solid rgba(255, 255, 255, 0.06);
  padding: 12px 20px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  z-index: 10;
  flex-shrink: 0;
}

header .brand {
  display: flex;
  align-items: center;
  gap: 10px;
}

header h1 {
  font-size: 16px;
  color: #fff;
  font-weight: 700;
  letter-spacing: -0.3px;
}

.badge-container {
  display: flex;
  align-items: center;
  gap: 12px;
}

.badge {
  background: linear-gradient(135deg, #0e639c, #007acc);
  color: #fff;
  padding: 2px 8px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.3px;
  box-shadow: 0 2px 8px rgba(0, 122, 204, 0.3);
}

.server-status {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 11px;
  color: #4ade80;
  font-weight: 500;
}

.status-dot {
  width: 8px;
  height: 8px;
  background-color: #4ade80;
  border-radius: 50%;
  box-shadow: 0 0 8px #4ade80;
  animation: pulse 1.8s infinite;
}

@keyframes pulse {
  0% { transform: scale(0.9); opacity: 0.6; }
  50% { transform: scale(1.1); opacity: 1; box-shadow: 0 0 12px #4ade80; }
  100% { transform: scale(0.9); opacity: 0.6; }
}

.toolbar-container {
  display: flex;
  flex-direction: column;
  border-bottom: 1px solid rgba(255, 255, 255, 0.05);
  flex-shrink: 0;
}

.toolbar {
  background: rgba(24, 28, 38, 0.7);
  backdrop-filter: blur(8px);
  padding: 8px 16px;
  display: flex;
  gap: 6px;
  align-items: center;
  overflow-x: auto;
  scrollbar-width: none;
  -ms-overflow-style: none;
}

.toolbar::-webkit-scrollbar {
  display: none;
}

.toolbar.top-row {
  border-bottom: 1px solid rgba(255, 255, 255, 0.03);
}

.toolbar.bottom-row {
  background: rgba(18, 21, 28, 0.5);
  padding: 6px 16px;
}

.toolbar .btn {
  flex-shrink: 0;
}

.toolbar .divider {
  width: 1px;
  height: 20px;
  background: rgba(255, 255, 255, 0.1);
  margin: 0 4px;
  flex-shrink: 0;
}

.btn {
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.08);
  color: #cdd9e5;
  padding: 6px 12px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 13px;
  font-weight: 500;
  display: flex;
  align-items: center;
  gap: 6px;
  transition: all 0.15s cubic-bezier(0.4, 0, 0.2, 1);
}

.btn:hover {
  background: rgba(255, 255, 255, 0.1);
  color: #fff;
  border-color: rgba(255, 255, 255, 0.15);
  transform: translateY(-1px);
}

.btn:active {
  transform: translateY(0);
}

.btn.primary {
  background: linear-gradient(135deg, #0e639c, #007acc);
  border: none;
  color: #fff;
  font-weight: 600;
  box-shadow: 0 3px 8px rgba(0, 122, 204, 0.2);
}

.btn.primary:hover {
  background: linear-gradient(135deg, #1177bb, #0088ee);
  box-shadow: 0 3px 12px rgba(0, 122, 204, 0.3);
}

.btn.danger {
  background: rgba(248, 81, 73, 0.12);
  border: 1px solid rgba(248, 81, 73, 0.25);
  color: #f85149;
}

.btn.danger:hover {
  background: rgba(248, 81, 73, 0.22);
  border-color: rgba(248, 81, 73, 0.45);
  color: #ff6b6b;
}

.breadcrumb {
  background: #11141c;
  padding: 8px 20px;
  font-size: 13px;
  color: #768390;
  border-bottom: 1px solid rgba(255, 255, 255, 0.05);
  display: flex;
  align-items: center;
  gap: 6px;
  flex-shrink: 0;
  word-break: break-all;
}

.breadcrumb a {
  color: #58a6ff;
  text-decoration: none;
  cursor: pointer;
  transition: color 0.15s ease;
  font-weight: 500;
}

.breadcrumb a:hover {
  color: #79c0ff;
  text-decoration: underline;
}

main {
  flex: 1;
  overflow-y: auto;
  padding: 16px;
  background: #0d1117;
}

.explorer-card {
  background: rgba(22, 27, 34, 0.6);
  border: 1px solid rgba(255, 255, 255, 0.05);
  border-radius: 10px;
  overflow: hidden;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15);
}

table {
  width: 100%;
  border-collapse: collapse;
  font-size: 14px;
}

th, td {
  padding: 12px 16px;
  text-align: left;
  border-bottom: 1px solid rgba(255, 255, 255, 0.04);
}

th {
  background: rgba(22, 27, 34, 0.95);
  color: #768390;
  font-weight: 600;
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  position: sticky;
  top: 0;
  z-index: 1;
}

tr {
  transition: background-color 0.15s ease;
}

tr:hover td {
  background: rgba(255, 255, 255, 0.02);
}

tr.selected td {
  background: rgba(56, 139, 253, 0.08) !important;
}

.chk {
  width: 17px;
  height: 17px;
  accent-color: #58a6ff;
  cursor: pointer;
}

.name-cell {
  display: flex;
  align-items: center;
  cursor: pointer;
  gap: 10px;
}

.name-cell:hover .fname {
  color: #58a6ff;
}

.fname {
  color: #adbac7;
  font-weight: 500;
  transition: color 0.15s ease;
}

.icon {
  font-size: 18px;
  width: 24px;
  text-align: center;
}

.dim {
  color: #768390;
  font-size: 13px;
}

.explorer-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(130px, 1fr));
  gap: 16px;
  padding: 16px;
}

.grid-item {
  background: rgba(22, 27, 34, 0.4);
  border: 1px solid rgba(255, 255, 255, 0.05);
  border-radius: 8px;
  padding: 16px 12px;
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  position: relative;
  cursor: pointer;
  transition: all 0.15s ease;
  user-select: none;
}

.grid-item:hover {
  background: rgba(255, 255, 255, 0.03);
  border-color: rgba(255, 255, 255, 0.1);
  transform: translateY(-2px);
}

.grid-item.selected {
  background: rgba(56, 139, 253, 0.08) !important;
  border-color: rgba(56, 139, 253, 0.4);
}

.grid-item .chk-container {
  position: absolute;
  top: 8px;
  left: 8px;
  z-index: 2;
}

.grid-item .thumb-container {
  width: 64px;
  height: 64px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 8px;
  flex-shrink: 0;
}

.grid-item .thumb-img {
  max-width: 100%;
  max-height: 100%;
  border-radius: 4px;
  object-fit: cover;
}

.grid-item .fallback-icon-grid {
  font-size: 40px;
}

.grid-item .name-label {
  font-size: 13px;
  color: #adbac7;
  font-weight: 500;
  word-break: break-all;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  text-overflow: ellipsis;
  line-height: 1.4;
  margin-top: 4px;
}

.grid-item .size-label {
  font-size: 11px;
  color: #768390;
  margin-top: 4px;
}

.thumb-container-mini {
  width: 24px;
  height: 24px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  margin-right: 8px;
  flex-shrink: 0;
}

.thumb-img-mini {
  max-width: 100%;
  max-height: 100%;
  border-radius: 2px;
  object-fit: cover;
}

.fallback-icon-mini {
  font-size: 16px;
}

/* Modal styles */
.modal-bg {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.7);
  backdrop-filter: blur(4px);
  display: none;
  align-items: center;
  justify-content: center;
  z-index: 100;
  padding: 16px;
}

.modal-bg.open {
  display: flex;
}

.modal {
  background: #1c2128;
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 10px;
  padding: 20px;
  min-width: 320px;
  max-width: 600px;
  width: 100%;
  max-height: 85vh;
  display: flex;
  flex-direction: column;
  box-shadow: 0 16px 32px rgba(0, 0, 0, 0.35);
}

.modal h2 {
  font-size: 16px;
  margin-bottom: 14px;
  color: #fff;
  font-weight: 600;
}

.modal input, .modal textarea {
  width: 100%;
  background: #22272e;
  border: 1px solid rgba(255, 255, 255, 0.1);
  color: #adbac7;
  padding: 8px 12px;
  border-radius: 6px;
  font-size: 14px;
  margin-bottom: 14px;
  outline: none;
  transition: border-color 0.2s ease;
}

.modal input:focus, .modal textarea:focus {
  border-color: #58a6ff;
}

.modal textarea {
  flex: 1;
  min-height: 250px;
  font-family: 'JetBrains Mono', Consolas, monospace;
  resize: vertical;
}

.modal-actions {
  display: flex;
  gap: 8px;
  justify-content: flex-end;
}

.preview-body {
  text-align: center;
  max-width: 100%;
  max-height: 55vh;
  overflow: auto;
}

.preview-body img, .preview-body video {
  max-width: 100%;
  max-height: 50vh;
  border-radius: 6px;
}

.empty {
  padding: 48px 20px;
  text-align: center;
  color: #768390;
  font-size: 14px;
}

footer {
  background: #1c2128;
  border-top: 1px solid rgba(255, 255, 255, 0.05);
  color: #adbac7;
  padding: 8px 20px;
  font-size: 12px;
  cursor: pointer;
  user-select: none;
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-shrink: 0;
  transition: background-color 0.15s ease;
}

footer:hover {
  background: #22272e;
}

.console-panel {
  background: #0d1117;
  border-top: 1px solid rgba(255, 255, 255, 0.08);
  height: 200px;
  display: none;
  flex-direction: column;
  font-family: 'JetBrains Mono', Consolas, monospace;
  font-size: 12px;
  color: #adbac7;
  flex-shrink: 0;
}

.console-panel.open {
  display: flex;
}

.console-header {
  background: #1c2128;
  border-bottom: 1px solid rgba(255, 255, 255, 0.05);
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 6px 16px;
  flex-shrink: 0;
}

.console-tabs {
  display: flex;
  align-items: center;
  gap: 8px;
}

.console-tabs .active {
  color: #fff;
  font-weight: 600;
  border-bottom: 2px solid #58a6ff;
  padding: 2px 0 6px 0;
}

.console-actions button {
  background: transparent;
  border: none;
  color: #768390;
  cursor: pointer;
  font-size: 13px;
  padding: 4px;
  border-radius: 4px;
  transition: all 0.15s ease;
}

.console-actions button:hover {
  color: #fff;
  background: rgba(255, 255, 255, 0.05);
}

.console-body {
  flex: 1;
  overflow-y: auto;
  padding: 12px 16px;
  line-height: 1.6;
  white-space: pre-wrap;
  word-break: break-all;
}

.log-entry {
  margin-bottom: 4px;
}

.log-time {
  color: #57ab5a;
  margin-right: 10px;
}

.log-error {
  color: #f85149;
}

.log-info {
  color: #58a6ff;
}

.log-success {
  color: #56d364;
}

/* Custom Scrollbar for modern look */
::-webkit-scrollbar {
  width: 6px;
  height: 6px;
}

::-webkit-scrollbar-track {
  background: #0d1117;
}

::-webkit-scrollbar-thumb {
  background: #30363d;
  border-radius: 3px;
}

::-webkit-scrollbar-thumb:hover {
  background: #8b949e;
}
</style>
</head>
<body>
<header>
  <div class="brand">
    <h1>Cope X Studio</h1>
    <span class="badge">Web Server</span>
  </div>
  <div class="badge-container">
    <div class="server-status">
      <div class="status-dot"></div>
      <span>Online</span>
    </div>
  </div>
</header>
<div class="toolbar-container">
  <div class="toolbar top-row">
    <button class="btn" onclick="showRoots()">💾 Ổ đĩa</button>
    <button class="btn" onclick="goUp()">⬆ Lên</button>
    <button class="btn" onclick="refresh()">↻ Làm mới</button>
    <button class="btn" id="viewModeBtn" onclick="toggleViewMode()">田 Lưới</button>
    <button class="btn" id="showHiddenBtn" onclick="toggleShowHidden()">👁️ Hiện file ẩn</button>
    <div class="divider"></div>
    <button class="btn primary" onclick="pickUpload()">⬆ Tải lên</button>
    <button class="btn" onclick="downloadSelected()">⬇ Tải xuống</button>
    <button class="btn" onclick="selectAll()">☑ Chọn tất cả</button>
    <button class="btn" onclick="deselectAll()">☐ Bỏ chọn tất cả</button>
  </div>
  <div class="toolbar bottom-row">
    <button class="btn" onclick="promptNew('folder')">📁 Thư mục mới</button>
    <button class="btn" onclick="promptNew('file')">📄 File mới</button>
    <div class="divider"></div>
    <button class="btn" onclick="zipSelected()">🗜 Nén ZIP</button>
    <button class="btn" onclick="renameSelected()">✏ Đổi tên</button>
    <button class="btn danger" onclick="deleteSelected()">🗑 Xóa</button>
    <input style="display: none;" type="file" id="fileInput" multiple onchange="uploadFiles(this.files)">
  </div>
</div>
<div class="breadcrumb" id="breadcrumb"></div>
<main>
  <div class="explorer-card" id="content">
    <div class="empty">Đang tải...</div>
  </div>
</main>

<div class="console-panel" id="consolePanel">
  <div class="console-header">
    <div class="console-tabs">
      <span class="active">OUTPUT</span>
    </div>
    <div class="console-actions">
      <button onclick="clearConsole()" title="Xóa logs">🗑</button>
      <button onclick="toggleConsole()" title="Đóng panel">❌</button>
    </div>
  </div>
  <div class="console-body" id="consoleBody"></div>
</div>

<footer id="status" onclick="toggleConsole()">
  <span id="statusText">Sẵn sàng</span>
  <span class="dim" style="cursor: pointer;">Console ⬆</span>
</footer>

<div class="modal-bg" id="modalBg" onclick="if(event.target===this)closeModal()">
  <div class="modal" id="modal">
    <h2 id="modalTitle"></h2>
    <div id="modalBody"></div>
    <div class="modal-actions" id="modalActions"></div>
  </div>
</div>

<script>
let rootPath='', currentPath='', entries=[], selected=new Set(), info={}, logs=[], viewMode=localStorage.getItem('viewMode')||'grid', showHidden=localStorage.getItem('showHidden')==='true';

async function api(url,opts={}){
  const r=await fetch(url,opts);
  const j=await r.json().catch(()=>({}));
  if(!r.ok)throw new Error(j.error||r.statusText);
  return j;
}

function setStatus(msg, type='info'){
  document.getElementById('statusText').textContent=msg;
  const time=new Date().toLocaleTimeString();
  logs.push({time,msg,type});
  updateConsole();
}

function updateConsole(){
  const body=document.getElementById('consoleBody');
  if(!body)return;
  body.innerHTML=logs.map(l=>{
    let cls='log-info';
    if(l.type==='error')cls='log-error';
    if(l.type==='success')cls='log-success';
    return `<div class="log-entry"><span class="log-time">[${l.time}]</span><span class="${cls}">${esc(l.msg)}</span></div>`;
  }).join('');
  body.scrollTop=body.scrollHeight;
}

function clearConsole(){
  logs=[];
  updateConsole();
}

function toggleConsole(){
  const panel=document.getElementById('consolePanel');
  panel.classList.toggle('open');
  if(panel.classList.contains('open')){
    const body=document.getElementById('consoleBody');
    if(body)body.scrollTop=body.scrollHeight;
  }
}

function toggleViewMode() {
  viewMode = viewMode === 'list' ? 'grid' : 'list';
  localStorage.setItem('viewMode', viewMode);
  updateViewModeButton();
  render();
}

function updateViewModeButton() {
  const btn = document.getElementById('viewModeBtn');
  if (btn) {
    btn.innerHTML = viewMode === 'list' ? '田 Lưới' : '☰ Danh sách';
  }
}

function toggleShowHidden() {
  showHidden = !showHidden;
  localStorage.setItem('showHidden', showHidden);
  updateShowHiddenButton();
  loadDir();
}

function updateShowHiddenButton() {
  const btn = document.getElementById('showHiddenBtn');
  if (btn) {
    btn.innerHTML = showHidden ? '👁️ Ẩn file ẩn' : '👁️ Hiện file ẩn';
    if (showHidden) {
      btn.style.color = '#58a6ff';
      btn.style.borderColor = 'rgba(88, 166, 255, 0.4)';
    } else {
      btn.style.color = '';
      btn.style.borderColor = '';
    }
  }
}

function hasThumbnail(ext) {
  return ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.mp4', '.mkv', '.webm', '.avi', '.mov', '.apk'].includes(ext.toLowerCase());
}

function showFallbackIconMini(img) {
  img.style.display = 'none';
  const span = img.nextElementSibling;
  if (span) {
    span.style.display = 'inline-block';
  }
}

function showFallbackIconGrid(img) {
  img.style.display = 'none';
  const span = img.nextElementSibling;
  if (span) {
    span.style.display = 'inline-block';
  }
}

async function init(){
  try{
    updateViewModeButton();
    updateShowHiddenButton();
    info=await api('/api/info');
    rootPath=info.root;
    currentPath=rootPath;
    await loadDir();
  }catch(e){setStatus('Lỗi: '+e.message, 'error')}
}

async function loadDir(){
  setStatus('Đang tải...', 'info');
  try{
    const data=await api('/api/list?path='+encodeURIComponent(currentPath)+'&showHidden='+showHidden);
    currentPath=data.path;
    entries=data.entries||[];
    selected.clear();
    render();
    setStatus(entries.length+' mục', 'success');
  }catch(e){setStatus('Lỗi: '+e.message, 'error')}
}

function refresh(){loadDir()}

function showRoots(){currentPath='@roots';loadDir();}

function goUp(){
  if(currentPath==='@roots')return;
  if(currentPath===rootPath)return;
  const parts=currentPath.replace(/\\/g,'/').split('/');
  parts.pop();
  let parent=parts.join('/')||'/';
  if(parent.length===2&&parent[1]===':')parent+='/';
  currentPath=parent;
  loadDir();
}

function renderBreadcrumb(){
  const el=document.getElementById('breadcrumb');
  const norm=currentPath.replace(/\\/g,'/');
  const rootNorm=rootPath.replace(/\\/g,'/');
  let html='<a onclick="navigate(rootPath)">🏠 Gốc</a>';
  if(norm!==rootNorm){
    const rel=norm.startsWith(rootNorm)?norm.slice(rootNorm.length).replace(/^\//,''):'';
    const parts=rel?rel.split('/'):[];
    let acc=rootNorm;
    parts.forEach(p=>{
      if(!p)return;
      acc+=(acc.endsWith('/')?'':'/')+p;
      const path=acc;
      html+=' / <a onclick="navigate(\''+path.replace(/'/g,"\\'")+'\')">'+esc(p)+'</a>';
    });
  }
  el.innerHTML=html;
}

function render(){
  renderBreadcrumb();
  const c=document.getElementById('content');
  if(!entries.length){c.innerHTML='<div class="empty">Thư mục trống</div>';return}
  
  if (viewMode === 'list') {
    let html='<table><thead><tr><th style="width: 40px;"></th><th>Tên</th><th>Kích thước</th><th style="width: 140px; text-align: right;">Thao tác</th></tr></thead><tbody>';
    entries.forEach(e=>{
      const enc=encodeURIComponent(e.path);
      const sel=selected.has(e.path)?'selected':'';
      const size=e.isDir?'—':fmtSize(e.size);
      html+=`<tr class="${sel}" data-path="${enc}" data-isdir="${e.isDir}" data-ext="${e.ext}">
        <td><input type="checkbox" class="chk" ${sel?'checked':''} onchange="toggleSel(decodeURIComponent('${enc}'),this.checked)"></td>
        <td><div class="name-cell" onclick="openEntry(decodeURIComponent('${enc}'),${e.isDir},'${e.ext}')">
          <div class="thumb-container-mini">
            ${hasThumbnail(e.ext) ? `<img class="thumb-img-mini" src="/api/thumb?path=${enc}" onerror="showFallbackIconMini(this)">` : ''}
            <span class="fallback-icon-mini" style="${hasThumbnail(e.ext) ? 'display: none;' : ''}">${e.isDir ? '📁' : fileIcon(e.ext)}</span>
          </div>
          <span class="fname">${esc(e.name)}</span></div></td>
        <td class="dim">${size}</td>
        <td style="text-align: right;">${actionBtns(e,enc)}</td></tr>`;
    });
    html+='</tbody></table>';
    c.innerHTML=html;
  } else {
    let html='<div class="explorer-grid">';
    entries.forEach(e=>{
      const enc=encodeURIComponent(e.path);
      const sel=selected.has(e.path)?'selected':'';
      const size=e.isDir?'—':fmtSize(e.size);
      html+=`<div class="grid-item ${sel}" onclick="openEntry(decodeURIComponent('${enc}'),${e.isDir},'${e.ext}')">
        <div class="chk-container" onclick="event.stopPropagation()">
          <input type="checkbox" class="chk" ${sel?'checked':''} onchange="toggleSel(decodeURIComponent('${enc}'),this.checked)">
        </div>
        <div class="thumb-container">
          ${hasThumbnail(e.ext) ? `<img class="thumb-img" src="/api/thumb?path=${enc}" onerror="showFallbackIconGrid(this)">` : ''}
          <span class="fallback-icon-grid" style="${hasThumbnail(e.ext) ? 'display: none;' : 'font-size: 40px;'}">${e.isDir ? '📁' : fileIcon(e.ext)}</span>
        </div>
        <div class="name-label" title="${esc(e.name)}">${esc(e.name)}</div>
        <div class="size-label">${size}</div>
      </div>`;
    });
    html+='</div>';
    c.innerHTML=html;
  }
}

function fileIcon(ext){
  const img=['.jpg','.jpeg','.png','.gif','.webp','.bmp'];
  const vid=['.mp4','.mkv','.webm','.avi','.mov'];
  const aud=['.mp3','.wav','.ogg','.flac','.m4a','.aac'];
  if(img.includes(ext))return '🖼️';
  if(vid.includes(ext))return '🎬';
  if(aud.includes(ext))return '🎵';
  if(ext==='.zip')return '🗜️';
  return '📄';
}

function actionBtns(e,enc){
  const pathArg="decodeURIComponent('"+enc+"')";
  let b='';
  if(!e.isDir){
    b+=`<button class="btn" style="padding: 4px 8px; display: inline-flex;" onclick="event.stopPropagation();downloadFile(${pathArg})" title="Tải xuống">⬇</button> `;
    if(isText(e.ext))b+=`<button class="btn" style="padding: 4px 8px; display: inline-flex;" onclick="event.stopPropagation();editFile(${pathArg})" title="Chỉnh sửa">✏</button> `;
    if(isMedia(e.ext))b+=`<button class="btn" style="padding: 4px 8px; display: inline-flex;" onclick="event.stopPropagation();previewMedia(${pathArg},'${e.ext}')" title="Xem">👁</button> `;
    if(e.ext==='.zip')b+=`<button class="btn" style="padding: 4px 8px; display: inline-flex;" onclick="event.stopPropagation();unzipFile(${pathArg})" title="Giải nén">📂</button> `;
  }
  return b;
}

function isText(ext){
  return ['.txt','.md','.json','.xml','.html','.htm','.css','.js','.ts','.dart','.py','.java','.yaml','.yml','.sql','.sh','.csv','.log','.ini','.cfg','.env'].includes(ext);
}
function isMedia(ext){
  return ['.jpg','.jpeg','.png','.gif','.webp','.bmp','.mp4','.mkv','.webm','.avi','.mov','.mp3','.wav','.ogg','.flac','.m4a','.aac'].includes(ext);
}

function openEntry(path,isDir,ext){
  if(isDir){currentPath=path;loadDir();return}
  if(isMedia(ext)){previewMedia(path,ext);return}
  if(isText(ext)){editFile(path);return}
  downloadFile(path);
}

function navigate(path){currentPath=path;loadDir()}

function toggleSel(path,on){
  if(on)selected.add(path);else selected.delete(path);
  render();
}

function getSelected(){
  if(selected.size)return[...selected];
  return[];
}

function pickUpload(){document.getElementById('fileInput').click()}

async function uploadFiles(files){
  if(!files.length)return;
  setStatus('Đang tải lên...', 'info');
  let count=0;
  try{
    for(const f of files){
      const url='/api/upload?path='+encodeURIComponent(currentPath)+'&name='+encodeURIComponent(f.name);
      const r=await fetch(url,{method:'POST',body:f,headers:{'Content-Type':'application/octet-stream'}});
      const j=await r.json();
      if(!r.ok)throw new Error(j.error||'Upload failed');
      count++;
    }
    setStatus('Đã tải lên '+count+' file thành công', 'success');
    loadDir();
  }catch(e){setStatus('Lỗi upload: '+e.message, 'error')}
  document.getElementById('fileInput').value='';
}

function downloadFile(path){
  const a = document.createElement('a');
  a.href = '/api/file?path='+encodeURIComponent(path)+'&download=1';
  a.download = path.split(/[/\\]/).pop() || 'download';
  a.style.display = 'none';
  document.body.appendChild(a);
  a.click();
  setTimeout(() => document.body.removeChild(a), 100);
}

function downloadSelected(){
  const paths = getSelected();
  if(!paths.length){
    setStatus('Chưa chọn mục để tải xuống', 'error');
    return;
  }
  let files = [];
  let hasDirectory = false;
  paths.forEach(path => {
    const entry = entries.find(e => e.path === path);
    if(entry){
      if(entry.isDir){
        hasDirectory = true;
      } else {
        files.push(path);
      }
    }
  });

  if(hasDirectory || paths.length > 5){
    zipAndDownload(paths);
  }else{
    if(files.length === 0){
      setStatus('Không có file nào được chọn để tải xuống', 'error');
      return;
    }
    files.forEach(path => {
      downloadFile(path);
    });
    setStatus('Đang tải xuống ' + files.length + ' file', 'success');
  }
}

async function zipAndDownload(paths){
  try {
    setStatus('Phát hiện thư mục hoặc tải trên 5 mục, tiến hành nén ZIP...', 'info');
    const r = await api('/api/zip', {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({paths, dest: currentPath})
    });
    setStatus('Đã nén thành công: ' + r.name + '. Đang tải xuống...', 'success');
    downloadFile(r.path);
    loadDir();
  } catch(e) {
    setStatus('Lỗi nén zip: ' + e.message, 'error');
  }
}

function selectAll(){
  entries.forEach(e => {
    selected.add(e.path);
  });
  render();
  setStatus('Đã chọn tất cả ' + selected.size + ' mục', 'info');
}

function deselectAll(){
  selected.clear();
  render();
  setStatus('Đã bỏ chọn tất cả', 'info');
}

async function editFile(path){
  try{
    const data=await api('/api/read?path='+encodeURIComponent(path));
    const enc=encodeURIComponent(path);
    showModal('Sửa file: '+path.split(/[/\\]/).pop(),
      '<textarea id="editContent">'+esc(data.content)+'</textarea>',
      '<button class="btn" onclick="closeModal()">Hủy</button><button class="btn primary" onclick="saveEdit(decodeURIComponent(\''+enc+'\'))">Lưu</button>');
  }catch(e){setStatus('Lỗi: '+e.message, 'error')}
}

async function saveEdit(path){
  const content=document.getElementById('editContent').value;
  try{
    await api('/api/write',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({path,content})});
    closeModal();setStatus('Đã lưu thành công', 'success');loadDir();
  }catch(e){setStatus('Lỗi: '+e.message, 'error')}
}

function previewMedia(path,ext){
  const url='/api/file?path='+encodeURIComponent(path);
  const img=['.jpg','.jpeg','.png','.gif','.webp','.bmp'];
  const vid=['.mp4','.mkv','.webm','.avi','.mov'];
  let body='';
  if(img.includes(ext))body='<div class="preview-body"><img src="'+url+'" alt=""></div>';
  else if(vid.includes(ext))body='<div class="preview-body"><video src="'+url+'" controls autoplay></video></div>';
  else body='<div class="preview-body"><audio src="'+url+'" controls autoplay></audio></div>';
  showModal('Xem: '+path.split(/[/\\]/).pop(),body,'<button class="btn" onclick="closeModal()">Đóng</button>');
}

async function promptNew(type){
  const label=type==='folder'?'Tên thư mục mới':'Tên file mới';
  const def=type==='folder'?'New Folder':'untitled.txt';
  showModal(label,'<input id="newName" value="'+def+'">',
    '<button class="btn" onclick="closeModal()">Hủy</button><button class="btn primary" onclick="createNew(\''+type+'\')">Tạo</button>');
  setTimeout(()=>{const el=document.getElementById('newName');el.focus();el.select()},100);
}

async function createNew(type){
  const name=document.getElementById('newName').value.trim();
  if(!name)return;
  try{
    const ep=type==='folder'?'/api/mkdir':'/api/create';
    await api(ep,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({path:currentPath,name})});
    closeModal();loadDir();
  }catch(e){setStatus('Lỗi: '+e.message, 'error')}
}

async function renameSelected(){
  const paths=getSelectedOrOne();
  if(paths.length!==1){setStatus('Chọn 1 mục để đổi tên', 'error');return}
  const path=paths[0];
  const old=path.split(/[/\\]/).pop();
  const enc=encodeURIComponent(path);
  showModal('Đổi tên','<input id="renameName" value="'+esc(old)+'">',
    '<button class="btn" onclick="closeModal()">Hủy</button><button class="btn primary" onclick="doRename(decodeURIComponent(\''+enc+'\'))">OK</button>');
}

async function doRename(path){
  const newName=document.getElementById('renameName').value.trim();
  if(!newName)return;
  try{
    await api('/api/rename',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({path,newName})});
    closeModal();loadDir();
  }catch(e){setStatus('Lỗi: '+e.message, 'error')}
}

async function deleteSelected(){
  const paths=getSelectedOrOne();
  if(!paths.length){setStatus('Chưa chọn mục', 'error');return}
  if(!confirm('Xóa '+paths.length+' mục?'))return;
  try{
    await api('/api/delete',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({paths})});
    loadDir();
  }catch(e){setStatus('Lỗi: '+e.message, 'error')}
}

async function zipSelected(){
  const paths=getSelectedOrOne();
  if(!paths.length){setStatus('Chưa chọn mục', 'error');return}
  try{
    const r=await api('/api/zip',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({paths,dest:currentPath})});
    setStatus('Đã nén thành công: '+r.name, 'success');loadDir();
  }catch(e){setStatus('Lỗi: '+e.message, 'error')}
}

async function unzipFile(path){
  try{
    const r=await api('/api/unzip',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({path})});
    setStatus('Đã giải nén thành công: '+r.name, 'success');loadDir();
  }catch(e){setStatus('Lỗi: '+e.message, 'error')}
}

function getSelectedOrOne(){
  if(selected.size)return[...selected];
  return[];
}

function stopModalMedia(){
  const modal=document.getElementById('modalBody');
  if(!modal)return;
  modal.querySelectorAll('video,audio').forEach(el=>{
    el.pause();
    el.removeAttribute('src');
    el.load();
  });
}

function showModal(title,body,actions){
  stopModalMedia();
  document.getElementById('modalTitle').textContent=title;
  document.getElementById('modalBody').innerHTML=body;
  document.getElementById('modalActions').innerHTML=actions;
  document.getElementById('modalBg').classList.add('open');
}
function closeModal(){
  stopModalMedia();
  document.getElementById('modalBg').classList.remove('open');
  document.getElementById('modalBody').innerHTML='';
}

function fmtSize(b){
  if(b==null)return'—';
  if(b<1024)return b+' B';
  if(b<1048576)return(b/1024).toFixed(1)+' KB';
  if(b<1073741824)return(b/1048576).toFixed(1)+' MB';
  return(b/1073741824).toFixed(1)+' GB';
}
function esc(s){return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;')}

init();
</script>
</body>
</html>''';
