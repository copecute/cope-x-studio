const String webUiHtml = r'''<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<link rel="icon" type="image/png" href="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAYAAADimHc4AAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAyNpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDYuMC1jMDAyIDc5LjE2NDQ4OCwgMjAyMC8wNy8xMC0yMjowNjo1MyAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0UmVmPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VSZWYjIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6OUI5NERFRjI2QkI2MTFGMUEwMEJFMzU5QzBGNTRCMTQiIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6OUI5NERFRjE2QkI2MTFGMUEwMEJFMzU5QzBGNTRCMTQiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIDIyLjAgKFdpbmRvd3MpIj4gPHhtcE1NOkRlcml2ZWRGcm9tIHN0UmVmOmluc3RhbmNlSUQ9InhtcC5paWQ6MkE0NzBDN0U2QkIxMTFGMTk1OTdFNEVGOEFGNEE3RUIiIHN0UmVmOmRvY3VtZW50SUQ9InhtcC5kaWQ6MkE0NzBDN0Y2QkIxMTFGMTk1OTdFNEVGOEFGNEE3RUIiLz4gPC9yZGY6RGVzY3JpcHRpb24+IDwvcmRmOlJERj4gPC94OnhtcG1ldGE+IDw/eHBhY2tldCBlbmQ9InIiPz5Eny0MAAAzRUlEQVR42ux9Cbhk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"/>
<title>Cope X Studio</title>
<style>
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap');
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:'Inter',system-ui,-apple-system,sans-serif;background-color:#0b0c10;background-image:radial-gradient(circle at 50% 0%,#1a2230 0%,#0b0c10 80%);color:#adbac7;height:100vh;height:100dvh;display:flex;flex-direction:column;overflow:hidden;-webkit-font-smoothing:antialiased}
header{background:rgba(18,20,28,0.85);backdrop-filter:blur(12px);-webkit-backdrop-filter:blur(12px);border-bottom:1px solid rgba(255,255,255,0.06);padding:12px 20px;display:flex;align-items:center;justify-content:space-between;z-index:10;flex-shrink:0}
header .brand{display:flex;align-items:center;gap:10px}
header h1{font-size:16px;color:#fff;font-weight:700;letter-spacing:-0.3px}
.badge-container{display:flex;align-items:center;gap:12px}
.badge{background:linear-gradient(135deg,#0e639c,#007acc);color:#fff;padding:2px 8px;border-radius:12px;font-size:11px;font-weight:600;letter-spacing:0.3px;box-shadow:0 2px 8px rgba(0,122,204,0.3)}
.server-status{display:flex;align-items:center;gap:6px;font-size:11px;color:#4ade80;font-weight:500}
.status-dot{width:8px;height:8px;background-color:#4ade80;border-radius:50%;box-shadow:0 0 8px #4ade80;animation:pulse 1.8s infinite}
@keyframes pulse{0%{transform:scale(0.9);opacity:0.6}50%{transform:scale(1.1);opacity:1;box-shadow:0 0 12px #4ade80}100%{transform:scale(0.9);opacity:0.6}}
.toolbar-container{display:flex;flex-direction:column;border-bottom:1px solid rgba(255,255,255,0.05);flex-shrink:0}
.toolbar{background:rgba(24,28,38,0.7);backdrop-filter:blur(8px);padding:8px 16px;display:flex;gap:6px;align-items:center;overflow-x:auto;scrollbar-width:none;-ms-overflow-style:none}
.toolbar::-webkit-scrollbar{display:none}
.toolbar.top-row{border-bottom:1px solid rgba(255,255,255,0.03)}
.toolbar.bottom-row{background:rgba(18,21,28,0.5);padding:6px 16px}
.toolbar .btn{flex-shrink:0}
.toolbar .divider{width:1px;height:20px;background:rgba(255,255,255,0.1);margin:0 4px;flex-shrink:0}
.btn{background:rgba(255,255,255,0.05);border:1px solid rgba(255,255,255,0.08);color:#cdd9e5;padding:6px 12px;border-radius:6px;cursor:pointer;font-size:13px;font-weight:500;display:flex;align-items:center;gap:6px;transition:all 0.15s cubic-bezier(0.4,0,0.2,1)}
.btn:hover{background:rgba(255,255,255,0.1);color:#fff;border-color:rgba(255,255,255,0.15);transform:translateY(-1px)}
.btn:active{transform:translateY(0)}
.btn.primary{background:linear-gradient(135deg,#0e639c,#007acc);border:none;color:#fff;font-weight:600;box-shadow:0 3px 8px rgba(0,122,204,0.2)}
.btn.primary:hover{background:linear-gradient(135deg,#1177bb,#0088ee);box-shadow:0 3px 12px rgba(0,122,204,0.3)}
.btn.danger{background:rgba(248,81,73,0.12);border:1px solid rgba(248,81,73,0.25);color:#f85149}
.btn.danger:hover{background:rgba(248,81,73,0.22);border-color:rgba(248,81,73,0.45);color:#ff6b6b}
.breadcrumb{background:#11141c;padding:8px 20px;font-size:13px;color:#768390;border-bottom:1px solid rgba(255,255,255,0.05);display:flex;align-items:center;gap:6px;flex-shrink:0;word-break:break-all}
.breadcrumb a{color:#58a6ff;text-decoration:none;cursor:pointer;transition:color 0.15s ease;font-weight:500}
.breadcrumb a:hover{color:#79c0ff;text-decoration:underline}
main{flex:1;overflow-y:auto;padding:16px;background:#0d1117}
.explorer-card{background:rgba(22,27,34,0.6);border:1px solid rgba(255,255,255,0.05);border-radius:10px;overflow:hidden;box-shadow:0 8px 24px rgba(0,0,0,0.15)}
table{width:100%;border-collapse:collapse;font-size:14px}
th,td{padding:12px 16px;text-align:left;border-bottom:1px solid rgba(255,255,255,0.04)}
th{background:rgba(22,27,34,0.95);color:#768390;font-weight:600;font-size:12px;text-transform:uppercase;letter-spacing:0.5px;position:sticky;top:0;z-index:1}
tr{transition:background-color 0.15s ease}
tr:hover td{background:rgba(255,255,255,0.02)}
tr.selected td{background:rgba(56,139,253,0.08)!important}
.chk{width:17px;height:17px;accent-color:#58a6ff;cursor:pointer}
.name-cell{display:flex;align-items:center;cursor:pointer;gap:10px}
.name-cell:hover .fname{color:#58a6ff}
.fname{color:#adbac7;font-weight:500;transition:color 0.15s ease}
.icon{font-size:18px;width:24px;text-align:center}
.dim{color:#768390;font-size:13px}
.explorer-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(130px,1fr));gap:16px;padding:16px}
.grid-item{background:rgba(22,27,34,0.4);border:1px solid rgba(255,255,255,0.05);border-radius:8px;padding:16px 12px;display:flex;flex-direction:column;align-items:center;text-align:center;position:relative;cursor:pointer;transition:all 0.15s ease;user-select:none}
.grid-item:hover{background:rgba(255,255,255,0.03);border-color:rgba(255,255,255,0.1);transform:translateY(-2px)}
.grid-item.selected{background:rgba(56,139,253,0.08)!important;border-color:rgba(56,139,253,0.4)}
.grid-item .chk-container{position:absolute;top:8px;left:8px;z-index:2}
.grid-item .thumb-container{width:64px;height:64px;display:flex;align-items:center;justify-content:center;margin-bottom:8px;flex-shrink:0}
.grid-item .thumb-img{max-width:100%;max-height:100%;border-radius:4px;object-fit:cover}
.grid-item .fallback-icon-grid{font-size:40px}
.grid-item .name-label{font-size:13px;color:#adbac7;font-weight:500;word-break:break-all;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden;text-overflow:ellipsis;line-height:1.4;margin-top:4px}
.grid-item .size-label{font-size:11px;color:#768390;margin-top:4px}
.thumb-container-mini{width:24px;height:24px;display:inline-flex;align-items:center;justify-content:center;margin-right:8px;flex-shrink:0}
.thumb-img-mini{max-width:100%;max-height:100%;border-radius:2px;object-fit:cover}
.fallback-icon-mini{font-size:16px}
.modal-bg{position:fixed;inset:0;background:rgba(0,0,0,0.7);backdrop-filter:blur(4px);display:none;align-items:center;justify-content:center;z-index:100;padding:16px}
.modal-bg.open{display:flex}
.modal{background:#1c2128;border:1px solid rgba(255,255,255,0.08);border-radius:10px;padding:20px;min-width:320px;max-width:600px;width:100%;max-height:85vh;display:flex;flex-direction:column;box-shadow:0 16px 32px rgba(0,0,0,0.35)}
.modal h2{font-size:16px;margin-bottom:14px;color:#fff;font-weight:600}
.modal input,.modal textarea{width:100%;background:#22272e;border:1px solid rgba(255,255,255,0.1);color:#adbac7;padding:8px 12px;border-radius:6px;font-size:14px;margin-bottom:14px;outline:none;transition:border-color 0.2s ease}
.modal input:focus,.modal textarea:focus{border-color:#58a6ff}
.modal textarea{flex:1;min-height:250px;font-family:'JetBrains Mono',Consolas,monospace;resize:vertical}
.modal-actions{display:flex;gap:8px;justify-content:flex-end}
.preview-body{text-align:center;max-width:100%;max-height:55vh;overflow:auto}
.preview-body img,.preview-body video{max-width:100%;max-height:50vh;border-radius:6px}
.empty{padding:48px 20px;text-align:center;color:#768390;font-size:14px}
footer{background:#1c2128;border-top:1px solid rgba(255,255,255,0.05);color:#adbac7;padding:8px 20px;font-size:12px;cursor:pointer;user-select:none;display:flex;justify-content:space-between;align-items:center;flex-shrink:0;transition:background-color 0.15s ease}
footer:hover{background:#22272e}
.console-panel{background:#0d1117;border-top:1px solid rgba(255,255,255,0.08);height:200px;display:none;flex-direction:column;font-family:'JetBrains Mono',Consolas,monospace;font-size:12px;color:#adbac7;flex-shrink:0}
.console-panel.open{display:flex}
.console-header{background:#1c2128;border-bottom:1px solid rgba(255,255,255,0.05);display:flex;justify-content:space-between;align-items:center;padding:6px 16px;flex-shrink:0}
.console-tabs{display:flex;align-items:center;gap:8px}
.console-tabs .active{color:#fff;font-weight:600;border-bottom:2px solid #58a6ff;padding:2px 0 6px 0}
.console-actions button{background:transparent;border:none;color:#768390;cursor:pointer;font-size:13px;padding:4px;border-radius:4px;transition:all 0.15s ease}
.console-actions button:hover{color:#fff;background:rgba(255,255,255,0.05)}
.console-body{flex:1;overflow-y:auto;padding:12px 16px;line-height:1.6;white-space:pre-wrap;word-break:break-all}
.log-entry{margin-bottom:4px}
.log-time{color:#57ab5a;margin-right:10px}
.log-error{color:#f85149}
.log-info{color:#58a6ff}
.log-success{color:#56d364}
::-webkit-scrollbar{width:6px;height:6px}
::-webkit-scrollbar-track{background:#0d1117}
::-webkit-scrollbar-thumb{background:#30363d;border-radius:3px}
::-webkit-scrollbar-thumb:hover{background:#8b949e}
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
  return ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.heic', '.heif', '.mp4', '.mkv', '.webm', '.avi', '.mov', '.pdf', '.apk'].includes(ext.toLowerCase());
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
