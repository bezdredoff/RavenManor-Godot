import {test} from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {validateVisualContract,contractFits,actorLocalFoot,visualInstances,splitSpriteDrawOrder,projectedUprightRect,seedPilotVisuals,spriteForAsset,canPopulateHall,movePreviewActor} from '../visual-contract.mjs';
import {toScreen} from '../projection.mjs';
import {exampleProject,object} from '../model.mjs';
import {newRoomProject} from '../catalog.mjs';
import {gameRoomReference} from '../projection.mjs';
import {BUILTIN_HALL_VISUALS} from '../hall-pilot.mjs';
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

test('bundled synchronous fallback is exactly equal to published visual-contract JSON',()=>{
 assert.deepEqual(BUILTIN_HALL_VISUALS,manifest);
 assert.equal(validateVisualContract(BUILTIN_HALL_VISUALS).sprites.length,7);
});
test('real new-room flow: Godot dimensions, seven sprites, independent actor placement, and no duplicate fill',()=>{
 const map=JSON.parse(fs.readFileSync(new URL('../reference/season1_world_map.json',import.meta.url),'utf8'));
 const p=newRoomProject(exampleProject,()=> 'room-test','RM-ROOM-HALL');
 const reference=gameRoomReference(p,map);
 p.width=reference.width;p.height=reference.height;p.grid=25;
 mergeCatalogAssets(p,catalog);
 assert.ok(canPopulateHall(p,BUILTIN_HALL_VISUALS));
 const make=(asset,rect,sprite)=>object(asset,rect.x,rect.y,{w:rect.w,h:rect.h,layerId:asset.layerId,assetRefId:asset.assetRefId,state:sprite.state});
 const n=seedPilotVisuals(p,BUILTIN_HALL_VISUALS,ref=>p.assets.find(a=>a.assetRefId===ref),make);
 assert.equal(n,7);assert.equal(p.objects.length,7);
 assert.equal(canPopulateHall(p,BUILTIN_HALL_VISUALS),false);
 assert.equal(seedPilotVisuals(p,BUILTIN_HALL_VISUALS,()=>null,()=>null),0);
 assert.equal(p.objects.find(o=>o.assetRefId==='RM-ASSET-HALL-017').state,'clean');
 assert.deepEqual(movePreviewActor(p,BUILTIN_HALL_VISUALS,{x:240,y:390}),{x:240,y:390});
 assert.deepEqual(p.previewActorFoot,{x:240,y:390});
});
test('failed pilot asset lookup never leaves a half-filled room',()=>{
 const p=exampleProject();p.width=700;p.height=690;p.objects=[];
 const create=()=>({id:'broken',assetRefId:'x'});
 assert.throws(()=>seedPilotVisuals(p,BUILTIN_HALL_VISUALS,()=>({assetRefId:'RM-ASSET-HALL-010'}),create));
 assert.equal(p.objects.length,0);
 assert.throws(()=>movePreviewActor(p,BUILTIN_HALL_VISUALS,{x:900,y:400}));
});
test('published web entry wires unified character category and individual sidebars',()=>{
 const html=fs.readFileSync(new URL('../index.html',import.meta.url),'utf8');
 const js=fs.readFileSync(new URL('../app.mjs',import.meta.url),'utf8');
 assert.match(html,/id="populateHall"/);assert.match(html,/id="togglePalette"/);assert.match(html,/id="toggleInspector"/);assert.doesNotMatch(html,/id="moveActor"/);
 assert.match(js,/populateHallDraft\(project\)/);
 assert.match(js,/pilot\.file/);
 assert.match(js,/migrateLegacyCharacter/);assert.match(js,/gameRenderOrder/);assert.match(js,/toggleSidebar/);assert.match(html,/id="sheetKind"/);
});
