import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {validateFirstFloorDraft,makeFirstFloorDraft,comparison} from '../first-floor.mjs';
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
