import {test} from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {validateVisualContract,contractFits,actorLocalFoot,visualInstances,splitSpriteDrawOrder,projectedUprightRect,seedPilotVisuals,spriteForAsset} from '../visual-contract.mjs';
import {toScreen} from '../projection.mjs';
import {exampleProject,object} from '../model.mjs';
import {validateCatalog,mergeCatalogAssets} from '../catalog.mjs';
const manifest=validateVisualContract(JSON.parse(fs.readFileSync(new URL('../reference/hall_visual_contract.json',import.meta.url),'utf8')));
const catalog=validateCatalog(JSON.parse(fs.readFileSync(new URL('../catalog/room-items.json',import.meta.url),'utf8')));
test('all seven Hall visual entries have stable refs and traceable committed sources',()=>{
 assert.equal(manifest.sprites.length,7);
 for(const sprite of manifest.sprites){
  assert.ok(catalog.items.some(a=>a.id===sprite.assetRefId));
  assert.ok(fs.existsSync(new URL('../reference/sprites/'+sprite.file,import.meta.url)));
  assert.ok(spriteForAsset(manifest,sprite.assetRefId));
 }
 assert.deepEqual(actorLocalFoot({roomId:'RM-ROOM-HALL'},manifest),{x:375,y:485});
});
test('new 700x690 drafts seed exact Godot coordinates and never rewrite legacy room',()=>{
 const p=exampleProject();
 mergeCatalogAssets(p,catalog);
 assert.equal(seedPilotVisuals(p,manifest,()=>null,()=>({})),0);
 assert.equal(p.objects.length,12);
 const blank=exampleProject();
 blank.width=700;blank.height=690;blank.objects=[];
 mergeCatalogAssets(blank,catalog);
 const n=seedPilotVisuals(blank,manifest,ref=>blank.assets.find(a=>a.assetRefId===ref),
   (a,rect)=>object(a,rect.x,rect.y,{w:rect.w,h:rect.h,layerId:a.layerId,assetRefId:a.assetRefId,state:a.states[0]}));
 assert.equal(n,7);
 assert.equal(blank.previewActorFoot.y,485);
 assert.equal(seedPilotVisuals(blank,manifest,()=>null,()=>({})),0);
 assert.deepEqual(blank.objects.find(o=>o.assetRefId==='RM-ASSET-HALL-002').x,75);
});
test('upright sprite foot anchor is not vertically squashed; actor occludes correctly by footY',()=>{
 const blank=exampleProject();blank.width=700;blank.height=690;blank.objects=[];
 mergeCatalogAssets(blank,catalog);
 seedPilotVisuals(blank,manifest,ref=>blank.assets.find(a=>a.assetRefId===ref),
   (a,r)=>object(a,r.x,r.y,{w:r.w,h:r.h,assetRefId:a.assetRefId}));
 const entries=visualInstances(blank,manifest);
 const view={x:32,y:18,scale:0.74};
 const clock=entries.find(x=>x.sprite.id==='clock');
 const r=projectedUprightRect(clock.object,view,toScreen);
 assert.ok(Math.abs(r.h-90*0.74)<0.001,'upright height unaffected by floor depth ratio');
 let order=splitSpriteDrawOrder(entries,485);
 assert.ok(order.behind.some(x=>x.sprite.id==='clock'));
 assert.ok(order.front.some(x=>x.sprite.id==='chair-left'));
 order=splitSpriteDrawOrder(entries,690);
 assert.equal(order.front.length,0);
 assert.equal(order.floor.length,1);
});
