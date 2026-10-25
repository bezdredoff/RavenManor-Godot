export const SCHEMA_VERSION = 1;
export const CATEGORIES = ['all', 'tile', 'architecture', 'furniture', 'decor', 'interaction'];
export const CATEGORY_NAMES = {all:'Всё',tile:'Тайлы',architecture:'Архитектура',furniture:'Мебель',decor:'Декор',interaction:'Объекты'};
export const BASE_ASSETS = [
  ['stone','Плитка','tile',40,40,'#bcb7a8','▦'],
  ['wood','Паркет','tile',40,40,'#977660','▤'],
  ['wall','Обшивка','tile',40,40,'#51433e','▥'],
  ['stairs','Лестница','architecture',200,110,'#957b68','▥'],
  ['door','Двойная дверь','architecture',95,42,'#6f473e','▣'],
  ['arch','Арка','architecture',110,40,'#5b4c48','⌒'],
  ['armchair','Кресло','furniture',66,65,'#7d4653','♜'],
  ['sofa','Диван','furniture',150,64,'#775064','▰'],
  ['table','Столик','furniture',65,65,'#8d7055','●'],
  ['cabinet','Шкаф','furniture',120,55,'#765740','▤'],
  ['rug','Ковёр','decor',170,260,'#793940','▥'],
  ['clock','Напольные часы','interaction',46,65,'#88643e','◷'],
  ['portrait','Портрет','decor',70,50,'#a37b55','▧'],
  ['lamp','Лампа','decor',35,35,'#be9e61','✦'],
  ['plant','Кашпо','decor',46,46,'#4f7559','✿'],
  ['hotspot','Hotspot','interaction',42,42,'#4c8dba','◎']
].map(([id,label,kind,w,h,color,symbol]) => ({id,label,kind,w,h,color,symbol}));

export function uid(prefix='o') { return `${prefix}-${globalThis.crypto?.randomUUID?.() || Math.random().toString(36).slice(2)}`; }
export function clone(value) { return JSON.parse(JSON.stringify(value)); }
export function snap(v, grid=40) { return Math.round(v/grid)*grid; }
export function bounds(v,lo,hi) { return Math.max(lo,Math.min(hi,v)); }
export function object(asset, x, y, extra={}) {
  return {id:uid(),assetId:asset.id,x,y,w:asset.w,h:asset.h,rotation:0,layerId:asset.kind==='tile'?'floor':'objects',state:'default',hotspotId:'',...extra};
}
export function exampleProject() {
  const assets=clone(BASE_ASSETS);
  const get=id=>assets.find(a=>a.id===id);
  const objects=[
    object(get('stairs'),135,100,{w:245,h:114,rotation:0,layerId:'architecture',assetRefId:'RM-ASSET-HALL-001'}),
    object(get('stairs'),620,100,{w:245,h:114,layerId:'architecture',assetRefId:'RM-ASSET-HALL-001'}),
    object(get('door'),448,84,{w:106,h:52,layerId:'architecture',assetRefId:'RM-ASSET-HALL-003'}),
    object(get('clock'),140,280,{assetRefId:'RM-ASSET-HALL-002',state:'stopped',hotspotId:'RM-HS-001'}),
    object(get('rug'),415,290,{w:170,h:350,layerId:'floor',assetRefId:'RM-ASSET-HALL-010'}),
    object(get('armchair'),112,434,{assetRefId:'RM-ASSET-HALL-017'}),
    object(get('armchair'),238,444,{assetRefId:'RM-ASSET-HALL-018'}),
    object(get('table'),184,526,{assetRefId:'RM-ASSET-HALL-019'}),
    object(get('portrait'),757,255,{assetRefId:'RM-ASSET-HALL-006'}),
    object(get('lamp'),835,340),
    object(get('plant'),760,515),
    object(get('door'),448,715,{w:106,h:42,layerId:'architecture'})
  ];
  return {schemaVersion:SCHEMA_VERSION,id:uid('room'),title:'Парадный холл — черновик',roomId:'RM-ROOM-HALL',width:1000,height:800,grid:40,assets,layers:[
    {id:'floor',name:'Пол и ковры',visible:true,locked:false},
    {id:'architecture',name:'Архитектура',visible:true,locked:false},
    {id:'objects',name:'Мебель и декор',visible:true,locked:false},
    {id:'foreground',name:'Передний план',visible:true,locked:false}
  ],objects,anchors:[{id:'RM-NAV-HALL-SPAWN',x:500,y:660,kind:'safe'},{id:'RM-NAV-HS-001',x:160,y:360,kind:'interaction',hotspotId:'RM-HS-001'}],provenance:'Illustrative layout only. Not approved geometry.'};
}
export function validateProject(input) {
  if(!input || typeof input!=='object' || input.schemaVersion!==SCHEMA_VERSION || !Array.isArray(input.assets) || !Array.isArray(input.layers) || !Array.isArray(input.objects)) throw new Error('Неподдерживаемый формат проекта');
  const p=clone(input);
  if(typeof p.title!=='string' || typeof p.roomId!=='string' || !/^RM-ROOM-[A-Z0-9-]+$/.test(p.roomId) || !Number.isFinite(p.width)||!Number.isFinite(p.height)||p.width<100||p.height<100||p.width>8000||p.height>8000)throw new Error('Некорректные размеры или roomId');
  p.grid=bounds(Math.round(Number(p.grid)||40),8,256);
  if(p.assets.length>2000||p.layers.length>50||p.objects.length>20000)throw new Error('Слишком большой проект');
  const layerIds=new Set(p.layers.map(l=>l.id)); const assets=new Set(p.assets.map(a=>a.id));
  if(layerIds.size!==p.layers.length||assets.size!==p.assets.length)throw new Error('Повторяющиеся ID');
  for(const a of p.assets){if(typeof a.id!=='string'||typeof a.label!=='string'||typeof a.kind!=='string'|| !Number.isFinite(a.w)||!Number.isFinite(a.h)||a.w<=0||a.h<=0||a.w>8000||a.h>8000)throw new Error('Некорректный ассет'); if(a.image && (typeof a.image!=='string'|| !/^data:image\/(png|jpeg|webp);base64,[a-zA-Z0-9+/=]+$/.test(a.image)))throw new Error('Поддерживаются только встроенные PNG/JPEG/WebP'); }
  for(const o of p.objects){if(!assets.has(o.assetId)||!layerIds.has(o.layerId)||!['x','y','w','h','rotation'].every(k=>Number.isFinite(o[k]))||o.w<=0||o.h<=0||o.w>8000||o.h>8000||typeof o.id!=='string')throw new Error('Некорректный объект');}
  p.anchors=Array.isArray(p.anchors)?p.anchors:[];
  return p;
}
export function pointInObject(x,y,o){const ang=-(o.rotation||0)*Math.PI/180,dx=x-(o.x+o.w/2),dy=y-(o.y+o.h/2); const rx=dx*Math.cos(ang)-dy*Math.sin(ang),ry=dx*Math.sin(ang)+dy*Math.cos(ang);return Math.abs(rx)<=o.w/2 && Math.abs(ry)<=o.h/2;}
export function topObjectAt(p,x,y){const order=new Map(p.layers.map((l,i)=>[l.id,i]));return [...p.objects].filter(o=>p.layers.find(l=>l.id===o.layerId)?.visible && !p.layers.find(l=>l.id===o.layerId)?.locked).sort((a,b)=>(order.get(b.layerId)||0)-(order.get(a.layerId)||0)).find(o=>pointInObject(x,y,o))||null;}
export function placeObject(p,assetId,x,y,layerId,gridSnap=true){const asset=p.assets.find(a=>a.id===assetId),layer=p.layers.find(l=>l.id===layerId);if(!asset||!layer||layer.locked) return null; const ox=gridSnap?snap(x-asset.w/2,p.grid):x-asset.w/2,oy=gridSnap?snap(y-asset.h/2,p.grid):y-asset.h/2;
  if(asset.kind==='tile'&&p.objects.some(o=>o.assetId===assetId&&o.layerId===layerId&&o.x===ox&&o.y===oy))return null;
  const o=object(asset,ox,oy,{layerId,assetRefId:asset.assetRefId||'',state:asset.states?.[0]||'default',familyKey:asset.familyKey||''});p.objects.push(o);return o;
}