const String webUiHtml = r'''<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Cope X Studio - Web</title>
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:Segoe UI,system-ui,sans-serif;background:#1e1e1e;color:#ccc;min-height:100vh;display:flex;flex-direction:column}
header{background:#252526;border-bottom:1px solid #3c3c3c;padding:10px 16px;display:flex;align-items:center;gap:12px;flex-wrap:wrap}
header h1{font-size:16px;color:#fff;font-weight:600}
.badge{background:#0e639c;color:#fff;padding:2px 8px;border-radius:4px;font-size:12px}
.toolbar{background:#2d2d2d;padding:8px 12px;display:flex;gap:6px;flex-wrap:wrap;border-bottom:1px solid #3c3c3c}
.btn{background:#3c3c3c;border:1px solid #555;color:#ccc;padding:6px 12px;border-radius:4px;cursor:pointer;font-size:13px}
.btn:hover{background:#4a4a4a;color:#fff}
.btn.primary{background:#0e639c;border-color:#0e639c;color:#fff}
.btn.danger{background:#5a1d1d;border-color:#8b2e2e}
.breadcrumb{background:#252526;padding:8px 16px;font-size:13px;color:#888;border-bottom:1px solid #3c3c3c;word-break:break-all}
.breadcrumb a{color:#3794ff;text-decoration:none;cursor:pointer}
.breadcrumb a:hover{text-decoration:underline}
main{flex:1;overflow:auto}
table{width:100%;border-collapse:collapse;font-size:14px}
th,td{padding:10px 14px;text-align:left;border-bottom:1px solid #2d2d2d}
th{background:#252526;color:#888;font-weight:500;position:sticky;top:0;z-index:1}
tr:hover td{background:#2a2d2e}
tr.selected td{background:#264f78}
.icon{width:20px;text-align:center;margin-right:8px}
.name-cell{display:flex;align-items:center;cursor:pointer}
.name-cell:hover .fname{color:#fff}
.fname{color:#ccc}
.dim{color:#888;font-size:12px}
footer{background:#007acc;color:#fff;padding:6px 16px;font-size:12px}
.modal-bg{position:fixed;inset:0;background:rgba(0,0,0,.6);display:none;align-items:center;justify-content:center;z-index:100;padding:16px}
.modal-bg.open{display:flex}
.modal{background:#252526;border:1px solid #3c3c3c;border-radius:8px;padding:20px;min-width:320px;max-width:96vw;max-height:90vh;display:flex;flex-direction:column}
.modal h2{font-size:16px;margin-bottom:12px;color:#fff}
.modal input,.modal textarea{width:100%;background:#3c3c3c;border:1px solid #555;color:#fff;padding:8px;border-radius:4px;font-size:14px;margin-bottom:12px}
.modal textarea{flex:1;min-height:300px;font-family:Consolas,monospace;resize:vertical}
.modal-actions{display:flex;gap:8px;justify-content:flex-end;margin-top:8px}
.preview-body{text-align:center;max-width:90vw;max-height:70vh;overflow:auto}
.preview-body img,video{max-width:100%;max-height:65vh;border-radius:4px}
.preview-body audio{width:100%;margin-top:20px}
.empty{padding:48px;text-align:center;color:#888}
#fileInput{display:none}
.chk{width:16px;height:16px}
</style>
</head>
<body>
<header>
  <h1>Cope X Studio</h1>
  <span class="badge">Web Server</span>
  <span id="serverInfo" class="dim"></span>
</header>
<div class="toolbar">
  <button class="btn" onclick="showRoots()">💾 Ổ đĩa</button>
  <button class="btn" onclick="goUp()">⬆ Lên</button>
  <button class="btn" onclick="refresh()">↻ Làm mới</button>
  <button class="btn primary" onclick="pickUpload()">⬆ Tải lên</button>
  <button class="btn" onclick="promptNew('folder')">📁 Thư mục mới</button>
  <button class="btn" onclick="promptNew('file')">📄 File mới</button>
  <button class="btn" onclick="zipSelected()">🗜 Nén ZIP</button>
  <button class="btn" onclick="renameSelected()">✏ Đổi tên</button>
  <button class="btn danger" onclick="deleteSelected()">🗑 Xóa</button>
  <input type="file" id="fileInput" multiple onchange="uploadFiles(this.files)">
</div>
<div class="breadcrumb" id="breadcrumb"></div>
<main><div id="content" class="empty">Đang tải...</div></main>
<footer id="status">Sẵn sàng</footer>

<div class="modal-bg" id="modalBg" onclick="if(event.target===this)closeModal()">
  <div class="modal" id="modal">
    <h2 id="modalTitle"></h2>
    <div id="modalBody"></div>
    <div class="modal-actions" id="modalActions"></div>
  </div>
</div>

<script>
let rootPath='', currentPath='', entries=[], selected=new Set(), info={};

async function api(url,opts={}){
  const r=await fetch(url,opts);
  const j=await r.json().catch(()=>({}));
  if(!r.ok)throw new Error(j.error||r.statusText);
  return j;
}

function setStatus(msg){document.getElementById('status').textContent=msg}

async function init(){
  try{
    info=await api('/api/info');
    rootPath=info.root;
    currentPath=rootPath;
    const addrs=(info.addresses||[]).map(a=>'http://'+a+':'+info.port).join(' · ');
    document.getElementById('serverInfo').textContent=addrs;
    await loadDir();
  }catch(e){setStatus('Lỗi: '+e.message)}
}

async function loadDir(){
  setStatus('Đang tải...');
  try{
    const data=await api('/api/list?path='+encodeURIComponent(currentPath));
    currentPath=data.path;
    entries=data.entries||[];
    selected.clear();
    render();
    setStatus(entries.length+' mục');
  }catch(e){setStatus('Lỗi: '+e.message)}
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
  let html='<a onclick="navigate(rootPath)">'+esc(rootNorm)+'</a>';
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
  let html='<table><thead><tr><th></th><th>Tên</th><th>Kích thước</th><th></th></tr></thead><tbody>';
  entries.forEach(e=>{
    const enc=encodeURIComponent(e.path);
    const sel=selected.has(e.path)?'selected':'';
    const icon=e.isDir?'📁':fileIcon(e.ext);
    const size=e.isDir?'—':fmtSize(e.size);
    html+=`<tr class="${sel}" data-path="${enc}" data-isdir="${e.isDir}" data-ext="${e.ext}">
      <td><input type="checkbox" class="chk" ${sel?'checked':''} onchange="toggleSel(decodeURIComponent('${enc}'),this.checked)"></td>
      <td><div class="name-cell" onclick="openEntry(decodeURIComponent('${enc}'),${e.isDir},'${e.ext}')">
        <span class="icon">${icon}</span><span class="fname">${esc(e.name)}</span></div></td>
      <td class="dim">${size}</td>
      <td>${actionBtns(e,enc)}</td></tr>`;
  });
  html+='</tbody></table>';
  c.innerHTML=html;
}

function fileIcon(ext){
  const img=['.jpg','.jpeg','.png','.gif','.webp','.bmp'];
  const vid=['.mp4','.mkv','.webm','.avi','.mov'];
  const aud=['.mp3','.wav','.ogg','.flac','.m4a','.aac'];
  if(img.includes(ext))return '🖼';
  if(vid.includes(ext))return '🎬';
  if(aud.includes(ext))return '🎵';
  if(ext==='.zip')return '🗜';
  return '📄';
}

function actionBtns(e,enc){
  const pathArg="decodeURIComponent('"+enc+"')";
  let b='';
  if(!e.isDir){
    b+=`<button class="btn" onclick="event.stopPropagation();downloadFile(${pathArg})">⬇</button> `;
    if(isText(e.ext))b+=`<button class="btn" onclick="event.stopPropagation();editFile(${pathArg})">✏</button> `;
    if(isMedia(e.ext))b+=`<button class="btn" onclick="event.stopPropagation();previewMedia(${pathArg},'${e.ext}')">👁</button> `;
    if(e.ext==='.zip')b+=`<button class="btn" onclick="event.stopPropagation();unzipFile(${pathArg})">📂</button> `;
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
  setStatus('Đang tải lên...');
  let count=0;
  try{
    for(const f of files){
      const url='/api/upload?path='+encodeURIComponent(currentPath)+'&name='+encodeURIComponent(f.name);
      const r=await fetch(url,{method:'POST',body:f,headers:{'Content-Type':'application/octet-stream'}});
      const j=await r.json();
      if(!r.ok)throw new Error(j.error||'Upload failed');
      count++;
    }
    setStatus('Đã tải lên '+count+' file');
    loadDir();
  }catch(e){setStatus('Lỗi upload: '+e.message)}
  document.getElementById('fileInput').value='';
}

function downloadFile(path){
  window.open('/api/file?path='+encodeURIComponent(path)+'&download=1','_blank');
}

async function editFile(path){
  try{
    const data=await api('/api/read?path='+encodeURIComponent(path));
    const enc=encodeURIComponent(path);
    showModal('Sửa file: '+path.split(/[/\\]/).pop(),
      '<textarea id="editContent">'+esc(data.content)+'</textarea>',
      '<button class="btn" onclick="closeModal()">Hủy</button><button class="btn primary" onclick="saveEdit(decodeURIComponent(\''+enc+'\'))">Lưu</button>');
  }catch(e){setStatus('Lỗi: '+e.message)}
}

async function saveEdit(path){
  const content=document.getElementById('editContent').value;
  try{
    await api('/api/write',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({path,content})});
    closeModal();setStatus('Đã lưu');loadDir();
  }catch(e){setStatus('Lỗi: '+e.message)}
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
  }catch(e){setStatus('Lỗi: '+e.message)}
}

async function renameSelected(){
  const paths=getSelectedOrOne();
  if(paths.length!==1){setStatus('Chọn 1 mục để đổi tên');return}
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
  }catch(e){setStatus('Lỗi: '+e.message)}
}

async function deleteSelected(){
  const paths=getSelectedOrOne();
  if(!paths.length){setStatus('Chưa chọn mục');return}
  if(!confirm('Xóa '+paths.length+' mục?'))return;
  try{
    await api('/api/delete',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({paths})});
    loadDir();
  }catch(e){setStatus('Lỗi: '+e.message)}
}

async function zipSelected(){
  const paths=getSelectedOrOne();
  if(!paths.length){setStatus('Chưa chọn mục');return}
  try{
    const r=await api('/api/zip',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({paths,dest:currentPath})});
    setStatus('Đã nén: '+r.name);loadDir();
  }catch(e){setStatus('Lỗi: '+e.message)}
}

async function unzipFile(path){
  try{
    const r=await api('/api/unzip',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({path})});
    setStatus('Đã giải nén: '+r.name);loadDir();
  }catch(e){setStatus('Lỗi: '+e.message)}
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
