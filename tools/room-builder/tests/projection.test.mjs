import {test} from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {GODOT_CAMERA_DEGREES,GODOT_DEFAULT_ZOOM,FLOOR_DEPTH_RATIO,toScreen,toWorld,worldDragDelta,fitProjectedRoom,projectedPixelHeight,gameRoomReference,hallCalibrationReview} from '../projection.mjs';
const source=JSON.parse(fs.readFileSync(new URL('../reference/season1_world_map.json',import.meta.url),'utf8'));
const measurements=JSON.parse(fs.readFileSync(new URL('../reference/hall_render_calibration.json',import.meta.url),'utf8'));
import {BUILTIN_HALL_VISUALS} from '../hall-pilot.mjs';
test('matches Godot current exact 65 degree transform and default game zoom',()=>{
 assert.equal(GODOT_CAMERA_DEGREES,65);
 assert.equal(GODOT_DEFAULT_ZOOM,0.74);
 assert.ok(Math.abs(FLOOR_DEPTH_RATIO-Math.sin(65*Math.PI/180))<1e-12);
 for(const mode of ['game','room','plan']){
  for(const p of [{x:0,y:0},{x:350,y:345},{x:700,y:690},{x:-40,y:35}]){
   const viewport={x:71,y:-34,scale:0.74};
   const mapped=toScreen(p,viewport,mode),back=toWorld(mapped,viewport,mode);
   assert.ok(Math.abs(back.x-p.x)<1e-8&&Math.abs(back.y-p.y)<1e-8);
  }
 }
});
test('dragging/picking are exact inverses even at small fractional zoom',()=>{
 for(const zoom of [0.18,0.68,0.74,0.8,1.6]){
  for(const mode of ['game','plan']){
   const d=worldDragDelta(24,-36,zoom,mode);
   assert.ok(Math.abs(d.x*zoom-24)<1e-9);
   assert.ok(Math.abs(d.y*zoom*(mode==='game'?FLOOR_DEPTH_RATIO:1)+36)<1e-9);
  }
  const d=worldDragDelta(24,-36,zoom,'room'),screen=toScreen(d,{x:0,y:0,scale:zoom},'room');
  assert.ok(Math.abs(screen.x-24)<1e-9&&Math.abs(screen.y+36)<1e-9);
 }
});
test('projected fit and PNG dimensions respect floor compression',()=>{
 const v=fitProjectedRoom(700,690,390,844,'game');
 assert.ok(v.scale*700<=390-41);
 assert.ok(v.scale*690*FLOOR_DEPTH_RATIO<=844-41);
 assert.equal(projectedPixelHeight(690,'plan'),690);
 assert.equal(projectedPixelHeight(690,'game'),Math.ceil(690*FLOOR_DEPTH_RATIO));
});
test('reference Hall anchors are exactly derived from the current Godot world map',()=>{
 const p={roomId:'RM-ROOM-HALL',width:700,height:690};
 const r=gameRoomReference(p,source);
 assert.deepEqual(r.origin,{x:500,y:150});
 assert.equal(r.aligned,true);
 assert.deepEqual(r.doors.find(x=>x.id==='RM-DOOR-HALL-ARCHIVE').x,0);
 assert.deepEqual(r.doors.find(x=>x.id==='RM-DOOR-HALL-CORRIDOR').x,700);
 assert.deepEqual(r.doors.find(x=>x.id==='RM-DOOR-ENTRY-HALL').y,690);
 assert.deepEqual(r.props.find(x=>x.id==='RM-ASSET-HALL-CLOCK'),{id:'RM-ASSET-HALL-CLOCK',x:75,y:310,w:60,h:90});
 assert.equal(gameRoomReference({...p,width:1000,height:800},source).aligned,false);
});

test('draft calibration references exactly mirror the measured Godot Hall source',()=>{
 const canonical=JSON.parse(fs.readFileSync(new URL('../../../data/raven/hall_render_calibration.json',import.meta.url),'utf8'));
 assert.deepEqual(measurements,canonical);
 const published=JSON.parse(fs.readFileSync(new URL('../../../builder/reference/hall_render_calibration.json',import.meta.url),'utf8'));
 assert.deepEqual(published,canonical);
});
test('Hall discrepancies report painted doors, staircases and pilot prop envelopes without editing draft',()=>{
 const origin=BUILTIN_HALL_VISUALS.roomWorldRect;
 const p={roomId:'RM-ROOM-HALL',width:700,height:690,
  objects:BUILTIN_HALL_VISUALS.sprites.map((s,i)=>({id:'pilot-'+i,assetRefId:s.assetRefId,
   x:s.rect[0]-origin[0],y:s.rect[1]-origin[1],w:s.rect[2],h:s.rect[3]}))};
 const before=JSON.stringify(p);
 const report=hallCalibrationReview(p,source,measurements,BUILTIN_HALL_VISUALS);
 assert.equal(report.ready,true,report.reason);
 assert.equal(report.doors.length,5);
 const archive=report.doors.find(d=>d.id==='RM-DOOR-HALL-ARCHIVE');
 assert.deepEqual([archive.dx,archive.dy],[27,-207]);
 assert.ok(archive.needsReview);
 const corridor=report.doors.find(d=>d.id==='RM-DOOR-HALL-CORRIDOR');
 assert.deepEqual([corridor.dx,corridor.dy],[-27,-242]);
 const entry=report.doors.find(d=>d.id==='RM-DOOR-ENTRY-HALL');
 assert.equal(entry.distance,7);assert.equal(entry.needsReview,false);
 const left=report.stairs.find(s=>s.id==='RM-ASSET-HALL-STAIRS-L');
 assert.deepEqual([left.dx,left.dy,left.dw,left.dh],[3,-40,-6,39]);
 assert.equal(report.stairs.length,2);
 assert.equal(report.items.length,3,'clock, console and gallery have single pilot sprite / map prop refs');
 assert.equal(report.items.filter(x=>x.needsReview).length,0);
 assert.equal(report.seating.footprints.length,3);
 assert.equal(report.seating.legacy.id,'RM-ASSET-HALL-SEATS');
 assert.equal(report.seating.status,'CANDIDATE_NOT_APPROVED');
 assert.equal(JSON.stringify(p),before,'report must not mutate room objects, IDs or geometry');
});
test('Hall calibration is withheld for mismatched room or stale canonical map anchors',()=>{
 const p={roomId:'RM-ROOM-HALL',width:700,height:690,objects:[]};
 assert.equal(hallCalibrationReview({...p,width:1000},source,measurements,BUILTIN_HALL_VISUALS).ready,false);
 const stale=structuredClone(source);
 stale.doors.find(d=>d.id==='RM-DOOR-HALL-ARCHIVE').point[1]+=10;
 const result=hallCalibrationReview(p,stale,measurements,BUILTIN_HALL_VISUALS);
 assert.equal(result.ready,false);
 assert.match(result.reason,/устарели/);
 const bad=structuredClone(measurements);
 bad.openings[1].id=bad.openings[0].id;
 assert.equal(hallCalibrationReview(p,source,bad,BUILTIN_HALL_VISUALS).ready,false);
});
test('Hall prop envelope review detects changed draft placement without changing canonical furniture',()=>{
 const asset=BUILTIN_HALL_VISUALS.sprites.find(s=>s.mapPropId==='RM-ASSET-HALL-CLOCK');
 const p={roomId:'RM-ROOM-HALL',width:700,height:690,objects:[
  {id:'moved-clock',assetRefId:asset.assetRefId,x:175,y:310,w:60,h:90}
 ]};
 const result=hallCalibrationReview(p,source,measurements,BUILTIN_HALL_VISUALS);
 assert.equal(result.ready,true);
 const clock=result.items.find(i=>i.id==='RM-ASSET-HALL-CLOCK');
 assert.equal(clock.dx,100);assert.equal(clock.needsReview,true);
 assert.deepEqual(clock.mapRect,{id:'RM-ASSET-HALL-CLOCK',x:75,y:310,w:60,h:90});
});
