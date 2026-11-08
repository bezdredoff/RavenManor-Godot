/* Optional versioned floor-map overlay for the EXISTING Room Builder v1 editor.
   No campaign, physics, or canonical map writes. */
export const FIRST_FLOOR_VERSION = 2;
const ROOM = /^RM-ROOM-[A-Z0-9-]+$/;
const DOOR = /^RM-DOOR-[A-Z0-9-]+$/;
const NAV = /^RM-(NAV|ANCHOR)-[A-Z0-9-]+$/;
const FG = /^RM-FG-[A-Z0-9-]+$/;
const clone = value => JSON.parse(JSON.stringify(value));

function values(v,n,label){
 if(!Array.isArray(v)||v.length!==n||v.some(x=>typeof x!=='number'||!Number.isFinite(x)))throw Error(label+': ожидаются '+n+' конечных чисел');
 return v;
}
function items(v,label){
 if(!Array.isArray(v)||v.length>1000)throw Error(label+': ожидается массив до 1000 элементов');
 return v;
}
function ids(rows,re,label){
 const set=new Set();
 rows.forEach((item,i)=>{
  if(!item||typeof item!=='object'||typeof item.id!=='string'||!re.test(item.id))throw Error(label+' #'+i+': неверный ID');
  if(set.has(item.id))throw Error(label+': повторяющийся ID '+item.id);
  set.add(item.id);
 });
 return set;
}
function inside(p,r,t=0){return p[0]>=r[0]-t&&p[0]<=r[0]+r[2]+t&&p[1]>=r[1]-t&&p[1]<=r[1]+r[3]+t;}
function pngPath(v,label){
 if(typeof v!=='string'||!v||v.startsWith('/')||v.includes('..')||v.includes('\\')||!(/^[\w./-]+\.png$/i).test(v))throw Error(label+': требуется относительный PNG путь в репозитории');
}
export function validateFirstFloorDraft(input,reference){
 const d=clone(input);
 if(!d||d.schemaVersion!==FIRST_FLOOR_VERSION||d.kind!=='raven-first-floor-draft')throw Error('firstFloorDraft: несовместимая schemaVersion/kind (нужна v2)');
 const base=d.baseImage;
 if(!base||typeof base!=='object'||('path'in base)===('dataUri'in base))throw Error('baseImage: нужен либо PNG path, либо dataUri');
 values(base.pixelSize,2,'baseImage.pixelSize');
 if(base.pixelSize.some(x=>x<1||x>16384))throw Error('Недопустимый размер PNG');
 if('path'in base)pngPath(base.path,'baseImage.path');
 else if(typeof base.dataUri!=='string'||!/^data:image\/png;base64,[A-Za-z0-9+/=]+$/.test(base.dataUri)||base.dataUri.length>40*1024*1024)throw Error('baseImage: повреждённый PNG dataUri');
 const c=d.calibration;
 if(!c||typeof c!=='object')throw Error('Отсутствует calibration');
 const imageRect=values(c.imageRect,4,'calibration.imageRect'),worldRect=values(c.worldRect,4,'calibration.worldRect');
 if(imageRect[2]<=0||imageRect[3]<=0||worldRect[2]<=0||worldRect[3]<=0||!inside(imageRect.slice(0,2),[0,0,...base.pixelSize])||!inside([imageRect[0]+imageRect[2],imageRect[1]+imageRect[3]],[0,0,...base.pixelSize]))throw Error('Размеры calibration не совпадают с PNG');
 const cp=items(c.controlPoints,'controlPoints');
 if(cp.length<2)throw Error('Нужно минимум две контрольные точки калибровки');
 cp.forEach((p,i)=>{
  if(!p||typeof p!=='object')throw Error('Неверная controlPoint #'+i);
  const pixel=values(p.pixel,2,'controlPoint.pixel'),world=values(p.world,2,'controlPoint.world');
  if(!inside(pixel,imageRect,1))throw Error('ControlPoint вне изображения #'+i);
  const mapped=[0,1].map(j=>worldRect[j]+(pixel[j]-imageRect[j])*worldRect[j+2]/imageRect[j+2]);
  if(Math.hypot(mapped[0]-world[0],mapped[1]-world[1])>1)throw Error('Несовпадающая calibration controlPoint #'+i);
 });
 const rooms=items(d.roomRegions,'roomRegions'),doors=items(d.doorPlacements,'doorPlacements');
 const anchors=items(d.navigationAnchors,'navigationAnchors'),fg=items(d.foregroundObjects,'foregroundObjects');
 const roomIds=ids(rooms,ROOM,'roomRegions');ids(doors,DOOR,'doorPlacements');ids(anchors,NAV,'navigationAnchors');ids(fg,FG,'foregroundObjects');
 const knownRooms=new Set(reference?.rooms?.map(r=>r.id)||[]);
 const knownDoors=new Map(reference?.doors?.map(r=>[r.id,r])||[]);
 const roomRects=new Map();
 rooms.forEach(r=>{
  if(reference&&!knownRooms.has(r.id))throw Error('Неизвестный room ID '+r.id);
  const rect=values(r.rect,4,r.id+'.rect');
  if(rect[2]<=0||rect[3]<=0||!inside(rect.slice(0,2),worldRect)||!inside([rect[0]+rect[2],rect[1]+rect[3]],worldRect))throw Error('Граница комнаты вне calibration '+r.id);
  roomRects.set(r.id,rect);
 });
 doors.forEach(d=>{
  if(reference&&!knownDoors.has(d.id))throw Error('Неизвестный door ID '+d.id);
  const p=values(d.point,2,d.id+'.point');
  if(!Array.isArray(d.rooms)||d.rooms.length!==2||!roomIds.has(d.rooms[0])||(d.rooms[1]!==null&&!roomIds.has(d.rooms[1])))throw Error('Неизвестные комнаты двери '+d.id);
  if(reference){const known=knownDoors.get(d.id);const want=[reference.rooms[known.a].id,known.b>=0?reference.rooms[known.b].id:null];if(d.rooms[0]!==want[0]||d.rooms[1]!==want[1])throw Error('Неверная пара комнат для '+d.id);}
  if(!inside(p,worldRect)||d.rooms.filter(Boolean).some(id=>!inside(p,roomRects.get(id),16)))throw Error('Некорректное положение двери '+d.id);
  if(typeof d.width!=='number'||!Number.isFinite(d.width)||d.width<1||d.width>500)throw Error('Некорректная ширина двери '+d.id);
 });
 const visited=new Set();
 anchors.forEach(a=>{
  if(!roomIds.has(a.roomId))throw Error('Неизвестная комната anchor '+a.id);
  const p=values(a.point,2,a.id+'.point');
  if(!inside(p,roomRects.get(a.roomId),1))throw Error('Anchor вне комнаты '+a.id);
  const key=a.roomId+':'+p.map(x=>x.toFixed(3)).join(',');
  if(visited.has(key))throw Error('Дублирующиеся navigation points в '+a.roomId);
  visited.add(key);
 });
 fg.forEach(f=>{
  if(!roomIds.has(f.roomId))throw Error('Неизвестная комната foreground '+f.id);
  const p=values(f.position,2,f.id+'.position'),size=values(f.size,2,f.id+'.size'),pivot=values(f.pivot,2,f.id+'.pivot');
  if(!inside(p,roomRects.get(f.roomId),1)||size.some(x=>x<=0||x>8000)||pivot.some((x,i)=>x<0||x>size[i]))throw Error('Некорректный floor-contact pivot '+f.id);
  pngPath(f.assetPath,f.id+'.assetPath');
  if(!f.occlusion||!['foot_y','fixed_front','none'].includes(f.occlusion.mode))throw Error('Некорректная occlusion '+f.id);
  if(f.occlusion.alphaMaskPath!==undefined)pngPath(f.occlusion.alphaMaskPath,f.id+'.alphaMaskPath');
 });
 return d;
}
export function makeFirstFloorDraft(map,baseImage){
 if(!map||map.schemaVersion!==1||!Array.isArray(map.rooms)||!Array.isArray(map.doors))throw Error('Нет карты-референса Godot');
 const [w,h]=baseImage.pixelSize,worldRect=[0,0,...values(map.worldSize,2,'worldSize')];
 return validateFirstFloorDraft({
  kind:'raven-first-floor-draft',schemaVersion:2,
  provenance:'Room Builder DRAFT; world map reference is a provisional feasibility plan, not approved art/geometry.',
  baseImage,calibration:{imageRect:[0,0,w,h],worldRect,controlPoints:[
   {pixel:[0,0],world:[0,0]},{pixel:[w,h],world:[worldRect[2],worldRect[3]]}
  ]},
  roomRegions:map.rooms.map(r=>({id:r.id,rect:[...r.rect]})),
  doorPlacements:map.doors.map(d=>({id:d.id,rooms:[map.rooms[d.a].id,d.b<0?null:map.rooms[d.b].id],point:[...d.point],width:80})),
  navigationAnchors:[],foregroundObjects:[]
 },map);
}
export function comparison(d,map){
 if(!map)return ['Не загружена схема предлагаемых координат Godot'];
 const regions=new Map(map.rooms.map(x=>[x.id,x.rect])),doors=new Map(map.doors.map(x=>[x.id,x.point]));
 const lines=['Сравнение с ПРОЕКТНОЙ геометрией Godot (не approved):'];
 for(const r of d.roomRegions){const delta=r.rect.map((x,i)=>Math.round(x-regions.get(r.id)[i]));lines.push(r.id+': Δ[X,Y,W,H] '+delta.join(', ')+(delta.some(x=>Math.abs(x)>12)?'  ⚠ REVIEW':''));}
 for(const o of d.doorPlacements){const delta=o.point.map((x,i)=>Math.round(x-doors.get(o.id)[i]));lines.push(o.id+': Δ[X,Y] '+delta.join(', ')+(Math.hypot(...delta)>12?'  ⚠ REVIEW':''));}
 lines.push('Нет автоматического изменения навигации, коллизий или campaign state.');
 return lines;
}
function el(tag,text,attrs={}){
 const e=document.createElement(tag);if(text!=null)e.textContent=text;
 for(const [key,value] of Object.entries(attrs))e[key]=value;
 return e;
}
function field(title,value,type='number'){
 const l=el('label',title,{className:'field'}),i=el('input',null,{type,value:String(value)});
 l.append(i);return [l,i];
}
export function installFirstFloorPanel({getProject,checkpoint,changed,getWorldReference,notify}){
 const panel=el('section',null,{className:'section first-floor-panel'});
 panel.append(el('div','Карта первого этажа · DRAFT v2',{className:'section-heading'}));
 panel.append(el('p','PNG и versioned manifest от Agent A/C. Существующий проект комнаты v1 сохраняется. Координаты и права на арт требуют проверки.',{className:'hint'}));
 const file=el('input',null,{type:'file',accept:'image/png'});
 const loadManifest=el('input',null,{type:'file',accept:'application/json,.json'});
 const imageButton=el('button','1. Загрузить PNG карты',{type:'button'}),jsonButton=el('button','Загрузить map manifest JSON',{type:'button'});
 const exportButton=el('button','Экспорт map draft JSON',{type:'button'}),validateButton=el('button','Проверить карту',{type:'button'});
 file.hidden=true;loadManifest.hidden=true;
 panel.append(imageButton,file,jsonButton,loadManifest,exportButton,validateButton);
 const status=el('pre','Нет draft; сначала загрузите PNG или map manifest.',{className:'calibration-report'});
 panel.append(status);
 const calibration=el('div',null),selector=el('select',null),edit=el('div',null);
 const preview=el('canvas',null,{width:320,height:320});
 preview.style.cssText='width:100%;height:auto;display:block;margin:8px 0;background:#161922;border:1px solid #62666b;touch-action:manipulation';
 const report=el('pre','',{className:'calibration-report'});
 panel.append(el('div','World-space калибровка (X, Y, W, H)',{className:'section-heading'}),calibration,el('div','Проверка комнат, дверей и anchors',{className:'section-heading'}),selector,edit,preview,report);
 document.querySelector('#showHallCalibration')?.closest('.section')?.after(panel);
 let image=null,selection='',lastDraft=null;
 const onError=e=>{status.textContent='ОШИБКА: '+(e?.message||String(e));notify('Карта не сохранена: '+(e?.message||e));};
 const draft=()=>getProject().firstFloorDraft;
 function update(fn){
  try{
   const next=fn(clone(draft()));
   validateFirstFloorDraft(next,getWorldReference());
   checkpoint();getProject().firstFloorDraft=next;changed();refresh();
  }catch(e){onError(e);}
 }
 function readImage(uri){image=new Image();image.onload=()=>paint();image.onerror=()=>{status.textContent='ОШИБКА: PNG не загружен. Проверьте source path / dataUri';};image.src=uri;}
 function refresh(){
  const d=draft();calibration.replaceChildren();edit.replaceChildren();selector.replaceChildren();preview.style.display=d?'block':'none';
  if(!d){status.textContent='Нет firstFloorDraft. Старые проекты v1 не изменены.';report.textContent='';return;}
  lastDraft=d;
  try{validateFirstFloorDraft(d,getWorldReference());status.textContent='DRAFT_ONLY · v2 · '+d.roomRegions.length+' комнат · '+d.doorPlacements.length+' дверей · '+d.navigationAnchors.length+' anchors. Для полного asset check нужен Python importer.';}
  catch(e){status.textContent='VALIDATION ERROR: '+e.message;}
  if(d.baseImage.dataUri)readImage(d.baseImage.dataUri);
  else{image=null;const url='../'+d.baseImage.path;readImage(url);}
  const [x,y,w,h]=d.calibration.worldRect,boxes=[x,y,w,h].map((v,i)=>field(['X','Y','W','H'][i],v));
  const b=el('button','Применить калибровку по двум углам',{type:'button'});
  boxes.forEach(([label])=>calibration.append(label));
  b.onclick=()=>{
   const v=boxes.map(([,input])=>Number(input.value));
   update(next=>{next.calibration.worldRect=v;const [ix,iy,iw,ih]=next.calibration.imageRect;next.calibration.controlPoints=[
    {pixel:[ix,iy],world:[v[0],v[1]]},{pixel:[ix+iw,iy+ih],world:[v[0]+v[2],v[1]+v[3]]}
   ];return next;});
  };calibration.append(b);
  const choices=[...d.roomRegions.map(o=>({name:'Комната: '+o.id,id:'r:'+o.id})),
   ...d.doorPlacements.map(o=>({name:'Дверь: '+o.id,id:'d:'+o.id})),
   ...d.navigationAnchors.map(o=>({name:'Anchor: '+o.id,id:'a:'+o.id}))];
  choices.forEach(ch=>selector.append(el('option',ch.name,{value:ch.id})));
  if(!choices.some(x=>x.id===selection))selection=choices[0]?.id||'';
  selector.value=selection;selector.onchange=()=>{selection=selector.value;renderSelection();paint();};
  renderSelection();
  report.textContent=comparison(d,getWorldReference()).join('\n');
  paint();
 }
 function renderSelection(){
  edit.replaceChildren();const d=draft();if(!d)return;
  const [kind,id]=selection.split(':');
  const list=kind==='r'?d.roomRegions:kind==='d'?d.doorPlacements:d.navigationAnchors;
  const item=list.find(x=>x.id===id);
  if(item){
   const key=kind==='r'?'rect':'point',values=item[key];
   const fields=values.map((v,i)=>field(['X','Y','W','H'][i],v));
   fields.forEach(([label])=>edit.append(label));
   const apply=el('button','Применить координаты',{type:'button'});
   apply.onclick=()=>update(next=>{const collection=kind==='r'?next.roomRegions:kind==='d'?next.doorPlacements:next.navigationAnchors;collection.find(x=>x.id===id)[key]=fields.map(([,f])=>Number(f.value));return next;});
   edit.append(apply);
  }
  const anchorName=field('Новый RM-NAV-ID','','text');
  const anchorRoom=el('select',null);
  for(const r of d.roomRegions)anchorRoom.append(el('option',r.id,{value:r.id}));
  const add=el('button','Добавить navigation anchor',{type:'button'});
  add.onclick=()=>update(next=>{
   const room=next.roomRegions.find(r=>r.id===anchorRoom.value);
   const [x,y,w,h]=room.rect;
   next.navigationAnchors.push({id:anchorName[1].value.trim(),roomId:room.id,point:[x+w/2,y+h/2]});
   selection='a:'+anchorName[1].value.trim();
   return next;
  });
  edit.append(anchorName[0],anchorRoom,add);
 }
 function paint(){
  const d=draft(),c=preview.getContext('2d'),s=preview.width;
  c.clearRect(0,0,s,s);if(!d)return;
  const [wx,wy,ww,wh]=d.calibration.worldRect,scale=Math.min(s/ww,s/wh),ox=(s-ww*scale)/2,oy=(s-wh*scale)/2;
  const pos=p=>[ox+(p[0]-wx)*scale,oy+(p[1]-wy)*scale];
  if(image?.complete&&image.naturalWidth){
   const [ix,iy,iw,ih]=d.calibration.imageRect;
   c.drawImage(image,ix,iy,iw,ih,ox,oy,ww*scale,wh*scale);
  }
  c.lineWidth=1.5;c.font='10px system-ui';
  for(const r of d.roomRegions){
   const [x,y]=pos(r.rect),w=r.rect[2]*scale,h=r.rect[3]*scale;
   c.strokeStyle=selection==='r:'+r.id?'#ffee88':'#6de1e4';
   c.strokeRect(x,y,w,h);c.fillStyle='#fff';c.fillText(r.id.replace('RM-ROOM-',''),x+2,y+11);
  }
  for(const door of d.doorPlacements){
   const [x,y]=pos(door.point);c.fillStyle=selection==='d:'+door.id?'#ffeb8d':'#f49b62';
   c.fillRect(x-3,y-3,6,6);
  }
  for(const a of d.navigationAnchors){
   const [x,y]=pos(a.point);c.fillStyle=selection==='a:'+a.id?'#ffeb8d':'#95f5a0';
   c.beginPath();c.arc(x,y,3,0,2*Math.PI);c.fill();
  }
  preview.onclick=e=>{
   const kind=selection[0];if(!['d','a'].includes(kind))return;
   const bounds=preview.getBoundingClientRect();
   const px=(e.clientX-bounds.left)*s/bounds.width,py=(e.clientY-bounds.top)*s/bounds.height;
   const point=[Math.round(wx+(px-ox)/scale),Math.round(wy+(py-oy)/scale)];
   update(next=>{const list=kind==='d'?next.doorPlacements:next.navigationAnchors;
    list.find(o=>o.id===selection.slice(2)).point=point;return next;});
  };
 }
 imageButton.onclick=()=>file.click();jsonButton.onclick=()=>loadManifest.click();
 file.onchange=async()=>{
  try{
   const f=file.files[0];if(!f)return;
   if(f.type!=='image/png'||f.size>20*1024*1024)throw Error('Нужен PNG <=20 MB');
   const bitmap=await createImageBitmap(f),size=[bitmap.width,bitmap.height];bitmap.close();
   const uri=await new Promise((resolve,reject)=>{const reader=new FileReader();reader.onload=()=>resolve(reader.result);reader.onerror=()=>reject(reader.error);reader.readAsDataURL(f);});
   const next=makeFirstFloorDraft(getWorldReference(),{pixelSize:size,dataUri:uri});
   checkpoint();getProject().firstFloorDraft=next;changed();selection='';refresh();
   notify('Создан firstFloorDraft v2: PNG сохранён в room project JSON.');
  }catch(e){onError(e);}finally{file.value='';}
 };
 loadManifest.onchange=async()=>{
  try{
   const f=loadManifest.files[0];if(!f)return;
   if(f.size>45*1024*1024)throw Error('JSON превышает 45 MB');
   const json=JSON.parse(await f.text());
   const source=json.kind==='raven_first_floor_draft_export'?json.source:(json.firstFloorDraft||json);
   const next=validateFirstFloorDraft(source,getWorldReference());
   checkpoint();getProject().firstFloorDraft=next;changed();selection='';refresh();
  }catch(e){onError(e);}finally{loadManifest.value='';}
 };
 exportButton.onclick=()=>{
  const d=draft();if(!d){onError(Error('Нет map draft'));return;}
  try{const checked=validateFirstFloorDraft(d,getWorldReference());const blob=new Blob([JSON.stringify(checked,null,2)],{type:'application/json'});
   const url=URL.createObjectURL(blob),a=el('a',null,{href:url,download:'rm-first-floor-draft-v2.json'});
   document.body.append(a);a.click();a.remove();setTimeout(()=>URL.revokeObjectURL(url),1500);
  }catch(e){onError(e);}
 };
 validateButton.onclick=()=>{refresh();notify(status.textContent.startsWith('DRAFT_ONLY')?'Map draft checked; gameplay unchanged':'Validation reported an error');};
 refresh();
 return {refresh};
}
