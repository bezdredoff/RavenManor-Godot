import {test} from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {GODOT_CAMERA_DEGREES,GODOT_DEFAULT_ZOOM,FLOOR_DEPTH_RATIO,toScreen,toWorld,worldDragDelta,fitProjectedRoom,projectedPixelHeight,gameRoomReference} from '../projection.mjs';
const source=JSON.parse(fs.readFileSync(new URL('../reference/season1_world_map.json',import.meta.url),'utf8'));
test('matches Godot current exact 65 degree transform and default game zoom',()=>{
 assert.equal(GODOT_CAMERA_DEGREES,65);
 assert.equal(GODOT_DEFAULT_ZOOM,0.74);
 assert.ok(Math.abs(FLOOR_DEPTH_RATIO-Math.sin(65*Math.PI/180))<1e-12);
 for(const mode of ['game','plan']){
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
