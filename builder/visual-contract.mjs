/** Shared noncanonical Hall preview manifest. Godot reads identical JSON. */
export function validateVisualContract(data){
 if(data?.schemaVersion!==1||data.roomId!=='RM-ROOM-HALL'||data.status!=='PILOT_NOT_APPROVED'||data.cameraElevation!==65)throw Error('Unsupported Hall visual contract');
 if(!Array.isArray(data.roomWorldRect)||data.roomWorldRect.length!==4||!Array.isArray(data.sprites)||!data.actor)throw Error('Malformed Hall visual contract');
 const ids=new Set(),assets=new Set();
 for(const item of data.sprites){
  if(ids.has(item.id)||assets.has(item.assetRefId)||!/^RM-ASSET-HALL-\d{3}$/.test(item.assetRefId)||!['floor','upright'].includes(item.mode)||!Array.isArray(item.rect)||item.rect.length!==4||!item.rect.every(Number.isFinite)||item.rect[2]<=0||item.rect[3]<=0||!/^[a-z_]+\.png$/.test(item.file))throw Error('Invalid or duplicate Hall visual '+item?.id);
  ids.add(item.id);assets.add(item.assetRefId);
 }
 if(data.sprites.length!==7||!Array.isArray(data.actor.foot)||data.actor.height!==90)throw Error('Hall preview manifest incomplete');
 return data;
}
export function spriteForAsset(contract,assetRefId){
 return contract?.sprites.find(item=>item.assetRefId===assetRefId)||null;
}
export function localVisualRect(sprite,contract){
 const [rx,ry]=contract.roomWorldRect,[x,y,w,h]=sprite.rect;
 return {x:x-rx,y:y-ry,w,h};
}
export function contractFits(project,contract){
 return !!contract&&project.roomId===contract.roomId&&project.width===contract.roomWorldRect[2]&&project.height===contract.roomWorldRect[3];
}
export function actorLocalFoot(project,contract){
 const [x,y]=contract.actor.foot;
 return {x:x-contract.roomWorldRect[0],y:y-contract.roomWorldRect[1]};
}
export function previewActorFoot(project,contract){
 const point=project.previewActorFoot;
 return point&&Number.isFinite(point.x)&&Number.isFinite(point.y)?point:actorLocalFoot(project,contract);
}
export function visualInstances(project,contract){
 const lookup=new Map(contract.sprites.map(s=>[s.assetRefId,s]));
 return project.objects.flatMap(o=>{
  const sprite=lookup.get(o.assetRefId);
  return sprite?[{object:o,sprite,footY:o.y+o.h}]:[];
 });
}
export function splitSpriteDrawOrder(instances,actorFootY){
 const floor=instances.filter(x=>x.sprite.mode==='floor');
 const upright=instances.filter(x=>x.sprite.mode==='upright').sort((a,b)=>a.footY-b.footY||(a.object.id<b.object.id?-1:1));
 return {floor,behind:upright.filter(x=>x.footY<=actorFootY),front:upright.filter(x=>x.footY>actorFootY)};
}
export function projectedUprightRect(object,view,projectionFn){
 const foot=projectionFn({x:object.x+object.w/2,y:object.y+object.h},view,'game');
 return {x:foot.x-object.w*view.scale/2,y:foot.y-object.h*view.scale,w:object.w*view.scale,h:object.h*view.scale};
}
export function actorScreenRect(foot,actor,view,projectionFn){
 const p=projectionFn(foot,view,'game'),height=actor.height*view.scale;
 const width=height*(actor.frameRect[2]/actor.frameRect[3]);
 return {x:p.x-width/2,y:p.y-height,w:width,h:height};
}
/** Called only for an explicitly new, blank Hall draft; never rewrite existing data. */
export function seedPilotVisuals(project,contract,assetByRef,createInstance){
 if(!contractFits(project,contract)||project.objects.length) return 0;
 for(const sprite of contract.sprites){
  const asset=assetByRef(sprite.assetRefId);
  if(!asset)throw Error('Missing Hall catalog entry '+sprite.assetRefId);
  const rect=localVisualRect(sprite,contract);
  project.objects.push(createInstance(asset,rect,sprite));
 }
 project.previewActorFoot=actorLocalFoot(project,contract);
 project.visualContractVersion=1;
 project.provenance='Experimental shared Godot Hall sprite-layout preview; positions/PNG states NOT approved.';
 return contract.sprites.length;
}
