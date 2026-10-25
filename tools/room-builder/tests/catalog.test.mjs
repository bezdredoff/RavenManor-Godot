import {test} from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {ROOM_NAMES,validateCatalog,assetFromCatalog,mergeCatalogAssets,assetsForRoom,newRoomProject} from '../catalog.mjs';
import {exampleProject,placeObject,validateProject,uid} from '../model.mjs';

const catalog = JSON.parse(fs.readFileSync(new URL('../catalog/room-items.json', import.meta.url),'utf8'));

test('the season-one catalog covers 8 rooms and 120 proposed unique positions',()=>{
  assert.equal(validateCatalog(catalog),catalog);
  assert.equal(catalog.items.length,120);
  assert.equal(catalog.rooms.length,8);
  assert.equal(catalog.items.filter(x=>x.roomId==='RM-ROOM-HALL').length,19);
  assert.equal(new Set(catalog.items.map(x=>x.id)).size,120);
  assert.ok(catalog.items.every(x=>x.approval==='PROPOSED'));
  assert.equal(catalog.items.filter(x=>x.pilotImages?.length).length,7);
});

test('two independent armchairs share a reusable visual family, table is separate',()=>{
  const left=catalog.items.find(x=>x.id==='RM-ASSET-HALL-017');
  const right=catalog.items.find(x=>x.id==='RM-ASSET-HALL-018');
  const table=catalog.items.find(x=>x.id==='RM-ASSET-HALL-019');
  assert.equal(left.familyKey,right.familyKey);
  assert.notEqual(right.familyKey,table.familyKey);
  assert.equal(left.pilotImages[0],right.pilotImages[0]);
});

test('catalog merges non-destructively and stamps exact registry IDs and legal states',()=>{
  const project=exampleProject();
  const count=mergeCatalogAssets(project,catalog);
  assert.equal(count,120);
  assert.equal(mergeCatalogAssets(project,catalog),0);
  const clock=assetFromCatalog(catalog.items.find(x=>x.id==='RM-ASSET-HALL-002'));
  const added=placeObject(project,clock.id,250,250,clock.layerId,false);
  assert.equal(added.assetRefId,clock.assetRefId);
  assert.equal(added.state,'stopped');
  assert.equal(validateProject(project).objects.at(-1).assetRefId,'RM-ASSET-HALL-002');
  assert.ok(assetsForRoom(project,'RM-ROOM-HALL').some(a=>a.id==='catalog:RM-ASSET-HALL-017'));
  assert.ok(!assetsForRoom(project,'RM-ROOM-HALL').some(a=>a.id==='catalog:RM-ASSET-KITCHEN-001'));
});

test('room drafts do not pretend geometry or place unapproved items automatically',()=>{
  const p=newRoomProject(exampleProject,uid,'RM-ROOM-ARCHIVE');
  assert.equal(p.roomId,'RM-ROOM-ARCHIVE');
  assert.equal(p.objects.length,0);
  assert.match(p.provenance,/NOT approved/);
  assert.ok(ROOM_NAMES['RM-ROOM-ARCHIVE']);
});

test('rejects duplicate catalog IDs and forged approvals',()=>{
  const bad=structuredClone(catalog);bad.items[1].id=bad.items[0].id;
  assert.throws(()=>validateCatalog(bad));
  const other=structuredClone(catalog);other.items[0].approval='APPROVED';
  assert.throws(()=>validateCatalog(other));
});