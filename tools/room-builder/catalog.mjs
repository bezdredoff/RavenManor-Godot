/** Production-catalog adapter. Never treats planning rows as approved or game-ready art. */
export const ROOM_NAMES = Object.freeze({
  'RM-ROOM-ENTRY':'Вход и крыльцо',
  'RM-ROOM-HALL':'Парадный холл',
  'RM-ROOM-CORRIDOR':'Жилой коридор',
  'RM-ROOM-BEDROOM':'Спальня Эвелин',
  'RM-ROOM-BATHROOM':'Ванная (виньетка)',
  'RM-ROOM-KITCHEN':'Кухня',
  'RM-ROOM-ARCHIVE':'Библиотека / архив',
  'RM-ROOM-CONSERVATORY':'Оранжерея'
});
const MAP = {
  base:['architecture','floor',110,55,'#b7afa0','▦'],
  architecture:['architecture','architecture',130,65,'#70616a','▥'],
  door:['architecture','architecture',85,38,'#846c59','▣'],
  portal:['architecture','architecture',110,42,'#806877','⌒'],
  furniture:['furniture','objects',90,65,'#8d635b','▰'],
  restoration:['furniture','objects',98,72,'#996d65','◈'],
  dressing:['decor','objects',52,42,'#89715e','✿'],
  light:['decor','objects',38,40,'#c1a16c','✦'],
  occluder:['architecture','foreground',75,48,'#715c75','▤'],
  interactive:['interaction','objects',55,52,'#9e8366','◎'],
  story:['interaction','objects',55,45,'#ad836f','✧'],
  clue:['interaction','objects',38,35,'#9c8c69','◇']
};
export function validateCatalog(data){
  if(!data || data.schemaVersion!==1 || !Array.isArray(data.items) || !Array.isArray(data.rooms)) throw new Error('Некорректная версия производственного каталога');
  const ids=new Set();
  for(const item of data.items){
    if(!/^RM-ASSET-[A-Z0-9-]+$/.test(item.id)||ids.has(item.id)||!ROOM_NAMES[item.roomId]||typeof item.name!=='string'||!Array.isArray(item.states)||!item.states.length||!MAP[item.layer]||item.approval!=='PROPOSED'||!['P1','P2'].includes(item.priority)||typeof item.familyKey!=='string'||!Number.isInteger(item.plannedInstances)||item.plannedInstances<1)throw new Error('Некорректная запись каталога: '+String(item.id));
    if(!['pilot-reference-only','not-generated'].includes(item.artStatus)
       ||!['requires-review','not-applicable'].includes(item.rightsStatus)
       ||!item.spatial||Object.values(item.spatial).some(x=>x!==null)
       ||!Array.isArray(item.stateAssets)||item.stateAssets.length!==item.states.length
       ||item.stateAssets.some((a,i)=>a.state!==item.states[i]||a.renderMethod!=='undecided'||a.approved!==false))
      throw new Error('Неутверждённые производственные поля должны оставаться явными: '+item.id);
    ids.add(item.id);
  }
  const totals=new Map(data.rooms.map(r=>[r.id,r.count]));
  if(totals.size!==Object.keys(ROOM_NAMES).length)throw new Error('Некорректный список комнат');
  for(const id of Object.keys(ROOM_NAMES))if(data.items.filter(i=>i.roomId===id).length!==totals.get(id))throw new Error('Количество объектов в комнате не совпадает: '+id);
  return data;
}
export function assetFromCatalog(item){
  const [kind,layerId,w,h,color,symbol]=MAP[item.layer];
  return {id:'catalog:'+item.id,label:item.name,kind,w,h,color,symbol,layerId,
    assetRefId:item.id,roomId:item.roomId,states:[...item.states],
    familyKey:item.familyKey,plannedInstances:item.plannedInstances,
    productionPriority:item.priority,approval:item.approval,placementAnchor:item.anchor,
    pilotImages:item.pilotImages||[],source:'production-register',
    spatial:item.spatial||null,stateAssets:item.stateAssets||[],rightsStatus:item.rightsStatus||'not-applicable',
    artStatus:(item.pilotImages||[]).length?'experimental PNG (not approved)':'not generated / placeholder'};
}
export function mergeCatalogAssets(project,catalog){
  validateCatalog(catalog);
  const ids=new Set(project.assets.map(a=>a.id));let added=0;
  for(const item of catalog.items){const asset=assetFromCatalog(item);if(!ids.has(asset.id)){project.assets.push(asset);ids.add(asset.id);added++;}
    else {const old=project.assets.find(a=>a.id===asset.id);
      // Refresh registry metadata, never replace user-imported image bytes.
      for(const key of ['label','kind','symbol','color','assetRefId','roomId','states','familyKey','plannedInstances','productionPriority','approval','placementAnchor','pilotImages','artStatus','spatial','stateAssets','rightsStatus'])old[key]=asset[key];}
  }
  return added;
}
export function assetsForRoom(project,roomId){return project.assets.filter(a=>!a.roomId||a.roomId===roomId);}
export function newRoomProject(exampleProject,uid,roomId){
  if(!ROOM_NAMES[roomId])throw new Error('Неизвестная комната');
  const p=exampleProject();p.id=uid('room');p.title=ROOM_NAMES[roomId]+' — черновик';p.roomId=roomId;p.objects=[];p.anchors=[];
  p.provenance='New authoring draft; room dimensions, object positions and navigation are NOT approved.';
  return p;
}

export function migrateLegacyHallReferences(p){
 // Only exact v0.1 demo positions; never rewrite deliberate player placements.
 if(p.roomId!=='RM-ROOM-HALL')return 0;
 const legacy=[['armchair',112,434,'RM-ASSET-HALL-017'],['armchair',238,444,'RM-ASSET-HALL-018']];
 let changes=0;
 for(const [assetId,x,y,id] of legacy){const o=p.objects.find(o=>o.assetId===assetId&&o.x===x&&o.y===y&&(o.assetRefId==='RM-ASSET-HALL-007'||(id==='RM-ASSET-HALL-018'&&!o.assetRefId)));if(o){o.assetRefId=id;changes++;}}
 const table=p.objects.find(o=>o.assetId==='table'&&!o.assetRefId&&o.x===184&&o.y===526);
 if(table){table.assetRefId='RM-ASSET-HALL-019';changes++;}
 return changes;
}

/** Keep personally imported sprites usable across room-specific local drafts. */
export function mergeUserAssets(target,source){
 const ids=new Set(target.assets.map(a=>a.id));let added=0;
 for(const a of source.assets||[]){if(a.source==='local-import'&&!ids.has(a.id)){target.assets.push(structuredClone(a));ids.add(a.id);added++;}}
 return added;
}

/** Serialize async IndexedDB writes: prevent a previous-room save racing a new-room save. */
export function createSerialWriter(write){
 let tail=Promise.resolve();
 return snapshot=>{const pending=tail.catch(()=>{}).then(()=>write(snapshot));tail=pending.catch(()=>{});return pending;};
}