import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {validateFirstFloorDraft,makeFirstFloorDraft,comparison,adaptFirstFloorArtManifestV1} from '../first-floor.mjs';
import {validateProject,exampleProject} from '../model.mjs';

const file=new URL('../../../tests/fixtures/first_floor_draft_valid.json',import.meta.url);
const fixture=JSON.parse(readFileSync(file,'utf8'));
const map=JSON.parse(readFileSync(new URL('../reference/season1_world_map.json',import.meta.url),'utf8'));
const copy=()=>JSON.parse(JSON.stringify(fixture.firstFloorDraft));

test('legacy schemaVersion=1 room projects open unchanged',()=>{
 const old=exampleProject();
 assert.equal(validateProject(old).schemaVersion,1);
 assert.equal(validateProject(old).firstFloorDraft,undefined);
});
test('valid schema v2 is an opt-in extension of existing v1 project',()=>{
 const full=structuredClone(fixture);
 assert.equal(validateProject(full).firstFloorDraft.schemaVersion,2);
 assert.equal(validateFirstFloorDraft(full.firstFloorDraft,map).doorPlacements.length,11);
});
test('new draft seeds provisional reference without approved geometry claims',()=>{
 const original=copy();
 const result=makeFirstFloorDraft(map,original.baseImage);
 assert.equal(result.schemaVersion,2);
 assert.deepEqual(result.roomRegions[0].rect,map.rooms[0].rect);
 assert.equal(result.provenance.includes('not approved'),true);
 assert.ok(comparison(result,map).some(x=>x.includes('геометрией Godot')));
});
test('schema mismatch, corrupted dataURI and invalid dimensions rejected',()=>{
 const bad=copy();bad.schemaVersion=4;
 assert.throws(()=>validateFirstFloorDraft(bad,map),/schemaVersion/);
 const b=copy();b.baseImage.dataUri='broken';
 assert.throws(()=>validateFirstFloorDraft(b,map),/baseImage/);
 const c=copy();c.calibration.imageRect=[0,0,20,20];
 assert.throws(()=>validateFirstFloorDraft(c,map),/calibration/);
});
test('unknown room or door IDs fail instead of remapping',()=>{
 const a=copy();a.roomRegions[0].id='RM-ROOM-NOT-FOUND';
 assert.throws(()=>validateFirstFloorDraft(a,map),/Неизвестный room ID/);
 const b=copy();b.doorPlacements[0].id='RM-DOOR-NOT-FOUND';
 assert.throws(()=>validateFirstFloorDraft(b,map),/Неизвестный door ID/);
});
test('duplicates and invalid placement are diagnosed',()=>{
 const a=copy();a.doorPlacements.push(structuredClone(a.doorPlacements[0]));
 assert.throws(()=>validateFirstFloorDraft(a,map),/повторяющийся ID/);
 const b=copy();b.doorPlacements[0].point=[20,20];
 assert.throws(()=>validateFirstFloorDraft(b,map),/Некорректное положение двери/);
});
test('mismatched calibration checkpoints rejected',()=>{
 const a=copy();a.calibration.controlPoints[1].world=[100,200];
 assert.throws(()=>validateFirstFloorDraft(a,map),/Несовпадающая calibration/);
});
test('missing/invalid foreground references and impossible pivots rejected',()=>{
 const a=copy();
 a.foregroundObjects=[{id:'RM-FG-ONE',roomId:'RM-ROOM-HALL',position:[900,700],
  size:[64,96],pivot:[32,200],assetPath:'assets/raven/hall/generated_pilot/props/grandfather_clock.png',occlusion:{mode:'foot_y'}}];
 assert.throws(()=>validateFirstFloorDraft(a,map),/floor-contact pivot/);
 a.foregroundObjects[0].pivot=[32,96];
 a.foregroundObjects[0].assetPath='../../private.png';
 assert.throws(()=>validateFirstFloorDraft(a,map),/PNG путь/);
});
test('duplicate navigation points fail',()=>{
 const a=copy();
 a.navigationAnchors.push({...a.navigationAnchors[0],id:'RM-NAV-SECOND'});
 assert.throws(()=>validateFirstFloorDraft(a,map),/Дублирующиеся navigation points/);
});

test('real Agent A v1 manifest with owner PNG uploads into unregistered v2 and survives roundtrip',async()=>{
 const art=JSON.parse(readFileSync(new URL('../../../tests/fixtures/first_floor_art_A_v1_unapproved.json',import.meta.url),'utf8'));
 const png=readFileSync(new URL('../../../a_detailed_top_down_isometric_game_map_illustratio.png',import.meta.url));
 const width=png.readUInt32BE(16),height=png.readUInt32BE(20);
 const uri='data:image/png;base64,'+png.toString('base64');
 const original=structuredClone(art);
 const result=await adaptFirstFloorArtManifestV1(art,map,{pixelSize:[width,height],dataUri:uri});
 assert.equal(result.registration.status,'unresolved');
 assert.equal(result.registration.navigationAllowed,false);
 assert.deepEqual(result.calibration.controlPoints,[]);
 assert.equal(result.baseImage.pixelSize[0],width);
 assert.equal(result.baseImage.pixelSize[1],height);
 assert.deepEqual(result.producerManifest,original);
 assert.deepEqual(art,original);
 assert.equal(result.navigationAnchors.length,0);
 assert.equal(result.foregroundObjects.length,0);
 assert.equal(result.doorPlacements.length,11);
 assert.deepEqual(validateFirstFloorDraft(JSON.parse(JSON.stringify(result)),map),result);
});
test('Agent A v1 rejects wrong PNG, duplicate IDs and false raster registration',async()=>{
 const art=JSON.parse(readFileSync(new URL('../../../tests/fixtures/first_floor_art_A_v1_unapproved.json',import.meta.url),'utf8'));
 const png=readFileSync(new URL('../../../a_detailed_top_down_isometric_game_map_illustratio.png',import.meta.url));
 const base={pixelSize:[png.readUInt32BE(16),png.readUInt32BE(20)],dataUri:'data:image/png;base64,'+png.toString('base64')};
 const invalid=structuredClone(art);invalid.source.gitBlobSha='0'.repeat(40);
 await assert.rejects(()=>adaptFirstFloorArtManifestV1(invalid,map,base),/Git blob/);
 const duplicated=structuredClone(art);duplicated.doors.push(structuredClone(duplicated.doors[0]));
 await assert.rejects(()=>adaptFirstFloorArtManifestV1(duplicated,map,base),/дублирующийся/);
 const wrongPlan=structuredClone(art);wrongPlan.coordinateSystems.worldPlanToSourcePixel.matrix=[1,0,0,1];
 await assert.rejects(()=>adaptFirstFloorArtManifestV1(wrongPlan,map,base),/неподтверждённое/);
});
