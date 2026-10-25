import {BASE_ASSETS,CATEGORIES,CATEGORY_NAMES,exampleProject,validateProject,clone,uid,snap,bounds,topObjectAt,placeObject,object} from './model.mjs';
import {ROOM_NAMES,validateCatalog,mergeCatalogAssets,filterLibraryAssets,newRoomProject,migrateLegacyHallReferences,mergeUserAssets,createSerialWriter} from './catalog.mjs';
import {validateVisualContract,contractFits,spriteForAsset,actorLocalFoot,previewActorFoot,visualInstances,splitSpriteDrawOrder,projectedUprightRect,actorScreenRect,seedPilotVisuals,canPopulateHall,movePreviewActor} from './visual-contract.mjs';
import {BUILTIN_HALL_VISUALS} from './hall-pilot.mjs';
import {GODOT_CAMERA_DEGREES,GODOT_DEFAULT_ZOOM,FLOOR_DEPTH_RATIO,depthRatio,toScreen,toWorld,worldDragDelta,fitProjectedRoom,projectedPixelHeight,gameRoomReference} from './projection.mjs';
const $=s=>document.querySelector(s);
const canvas=$('#canvas'),ctx=canvas.getContext('2d');
let project=exampleProject(),selected=null,selectedAsset='armchair',selectedLayer='objects',tool='select',category='all',showGrid=true;
let productionCatalog=null;
let past=[],future=[],view={x:0,y:0,scale:1},ready=false,gesture=null,dirty=false,saveTimer=null,importFile=null;
let editRevision=0,onlyMissing=false,catalogScope='all',viewMode='game',worldReference=null,showDoorGuides=true,referenceImage=null,visualContract=validateVisualContract(BUILTIN_HALL_VISUALS),actorImage=null,drawActorPreview=true;
const pointers=new Map(),imageCache=new Map(),pilotImages=new Map();
function notify(message){$('#notice').textContent=message;}
function changed(){editRevision++;dirty=true;$('#objectCount').textContent=`${project.objects.length} объектов • ${project.layers.length} слоёв`;clearTimeout(saveTimer);saveTimer=setTimeout(save,550);if(productionCatalog){if(onlyMissing)renderPalette();else updateCatalogProgress();}draw();}
function checkpoint(){past.push(JSON.stringify(project));if(past.length>60)past.shift();future=[];historyButtons();}
function historyButtons(){$('#undo').disabled=!past.length;$('#redo').disabled=!future.length;}
function undo(){if(!past.length)return;future.push(JSON.stringify(project));project=validateProject(JSON.parse(past.pop()));selected=null;refresh();changed();historyButtons();}
function redo(){if(!future.length)return;past.push(JSON.stringify(project));project=validateProject(JSON.parse(future.pop()));selected=null;refresh();changed();historyButtons();}
function db(){return new Promise((resolve,reject)=>{const request=indexedDB.open('raven-room-builder',1);request.onupgradeneeded=()=>request.result.createObjectStore('projects');request.onsuccess=()=>resolve(request.result);request.onerror=()=>reject(request.error);});}
async function persistSnapshot(snapshot){
 const database=await db();
 try{await new Promise((resolve,reject)=>{const t=database.transaction('projects','readwrite');t.objectStore('projects').put(snapshot,'current');t.objectStore('projects').put(snapshot,'room:'+snapshot.roomId);t.oncomplete=()=>resolve();t.onerror=()=>reject(t.error);t.onabort=()=>reject(t.error||new Error('Транзакция сохранения отменена'));});}
 finally{database.close();}
}
const writeSnapshot=createSerialWriter(persistSnapshot);
async function save(){
 clearTimeout(saveTimer);saveTimer=null;
 // Capture the immutable room snapshot now, and serialize writes; old room saves
 // must never land AFTER a newer room is selected.
 const snapshot=clone(project),revision=editRevision;
 const operation=writeSnapshot(snapshot);
 try{await operation;if(project.roomId===snapshot.roomId&&editRevision===revision)dirty=false;notify('Сохранено локально на этом устройстве');return true;}
 catch(err){notify('Ошибка сохранения — экспортируй JSON, не переключай комнату');console.error(err);return false;}
}
async function restore(){try{const database=await db();const data=await new Promise((resolve,reject)=>{const r=database.transaction('projects').objectStore('projects').get('current');r.onsuccess=()=>resolve(r.result);r.onerror=()=>reject(r.error);});database.close();if(data){project=validateProject(data);migrateLegacyHallReferences(project);}}catch(e){console.warn('Local project unavailable:',e);notify('Автосохранение недоступно — используй JSON');}}
async function loadProjectByRoom(roomId){
  const database=await db();
  try {return await new Promise((resolve,reject)=>{const r=database.transaction('projects').objectStore('projects').get('room:'+roomId);r.onsuccess=()=>resolve(r.result);r.onerror=()=>reject(r.error);});}
  finally {database.close();}
}
async function switchRoom(roomId){
  if(roomId===project.roomId)return;
  if(!ROOM_NAMES[roomId]){notify('Неизвестная комната');return;}
  if(!await save())throw new Error('Черновик не сохранён; экспортируй JSON перед переключением');
  let loaded=null;
  try{loaded=await loadProjectByRoom(roomId);}catch(e){console.warn('Room loading failed:',e);}
  const previous=project;
  project=loaded?validateProject(loaded):newRoomProject(exampleProject,uid,roomId);
  mergeUserAssets(project,previous);
  migrateLegacyHallReferences(project);
  if(productionCatalog)mergeCatalogAssets(project,productionCatalog);
  selected=null;selectedLayer='objects';selectedAsset='armchair';past=[];future=[];
  refresh();fit();historyButtons();changed();
  notify('Комната: '+ROOM_NAMES[roomId]+(loaded?' — сохранённый черновик':' — новый черновик'));
}
async function loadProductionCatalog(){
  try{
    const response=await fetch('./catalog/room-items.json',{cache:'no-cache'});
    if(!response.ok)throw new Error('HTTP '+response.status);
    productionCatalog=validateCatalog(await response.json());
    mergeCatalogAssets(project,productionCatalog);
    changed();renderPalette();
    notify('Загружен каталог: '+productionCatalog.items.length+' позиций (все предварительные)');
  }catch(err){console.warn('Catalog unavailable:',err);notify('Каталог недоступен — базовые инструменты и локальный проект работают');}
}
function assetFor(o){return project.assets.find(a=>a.id===o.assetId);}
function layerFor(o){return project.layers.find(l=>l.id===o.layerId);}
function drawAsset(c,o){const a=assetFor(o);if(!a)return; c.save();c.translate(o.x+o.w/2,o.y+o.h/2);c.rotate((o.rotation||0)*Math.PI/180); c.globalAlpha=o.opacity??1;
 const w=o.w,h=o.h,x=-w/2,y=-h/2;
 if(a.image){let image=imageCache.get(a.id);if(!image){image=new Image();image.src=a.image;image.onload=draw;imageCache.set(a.id,image);}if(image.complete&&image.naturalWidth) c.drawImage(image,x,y,w,h);else{c.fillStyle='#544554';c.fillRect(x,y,w,h);}}else{
   c.fillStyle=a.color||'#7e6476';c.strokeStyle='#493942';c.lineWidth=2;
   if(a.id==='rug'){c.fillRect(x,y,w,h);c.strokeStyle='#d2b17a';c.strokeRect(x+10,y+10,w-20,h-20);c.strokeRect(x+15,y+15,w-30,h-30);}
   else if(a.id==='stairs'){c.fillRect(x,y,w,h);c.strokeStyle='#e6d1b2';for(let i=1;i<7;i++){const dy=y+(h/7)*i;c.beginPath();c.moveTo(x+8,dy);c.lineTo(x+w-8,dy);c.stroke();}}
   else if(a.id==='armchair'||a.id==='sofa'){round(c,x,y,w,h,10);c.fill();c.stroke();c.fillStyle='#a87983';round(c,x+7,y+10,w-14,h-20,7);c.fill();c.fillStyle='#3f303d';c.fillRect(x,y,w,12);}
   else if(a.id==='clock'){round(c,x+4,y+2,w-8,h-4,5);c.fill();c.stroke();c.fillStyle='#e0c697';c.beginPath();c.arc(0,y+19,Math.min(w/4,14),0,Math.PI*2);c.fill();c.fillStyle='#4f3c2c';c.fillRect(-2,y+18,2,10);}
   else if(a.id==='table'){c.beginPath();c.ellipse(0,0,w/2,h/2,0,0,Math.PI*2);c.fill();c.stroke();c.beginPath();c.ellipse(0,0,w/2-7,h/2-7,0,0,Math.PI*2);c.stroke();}
   else if(a.id==='plant'){c.beginPath();c.arc(0,0,w/2,0,Math.PI*2);c.fill();c.fillStyle='#77a67a';for(let i=0;i<6;i++){c.beginPath();c.ellipse(Math.cos(i)*w/5,Math.sin(i)*h/5,w/5,h/10,i,0,Math.PI*2);c.fill();}}
   else{c.fillRect(x,y,w,h);c.strokeRect(x,y,w,h);if(a.id!=='stone'&&a.id!=='wood'&&a.id!=='wall'){c.font=`${Math.min(28,h*.55)}px system-ui`;c.textAlign='center';c.textBaseline='middle';c.fillStyle='#f0dbc1';c.fillText(a.symbol||'▪',0,0);}}
 }c.restore();}
function round(c,x,y,w,h,r){c.beginPath();c.roundRect(x,y,w,h,Math.max(0,Math.min(r,w/2,h/2)));}

function pilotImage(file){
 if(pilotImages.has(file))return pilotImages.get(file);
 const img=new Image();img.onload=draw;
 img.onerror=()=>notify('Не удалось загрузить пилотный спрайт: '+file);
 img.src='./reference/sprites/'+file;
 pilotImages.set(file,img);return img;
}
async function loadHallVisuals(){
 try{
  const res=await fetch('./reference/hall_visual_contract.json',{cache:'no-cache'});
  if(!res.ok)throw Error('HTTP '+res.status);
  const remote=validateVisualContract(await res.json());
  if(JSON.stringify(remote)!==JSON.stringify(BUILTIN_HALL_VISUALS))throw Error('Pilot contract version mismatch');
  visualContract=remote;
 }catch(err){console.warn('Using built-in Hall visual contract',err);notify('Встроенная схема холла активна; изображения требуют подключения');}
 actorImage=pilotImage(visualContract.actor.source);
 for(const sprite of visualContract.sprites)pilotImage(sprite.file);
 renderPalette();draw();
}
function populateHallDraft(target){
 if(!canPopulateHall(target,visualContract))return 0;
 if(!productionCatalog)throw Error('Библиотека предметов ещё не загрузилась');
 return seedPilotVisuals(target,visualContract,ref=>target.assets.find(a=>a.assetRefId===ref),
  (asset,rect,sprite)=>object(asset,rect.x,rect.y,{w:rect.w,h:rect.h,layerId:asset.layerId,assetRefId:asset.assetRefId,state:sprite.state}));
}
function placeOnoeNow(){
 if(!activeContract()){notify('Оноэ можно разместить только в холле Godot 700×690');return;}
 checkpoint();movePreviewActor(project,visualContract);drawActorPreview=true;$('#showActor').checked=true;
 changeTool('actor');changed();togglePanel(null);
 notify('Оноэ размещена. Коснись пола, чтобы изменить её положение.');
}
function activeContract(){return visualContract&&contractFits(project,visualContract)?visualContract:null;}
function drawPilotItem(c,item,viewport,mode='upright'){
 const o=item.object,src=pilotImage(item.sprite.file);
 let box;
 if(mode==='floor'){
  const tl=toScreen({x:o.x,y:o.y},viewport,'game');
  box={x:tl.x,y:tl.y,w:o.w*viewport.scale,h:o.h*viewport.scale*depthRatio('game')};
 }else box=projectedUprightRect(o,viewport,toScreen);
 c.save();c.globalAlpha=o.opacity??1;
 if(src.complete&&src.naturalWidth)c.drawImage(src,box.x,box.y,box.w,box.h);
 else {c.fillStyle='#66505c99';c.fillRect(box.x,box.y,box.w,box.h);}
 c.restore();
}
function drawPreviewActor(c,viewport,contract){
 if(!drawActorPreview)return;
 const foot=previewActorFoot(project,contract),box=actorScreenRect(foot,contract.actor,viewport,toScreen);
 c.save();
 if(actorImage?.complete&&actorImage.naturalWidth){
  const [sx,sy,sw,sh]=contract.actor.frameRect;
  c.drawImage(actorImage,sx,sy,sw,sh,box.x,box.y,box.w,box.h);
 }else{c.fillStyle='#d3aa9c';c.fillRect(box.x,box.y,box.w,box.h);}
 c.fillStyle='#56dcca';c.beginPath();
 const p=toScreen(foot,viewport,'game');c.arc(p.x,p.y,3*viewport.scale,0,Math.PI*2);c.fill();
 c.restore();
}
function drawGameSprites(c,viewport,contract,exporting=false){
 const foot=previewActorFoot(project,contract),parts=splitSpriteDrawOrder(visualInstances(project,contract).filter(x=>layerFor(x.object)?.visible),foot.y);
 for(const item of parts.behind)drawPilotItem(c,item,viewport);
 drawPreviewActor(c,viewport,contract);
 for(const item of parts.front)drawPilotItem(c,item,viewport);
 if(!exporting&&selected){
  const o=project.objects.find(o=>o.id===selected);
  if(o&&spriteForAsset(contract,o.assetRefId)){
   const box=projectedUprightRect(o,viewport,toScreen);
   const rect=spriteForAsset(contract,o.assetRefId)?.mode==='floor'
      ?{x:toScreen({x:o.x,y:o.y},viewport,'game').x,
        y:toScreen({x:o.x,y:o.y},viewport,'game').y,
        w:o.w*viewport.scale,h:o.h*viewport.scale*depthRatio('game')} :box;
   c.save();c.strokeStyle='#42b9f9';c.lineWidth=2;
   c.setLineDash([7,4]);c.strokeRect(rect.x,rect.y,rect.w,rect.h);
   c.restore();
  }
 }
}
function hitGamePilot(pos){
 const contract=activeContract();if(!contract||viewMode!=='game')return null;
 const items=visualInstances(project,contract);
 // Upright cutouts must take priority over the large underlying carpet.
 const order=items.sort((a,b)=>
  (a.sprite.mode==='upright'?0:1)-(b.sprite.mode==='upright'?0:1) || b.footY-a.footY);
 for(const entry of order){
  const o=entry.object;const r=entry.sprite.mode==='upright'
    ?projectedUprightRect(o,view,toScreen)
    :{x:toScreen({x:o.x,y:o.y},view,'game').x,y:toScreen({x:o.x,y:o.y},view,'game').y,w:o.w*view.scale,h:o.h*view.scale*depthRatio('game')};
  if(pos.x>=r.x-5&&pos.x<=r.x+r.w+5&&pos.y>=r.y-5&&pos.y<=r.y+r.h+5
     &&!layerFor(o)?.locked&&layerFor(o)?.visible)return o;
 }
 return null;
}


function referenceForCurrentRoom(){return gameRoomReference(project,worldReference);}
function ensureHallReferenceImage(){
 if(referenceImage)return referenceImage;
 referenceImage=new Image();
 referenceImage.onload=draw;
 referenceImage.onerror=()=>notify('Экспериментальный фон Godot не загружен');
 referenceImage.src='./reference/hall_twin_staircases.png';
 return referenceImage;
}
async function loadGameReference(){
 try{
  const response=await fetch('./reference/season1_world_map.json',{cache:'no-cache'});
  if(!response.ok)throw new Error('HTTP '+response.status);
  worldReference=await response.json();
  if(worldReference.schemaVersion!==1||!Array.isArray(worldReference.rooms))throw new Error('Некорректный формат карты');
  if(project.roomId==='RM-ROOM-HALL')ensureHallReferenceImage();
  draw();
 }catch(err){console.warn('Godot reference unavailable:',err);notify('Пока недоступна схема дверей Godot');}
}
function drawDoorGuides(c,reference){
 if(!showDoorGuides||!reference?.aligned)return;
 c.save();c.lineWidth=2;c.font='11px system-ui';
 for(const prop of reference.props){
  c.strokeStyle='#ffda91';c.lineWidth=2;c.setLineDash([5,3]);
  c.strokeRect(prop.x,prop.y,prop.w,prop.h);
  c.setLineDash([]);c.fillStyle='#ffda91';c.font='10px system-ui';
  c.fillText(prop.id.replace('RM-ASSET-HALL-',''),prop.x+4,prop.y+12);
 }
 for(const door of reference.doors){
  c.strokeStyle=door.status==='future'?'#efaaa7':'#76d8b4';
  c.fillStyle=c.strokeStyle;
  c.beginPath();c.arc(door.x,door.y,8,0,Math.PI*2);c.stroke();
  c.fillText(door.id.replace('RM-DOOR-',''),door.x+11,door.y-6);
 }
 c.restore();
}
function updateProjectionStatus(){
 const r=referenceForCurrentRoom();
 $('#canvasStatus').textContent=viewMode==='game'?'Игровой вид Godot · 65° · пол ×'+FLOOR_DEPTH_RATIO.toFixed(3):'Технический план · XY';
 const warning=$('#renderWarning');
 if(viewMode==='plan')warning.textContent='Вид сверху — вспомогательный. Проверяй композицию в игровом режиме 65°.';
 else if(!r)warning.textContent='Игровая проекция активна, но данные карты Godot недоступны. Графика предметов пока схематическая.';
 else if(!r.aligned)warning.textContent='Черновик '+project.width+'×'+project.height+' не совпадает с размером Godot '+r.width+'×'+r.height+'. Фон и порталы скрыты. Координаты не менялись.';
 else warning.textContent=activeContract()?'Пилотные PNG, прямостоящие спрайты и сортировка относительно Оноэ. Двери/коллизии/маски и финальный арт ещё не утверждены.':'Проекция и двери Godot: PNG предметов пока не доступны.';
 $('#previewMode').value=viewMode;
}
function useGodotZoom(){
 const scale=GODOT_DEFAULT_ZOOM;
 view={scale,x:(canvas.clientWidth-project.width*scale)/2,y:(canvas.clientHeight-project.height*scale*depthRatio(viewMode))/2};
 draw();
}

function drawScene(c,viewport,exporting=false){c.clearRect(0,0,c.canvas.width,c.canvas.height);c.save();c.setTransform(viewport.scale,0,0,viewport.scale*depthRatio(viewMode),viewport.x,viewport.y);c.fillStyle='#bdb6a8';c.fillRect(0,0,project.width,project.height);
 const ref=referenceForCurrentRoom();if(viewMode==='game'&&ref?.aligned&&project.roomId==='RM-ROOM-HALL'){const bg=ensureHallReferenceImage();if(bg.complete&&bg.naturalWidth)c.drawImage(bg,0,0,project.width,project.height);}
 c.strokeStyle='#4d3f46';c.lineWidth=16;c.strokeRect(7,7,project.width-14,project.height-14);
 if(showGrid&&!exporting){c.strokeStyle='#69645c33';c.lineWidth=1/viewport.scale;c.beginPath();for(let x=0;x<=project.width;x+=project.grid){c.moveTo(x,0);c.lineTo(x,project.height);}for(let y=0;y<=project.height;y+=project.grid){c.moveTo(0,y);c.lineTo(project.width,y);}c.stroke();}
 const contract=viewMode==='game'?activeContract():null;
 const records=contract?visualInstances(project,contract):[];
 const renderIDs=new Set(records.map(x=>x.object.id));
 const order=new Map(project.layers.map((l,i)=>[l.id,i]));
 if(contract){
  // Carpets sit on the projected floor, before any tall furniture.
  for(const item of records.filter(x=>x.sprite.mode==='floor'&&layerFor(x.object)?.visible)){
   const img=pilotImage(item.sprite.file);
   if(img.complete&&img.naturalWidth)c.drawImage(img,item.object.x,item.object.y,item.object.w,item.object.h);
   else drawAsset(c,item.object);
  }
 }
 for(const o of [...project.objects].sort((a,b)=>(order.get(a.layerId)||0)-(order.get(b.layerId)||0)))
  if(layerFor(o)?.visible&&!renderIDs.has(o.id))drawAsset(c,o);
 if(!exporting&&viewMode==='game')drawDoorGuides(c,referenceForCurrentRoom());
 if(!exporting&&selected){const o=project.objects.find(o=>o.id===selected);if(o&&!(contract&&renderIDs.has(o.id))){c.save();c.translate(o.x+o.w/2,o.y+o.h/2);c.rotate((o.rotation||0)*Math.PI/180);c.strokeStyle='#2c9cf9';c.lineWidth=2/viewport.scale;c.setLineDash([8/viewport.scale,5/viewport.scale]);c.strokeRect(-o.w/2-3,-o.h/2-3,o.w+6,o.h+6);c.setLineDash([]);c.fillStyle='#2c9cf9';c.beginPath();c.arc(o.w/2+4,-o.h/2-4,7/viewport.scale,0,Math.PI*2);c.fill();c.restore();}}
 c.restore();if(contract)drawGameSprites(c,viewport,contract,exporting);}
function draw(){if(!ready)return;const dpr=window.devicePixelRatio||1,w=Math.round(canvas.clientWidth*dpr),h=Math.round(canvas.clientHeight*dpr);if(w!==canvas.width||h!==canvas.height){canvas.width=w;canvas.height=h;}ctx.setTransform(dpr,0,0,dpr,0,0); // canvas coordinates are CSS pixels
 const fake={scale:view.scale*dpr,x:view.x*dpr,y:view.y*dpr};ctx.setTransform(1,0,0,1,0,0);drawScene(ctx,fake);$('#zoomLabel').textContent=`${Math.round(view.scale*100)}%`;updateProjectionStatus();}
function fit(){view=fitProjectedRoom(project.width,project.height,canvas.clientWidth,canvas.clientHeight,viewMode);draw();}
function toLocal(ev){const r=canvas.getBoundingClientRect();return{x:ev.clientX-r.left,y:ev.clientY-r.top};}
function world(pos){return toWorld(pos,view,viewMode);}
function zoomAt(x,y,factor){const old=view.scale;view.scale=bounds(view.scale*factor,.15,5);view.x=x-(x-view.x)*(view.scale/old);view.y=y-(y-view.y)*(view.scale/old);draw();}
function changeTool(next){tool=next;document.querySelectorAll('[data-tool]').forEach(b=>b.classList.toggle('active',b.dataset.tool===next));notify(next==='actor'?'Коснись места на полу, куда должна встать Оноэ (тест перекрытий)':next==='stamp'?'Коснись комнаты, чтобы поставить выбранный предмет':next==='pan'?'Перетаскивай холст':'Готово');}
function paint(pos){const w=world(pos);if(w.x<0||w.y<0||w.x>project.width||w.y>project.height)return;
 if(tool==='actor'){if(!activeContract()){notify('Сначала создай игровой холл 700×690');return;}movePreviewActor(project,visualContract,w);drawActorPreview=true;$('#showActor').checked=true;changed();notify('Оноэ: '+Math.round(w.x)+' × '+Math.round(w.y));return;}
 if(tool==='stamp'){const asset=project.assets.find(a=>a.id===selectedAsset);const layer=asset?.kind==='tile'?'floor':(asset?.layerId||selectedLayer);const o=placeObject(project,selectedAsset,w.x,w.y,layer,asset?.kind==='tile');if(o){selected=o.id;changed();}}
 else if(tool==='erase'){const o=hitGamePilot(pos)||topObjectAt(project,w.x,w.y);if(o){project.objects=project.objects.filter(a=>a.id!==o.id);if(selected===o.id)selected=null;changed();}}
}
function pointerDown(ev){if(ev.pointerType==='mouse'&&ev.button!==0)return;ev.preventDefault();canvas.setPointerCapture(ev.pointerId);const pos=toLocal(ev);pointers.set(ev.pointerId,pos);if(pointers.size>=2){gesture={mode:'pinch',start:[...pointers.values()]};return;}
 if(tool==='pan'){gesture={mode:'pan',pos};return;}
 if(tool==='stamp'||tool==='erase'||tool==='actor'){checkpoint();paint(pos);gesture={mode:'paint',last:pos};return;}
 const w=world(pos),o=hitGamePilot(pos)||topObjectAt(project,w.x,w.y); selected=o?.id||null;renderProperties();draw();if(o){gesture={mode:'drag',pos,startX:o.x,startY:o.y,id:o.id,moved:false};}else gesture=null;}
function pointerMove(ev){if(!pointers.has(ev.pointerId))return;ev.preventDefault();const pos=toLocal(ev),old=pointers.get(ev.pointerId);pointers.set(ev.pointerId,pos);if(pointers.size>=2){const vals=[...pointers.values()];const oldVals=vals.map(p=>p===pos?old:p);const dist=(a,b)=>Math.hypot(a.x-b.x,a.y-b.y);const before=dist(oldVals[0],oldVals[1]),after=dist(vals[0],vals[1]);const prevMid={x:(oldVals[0].x+oldVals[1].x)/2,y:(oldVals[0].y+oldVals[1].y)/2};const nextMid={x:(vals[0].x+vals[1].x)/2,y:(vals[0].y+vals[1].y)/2};if(before>0)zoomAt(prevMid.x,prevMid.y,after/before);view.x+=nextMid.x-prevMid.x;view.y+=nextMid.y-prevMid.y;draw();return;}
 if(!gesture)return;if(gesture.mode==='pan'){view.x+=pos.x-gesture.pos.x;view.y+=pos.y-gesture.pos.y;gesture.pos=pos;draw();}else if(gesture.mode==='drag'){const o=project.objects.find(a=>a.id===gesture.id);if(!o||layerFor(o)?.locked)return;const offset=worldDragDelta(pos.x-gesture.pos.x,pos.y-gesture.pos.y,view.scale,viewMode),deltaX=offset.x,deltaY=offset.y;if(!gesture.moved&&Math.hypot(deltaX,deltaY)>3){checkpoint();gesture.moved=true;}if(gesture.moved){o.x=snap(gesture.startX+deltaX,project.grid/2);o.y=snap(gesture.startY+deltaY,project.grid/2);draw();}}else if(gesture.mode==='paint'){paint(pos);}}
function pointerUp(ev){if(!pointers.has(ev.pointerId))return;pointers.delete(ev.pointerId);if(gesture?.mode==='drag'&&gesture.moved){changed();renderProperties();}if(pointers.size===0)gesture=null;else gesture={mode:'pan',pos:[...pointers.values()][0]};}
function updateCatalogProgress(){const items=productionCatalog?.items.filter(i=>i.roomId===project.roomId)||[];const present=new Set(project.objects.map(o=>o.assetRefId).filter(Boolean));const count=items.filter(i=>present.has(i.id)).length;$('#roomProgress').textContent=productionCatalog?`На плане: ${count} из ${items.length} позиций · осталось ${items.length-count}`:'Загрузка списка предметов…';}
function renderPalette(){
 const term=$('#search').value.toLocaleLowerCase().trim();
 $('#categories').replaceChildren(...CATEGORIES.map(k=>{const b=document.createElement('button');b.textContent=CATEGORY_NAMES[k];b.className=category===k?'active':'';b.onclick=()=>{category=k;renderPalette();};return b;}));
 const options=Object.entries(ROOM_NAMES);
 const sel=$('#catalogRoom');sel.replaceChildren(...options.map(([id,name])=>{const o=document.createElement('option');o.value=id;o.textContent=name;return o;}));sel.value=project.roomId;
 const scope=$('#catalogScope');scope.value=catalogScope;scope.disabled=!productionCatalog;
 const actual=productionCatalog?.items.filter(i=>i.roomId===project.roomId)||[];
 const withPilots=actual.filter(i=>i.pilotImages?.length).length;
 $('#catalogInfo').textContent=productionCatalog?`Весь особняк: ${productionCatalog.items.length} позиций · ${actual.length} в выбранной комнате · ${withPilots} с экспериментальным PNG · 0 утверждены`:'Загрузка производственного каталога…';
 $('#onlyMissing').closest('label').style.display=catalogScope==='all'&&productionCatalog?'none':'';
 const holder=$('#assets');holder.replaceChildren();
 const placed=new Set(project.objects.map(o=>o.assetRefId).filter(Boolean));
 updateCatalogProgress();
 const scopeMode=productionCatalog?catalogScope:'room';
 const matches=filterLibraryAssets(project,{roomId:project.roomId,scope:scopeMode,category,search:term,onlyMissing,placedRefs:placed});
 let lastRoom=null;
 for(const a of matches){
  if(scopeMode==='all'&&a.roomId!==lastRoom){
    lastRoom=a.roomId;
    const heading=document.createElement('div');heading.className='asset-group-heading';
    heading.textContent=ROOM_NAMES[a.roomId]||a.roomId;
    holder.append(heading);
  }
  const b=document.createElement('button');b.className='asset-card'+(selectedAsset===a.id?' active':'');
  b.title=`${a.label} · ${a.assetRefId||'черновой элемент'} · ${a.productionPriority||'без приоритета'} · ${a.artStatus||'ручной импорт'}`;
  const preview=document.createElement('div');preview.className='asset-preview';
  const pilot=a.assetRefId?spriteForAsset(visualContract,a.assetRefId):null;
  if(pilot){const img=document.createElement('img');img.src='./reference/sprites/'+pilot.file;img.alt='Пилотный PNG';img.loading='lazy';img.onerror=()=>{preview.replaceChildren();preview.textContent=a.symbol||'■';preview.style.color=a.color;};preview.append(img);}
  else if(a.image){const img=document.createElement('img');img.src=a.image;img.alt='';preview.append(img);}
  else{preview.textContent=a.symbol||'■';preview.style.color=a.color;}
  const label=document.createElement('small');label.textContent=a.label;b.append(preview,label);
  if(a.assetRefId){const meta=document.createElement('span');meta.className='asset-meta';meta.textContent=`${a.productionPriority||''} · ${pilot?'PNG пилот':(a.pilotImages||[]).length?'PNG экспериментальный':'макет'}`;b.append(meta);
   if(scopeMode==='all'&&a.roomId!==project.roomId){
     const hint=document.createElement('span');hint.className='asset-room-hint';
     hint.textContent='Выбрать → перейти в эту комнату';b.append(hint);
   }
  }
  b.onclick=async()=>{
   if(a.roomId&&a.roomId!==project.roomId){
     try{await switchRoom(a.roomId);}catch(err){notify('Не удалось сменить комнату: '+err.message);return;}
   }
   selectedAsset=a.id;selectedLayer=a.layerId||selectedLayer;
   changeTool('stamp');renderPalette();togglePanel(null);
  };holder.append(b);
 }
 $('#onlyMissing').checked=onlyMissing;
 $('#paletteCount').textContent=scopeMode==='all'?`${matches.length} показано из ${productionCatalog.items.length} предметов особняка`:`${matches.length} элементов в библиотеке комнаты (включая базовые инструменты)`;
}
function renderLayers(){const box=$('#layers');box.replaceChildren();for(const layer of [...project.layers].reverse()){const row=document.createElement('div');row.className=`layer-row ${selectedLayer===layer.id?'active':''}`;const vis=document.createElement('input');vis.type='checkbox';vis.checked=layer.visible;vis.title='Показать слой';vis.onchange=()=>{checkpoint();layer.visible=vis.checked;changed();};const b=document.createElement('button');b.className='layer-label';b.textContent=layer.name;b.onclick=()=>{selectedLayer=layer.id;renderLayers();};const lock=document.createElement('button');lock.textContent=layer.locked?'🔒':'♧';lock.title='Блокировка слоя';lock.onclick=()=>{checkpoint();layer.locked=!layer.locked;changed();renderLayers();};const up=document.createElement('button');up.textContent='↑';up.title='Поднять слой';up.onclick=()=>{const i=project.layers.indexOf(layer);if(i<project.layers.length-1){checkpoint();[project.layers[i],project.layers[i+1]]=[project.layers[i+1],project.layers[i]];changed();renderLayers();}};row.append(vis,b,lock,up);box.append(row);}}
function makeField(label,value,callback,type='text'){const field=document.createElement('label');field.className='field';field.textContent=label;const input=document.createElement('input');input.type=type;input.value=value??'';input.addEventListener('change',()=>{checkpoint();callback(type==='number'?Number(input.value):input.value);changed();renderProperties();});field.append(input);return field;}
function makeStateField(o,a){
 if(!a?.states?.length)return makeField('Состояние',o.state,v=>o.state=v);
 const label=document.createElement('label');label.className='field';label.textContent='Состояние (плановое)';
 const select=document.createElement('select');const states=[...new Set([...a.states,o.state])];
 for(const state of states){const opt=document.createElement('option');opt.value=state;opt.textContent=state;select.append(opt);}
 select.value=o.state;select.onchange=()=>{checkpoint();o.state=select.value;changed();renderProperties();};label.append(select);return label;
}
function makeAssetReferenceField(o,a){
 if(!a?.assetRefId)return makeField('RM-ASSET-ID',o.assetRefId||'',v=>o.assetRefId=v);
 const label=document.createElement('label');label.className='field';label.textContent='Реестровый RM-ASSET-ID (фиксирован)';
 const input=document.createElement('input');input.value=a.assetRefId;input.readOnly=true;input.title='Связь с реестром фиксирована; дублируй объект, чтобы получить новый ID экземпляра';
 label.append(input);return label;
}
function renderProperties(){const el=$('#properties'),o=project.objects.find(o=>o.id===selected);el.replaceChildren();if(!o){el.textContent='Коснись предмета на холсте';el.classList.add('muted');return;}el.classList.remove('muted');const a=assetFor(o);const head=document.createElement('strong');head.textContent=a?.label||o.assetId;el.append(head);if(a?.assetRefId){const details=document.createElement('p');details.className='catalog-detail';details.textContent=`${a.assetRefId} · ${a.productionPriority} · ${a.artStatus}; размеры, точка опоры и кликабельная зона пока не измерены. ${a.rightsStatus==='requires-review'?'Права на исходник требуют проверки.':''}`;el.append(details);if(a.pilotImages?.length){const link=document.createElement('a');link.className='catalog-source-link';link.href='https://github.com/bezdredoff/RavenManor-Godot/blob/main/'+a.pilotImages[0].split('/').map(encodeURIComponent).join('/');link.target='_blank';link.rel='noopener noreferrer';link.textContent='Открыть исходный экспериментальный PNG';el.append(link);}}
 el.append(makeField('X',o.x,v=>o.x=v,'number'),makeField('Y',o.y,v=>o.y=v,'number'),makeField('Ширина',o.w,v=>o.w=Math.max(1,v),'number'),makeField('Высота',o.h,v=>o.h=Math.max(1,v),'number'),makeField('Поворот (°)',o.rotation,v=>o.rotation=v,'number'),makeStateField(o,a),makeAssetReferenceField(o,a),makeField('Hotspot ID',o.hotspotId||'',v=>o.hotspotId=v));
 const wrapper=document.createElement('div');wrapper.className='field';wrapper.textContent='Слой';const select=document.createElement('select');for(const l of project.layers){const opt=document.createElement('option');opt.value=l.id;opt.textContent=l.name;select.append(opt);}select.value=o.layerId;select.onchange=()=>{checkpoint();o.layerId=select.value;changed();renderLayers();};wrapper.append(select);el.append(wrapper);const row=document.createElement('div');row.className='action-row';for(const [name,action] of [['Дублировать',()=>{checkpoint();const copy=clone(o);copy.id=uid();copy.x+=20;copy.y+=20;project.objects.push(copy);selected=copy.id;changed();renderProperties();}],['Удалить',()=>{checkpoint();project.objects=project.objects.filter(p=>p.id!==o.id);selected=null;changed();renderProperties();}]]){const b=document.createElement('button');b.textContent=name;b.onclick=action;row.append(b);}el.append(row);}
function renderSettings(){$('#populateHall').disabled=!canPopulateHall(project,visualContract);$('#title').value=project.title;$('#roomId').value=project.roomId;$('#roomWidth').value=project.width;$('#roomHeight').value=project.height;$('#gridSize').value=project.grid;$('#objectCount').textContent=`${project.objects.length} объектов • ${project.layers.length} слоёв`;}
function refresh(){imageCache.clear();renderSettings();renderPalette();renderLayers();renderProperties();draw();}
function togglePanel(id){for(const p of [$('#palette'),$('#inspector')])p.classList.toggle('open',p.id===id);}
function download(blob,name){const u=URL.createObjectURL(blob),a=document.createElement('a');a.href=u;a.download=name;document.body.append(a);a.click();a.remove();setTimeout(()=>URL.revokeObjectURL(u),1500);}
function exportJSON(){download(new Blob([JSON.stringify(project,null,2)],{type:'application/json'}),`${project.roomId.toLowerCase()}-room.json`);notify('Экспортирован редактируемый проект');$('#exportDialog').close();}
async function exportPNG(){
 const sourceImages=project.assets.filter(a=>a.image&&project.objects.some(o=>o.assetId===a.id));
 try{await Promise.all(sourceImages.map(async a=>{let image=imageCache.get(a.id);if(!image){image=new Image();image.src=a.image;imageCache.set(a.id,image);}if(!image.complete||!image.naturalWidth)await image.decode();}));}
 catch(error){notify('Не удалось подготовить одно из изображений для PNG');console.error(error);return;}
 if(viewMode==='game'&&referenceForCurrentRoom()?.aligned&&project.roomId==='RM-ROOM-HALL'){try{const bg=ensureHallReferenceImage();if(!bg.complete||!bg.naturalWidth)await bg.decode();}catch(err){notify('Фон Godot недоступен; экспорт без фона');}}
 if(viewMode==='game'&&activeContract()){
   try{const contract=activeContract();
    const files=[...new Set([...contract.sprites.map(x=>x.file),...(drawActorPreview?[contract.actor.source]:[])])];
    await Promise.all(files.map(async file=>{const img=pilotImage(file);if(!img.complete||!img.naturalWidth)await img.decode();}));
   }catch(err){notify('Ошибка загрузки игрового PNG — экспорт отменён');return;}
 }
 const off=document.createElement('canvas');off.width=project.width;off.height=projectedPixelHeight(project.height,viewMode);drawScene(off.getContext('2d'),{x:0,y:0,scale:1},true);off.toBlob(blob=>{if(blob)download(blob,`${project.roomId.toLowerCase()}-preview.png`);else notify('Ошибка экспорта PNG');},'image/png');$('#exportDialog').close();}
async function importJSON(file){if(!file||file.size>45*1024*1024)throw new Error('JSON слишком большой (макс. 45 MB)');const p=validateProject(JSON.parse(await file.text()));migrateLegacyHallReferences(p);if(productionCatalog)mergeCatalogAssets(p,productionCatalog);
 if(!await save())throw new Error('Сначала экспортируй несохранённый черновик');
 project=p;selected=null;selectedAsset=p.assets[0]?.id||'';selectedLayer=p.layers[0]?.id||'';past=[];future=[];historyButtons();refresh();fit();changed();notify('Проект импортирован');}
async function handleSheet(file,columns,rows){if(!file||file.size>10*1024*1024)throw new Error('Файл слишком большой (макс. 10 MB)');if(!/^image\/(png|jpeg|webp)$/.test(file.type))throw new Error('Только PNG, JPEG и WebP');const img=await createImageBitmap(file),cols=Number(columns),rws=Number(rows);if(cols*rws>128||img.width%cols||img.height%rws)throw new Error('Необходимо равномерное деление, не более 128 спрайтов');checkpoint();const w=img.width/cols,h=img.height/rws;const stem=file.name.replace(/\.[^.]+$/,'').slice(0,40);const scratch=document.createElement('canvas');scratch.width=w;scratch.height=h;const c=scratch.getContext('2d');for(let y=0;y<rws;y++)for(let x=0;x<cols;x++){c.clearRect(0,0,w,h);c.drawImage(img,x*w,y*h,w,h,0,0,w,h);project.assets.push({id:uid('asset'),label:cols*rws===1?stem:`${stem} ${x+1}-${y+1}`,kind:'decor',w,h,color:'#80627a',symbol:'▧',image:scratch.toDataURL('image/png'),source:'local-import',license:'User must verify usage rights'});}img.close();renderPalette();changed();notify(`Добавлено ${cols*rws} ассетов`);}
function wire(){document.querySelectorAll('[data-tool]').forEach(b=>b.onclick=()=>changeTool(b.dataset.tool));$('#undo').onclick=undo;$('#redo').onclick=redo;$('#save').onclick=save;$('#fit').onclick=fit;$('#moveActor').onclick=placeOnoeNow;$('#populateHall').onclick=()=>{try{if(!canPopulateHall(project,visualContract)){notify('Заполнение доступно только в пустом холле 700×690');return;}checkpoint();const count=populateHallDraft(project);selected=null;refresh();changed();notify('Размещено '+count+' пилотных предметов.');}catch(err){notify('Не удалось заполнить холл: '+err.message);console.error(err);}};$('#showActor').onchange=e=>{drawActorPreview=e.target.checked;draw();};$('#gameZoom').onclick=useGodotZoom;$('#previewMode').onchange=e=>{viewMode=e.target.value;fit();};$('#showDoorGuides').onchange=e=>{showDoorGuides=e.target.checked;draw();};$('#zoomIn').onclick=()=>zoomAt(canvas.clientWidth/2,canvas.clientHeight/2,1.2);$('#zoomOut').onclick=()=>zoomAt(canvas.clientWidth/2,canvas.clientHeight/2,1/1.2);$('#grid').onchange=ev=>{showGrid=ev.target.checked;draw();};$('#search').oninput=renderPalette;$('#catalogScope').onchange=e=>{catalogScope=e.target.value;renderPalette();};$('#onlyMissing').onchange=e=>{onlyMissing=e.target.checked;renderPalette();};$('#catalogRoom').onchange=e=>switchRoom(e.target.value).catch(err=>notify('Ошибка открытия комнаты: '+err.message));
 $('#title').onchange=e=>{checkpoint();project.title=e.target.value.trim()||'Без названия';changed();};for(const [id,key] of [['roomWidth','width'],['roomHeight','height'],['gridSize','grid']])$("#"+id).onchange=e=>{const v=Number(e.target.value);const p=clone(project);p[key]=v;try{validateProject(p);checkpoint();project[key]=v;changed();fit();}catch(err){notify(err.message);renderSettings();}};
 $('#addLayer').onclick=()=>{checkpoint();const id=uid('layer');project.layers.push({id,name:`Слой ${project.layers.length+1}`,visible:true,locked:false});selectedLayer=id;changed();renderLayers();};
 $('#exportMenu').onclick=()=>$('#exportDialog').showModal();$('#mobileExport').onclick=()=>$('#exportDialog').showModal();$('#exportJSON').onclick=exportJSON;$('#exportPNG').onclick=exportPNG;$('#importJSONBtn').onclick=()=>$('#projectFile').click();$('#projectFile').onchange=async e=>{try{await importJSON(e.target.files[0]);$('#exportDialog').close();}catch(err){notify(err.message);}e.target.value='';};
 $('#newRoom').onclick=async()=>{
 if(!confirm('Создать пустой черновик для этой комнаты? Прежний будет перезаписан. Сначала экспортируй текущий JSON в резервную копию.'))return;
 if(!await save()){notify('Не удалось сохранить текущий черновик — экспортируй JSON');return;}
 const p=newRoomProject(exampleProject,uid,project.roomId);
 const room=gameRoomReference(p,worldReference);
 if(room){
  // The reference is a PROPOSED Godot feasibility floorplan; do not change old projects.
  p.width=room.width;p.height=room.height;p.grid=25;
  p.referenceWorldOrigin=[room.origin.x,room.origin.y];
  p.provenance='Proposed Godot world map room draft; matching floor dimensions, not approved furniture/doors/art.';
 }
 if(productionCatalog)mergeCatalogAssets(p,productionCatalog);
 let count=0;
 try{count=populateHallDraft(p);if(p.roomId==='RM-ROOM-HALL'&&p.width===700&&count!==7)throw Error('Ожидалось 7 предметов, получено '+count);}
 catch(err){notify('Комната не создана: '+err.message);console.error(err);return;}
 project=p;selected=null;past=[];future=[];historyButtons();refresh();fit();changed();
 $('#exportDialog').close();
 notify(count?'Холл 700×690: размещено '+count+' PNG предметов':'Новая комната '+p.width+'×'+p.height);
};
 $('#assetFiles').onchange=e=>{const file=e.target.files[0];if(!file)return;importFile=file;$('#sheetName').textContent=`${file.name} (${Math.round(file.size/1024)} KB)`;$('#sheetDialog').showModal();e.target.value='';};$('#sheetConfirm').onclick=async()=>{try{await handleSheet(importFile,$('#sheetCols').value,$('#sheetRows').value);$('#sheetDialog').close();}catch(err){notify(err.message);}};
 for(const b of document.querySelectorAll('[data-panel]'))b.onclick=()=>togglePanel(b.dataset.panel);$('#closePalette').onclick=()=>togglePanel(null);$('#closeInspector').onclick=()=>togglePanel(null);$('#mobileStamp').onclick=()=>{changeTool('stamp');togglePanel('palette');};
 canvas.addEventListener('pointerdown',pointerDown);canvas.addEventListener('pointermove',pointerMove);canvas.addEventListener('pointerup',pointerUp);canvas.addEventListener('pointercancel',pointerUp);canvas.addEventListener('contextmenu',e=>e.preventDefault());canvas.addEventListener('wheel',e=>{e.preventDefault();const p=toLocal(e);zoomAt(p.x,p.y,e.deltaY<0?1.1:1/1.1);},{passive:false});window.addEventListener('resize',draw);window.addEventListener('keydown',e=>{if(['INPUT','TEXTAREA'].includes(document.activeElement?.tagName)||document.querySelector('dialog[open]'))return;if((e.ctrlKey||e.metaKey)&&e.key.toLowerCase()==='z'){e.preventDefault();e.shiftKey?redo():undo();}if(e.key==='Delete'&&selected){checkpoint();project.objects=project.objects.filter(o=>o.id!==selected);selected=null;refresh();changed();}});
 window.addEventListener('beforeunload',e=>{if(dirty){e.preventDefault();e.returnValue='';}});
}
async function start(){wire();await restore();ready=true;refresh();fit();historyButtons();await loadProductionCatalog();await loadGameReference();await loadHallVisuals();if('serviceWorker'in navigator&&location.protocol.startsWith('http'))navigator.serviceWorker.register('./sw.js').catch(console.warn);}
start();