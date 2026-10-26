import test from 'node:test';
import assert from 'node:assert/strict';
import {exampleProject,validateProject} from '../model.mjs';
import {normalizeWall,nearestWall,solidWallRuns,endpointTopology,validateWalls,wallBand,WALL_BAND_HEIGHT,isPortal} from '../wall-tools.mjs';

test('wall strokes snap orthogonally and derive connected corners',()=>{
 const first={id:'w1',...normalizeWall({x:2,y:3},{x:103,y:22},25),style:'grand',thickness:18};
 const second={id:'w2',...normalizeWall({x:100,y:0},{x:92,y:150},25),style:'grand',thickness:18};
 assert.deepEqual([first.ax,first.ay,first.bx,first.by],[0,0,100,0]);
 assert.equal(endpointTopology([first,second],first,false),'corner');
});

test('openings cut deterministic solid wall runs and nearest placement clamps',()=>{
 const wall={id:'wall',ax:0,ay:0,bx:200,by:0,style:'residential',thickness:18};
 const found=nearestWall([wall],{x:101,y:12},25);assert.equal(found.wall.id,'wall');assert.ok(Math.abs(found.t-.505)<.001);
 assert.deepEqual(solidWallRuns(wall,[{id:'door',wallId:'wall',kind:'door',width:60,offset:.5}]),[[0,70],[130,200]]);
});

test('project schema accepts safe wall sockets and rejects diagonal or forged door ids',()=>{
 const p=exampleProject();p.walls=[{id:'w',ax:0,ay:0,bx:200,by:0,style:'grand',thickness:18}];
 p.openings=[{id:'o',wallId:'w',kind:'double_door',width:100,offset:.5,doorId:'RM-DOOR-ENTRY-HALL'}];
 assert.equal(validateProject(p).openings.length,1);assert.equal(validateWalls(p).walls.length,1);
 p.walls[0].by=20;assert.throws(()=>validateProject(p),/ортогональной/);
 p.walls[0].by=0;p.openings[0].doorId='RM-HACK';assert.throws(()=>validateProject(p),/RM-DOOR/);
});

test('project schema rejects overlapping openings on the same wall',()=>{
 const p=exampleProject();p.walls=[{id:'w',ax:0,ay:0,bx:300,by:0,style:'grand',thickness:18}];
 p.openings=[
  {id:'a',wallId:'w',kind:'door',width:100,offset:.4},
  {id:'b',wallId:'w',kind:'window',width:100,offset:.5}
 ];
 assert.throws(()=>validateProject(p),/пересекаются/);
});

test('textured wall bands keep one orientation and one module height',()=>{
 const right={id:'r',ax:0,ay:100,bx:200,by:100,style:'grand',thickness:18};
 const left={id:'l',ax:200,ay:100,bx:0,by:100,style:'grand',thickness:18};
 const down={id:'d',ax:50,ay:0,bx:50,by:200,style:'grand',thickness:18};

 const forward=wallBand(right,0,200),backward=wallBand(left,0,200),vertical=wallBand(down,0,200);
 assert.equal(forward.angle,0);assert.equal(backward.angle,0);
 assert.equal(forward.length,200);assert.equal(backward.length,200);
 assert.equal(forward.height,WALL_BAND_HEIGHT);
 // Both directions start the band at the same world point so the texture does not flip.
 assert.deepEqual([forward.x,forward.y],[backward.x,backward.y]);
 assert.ok(Math.abs(vertical.angle-Math.PI/2)<1e-9);
 assert.equal(wallBand(right,120,80),null);
});
test('only traversable openings cut the wall; windows stay on a solid wall',()=>{
 const wall={id:'w',ax:0,ay:0,bx:200,by:0,style:'residential',thickness:18};
 const door={id:'d',wallId:'w',kind:'door',width:60,offset:.5};
 const window_={id:'n',wallId:'w',kind:'window',width:60,offset:.5};
 const glass={id:'g',wallId:'w',kind:'glass',width:80,offset:.5};
 assert.deepEqual(solidWallRuns(wall,[door]),[[0,70],[130,200]]);
 assert.deepEqual(solidWallRuns(wall,[window_]),[[0,200]]);
 assert.deepEqual(solidWallRuns(wall,[glass]),[[0,200]]);
 assert.deepEqual(solidWallRuns(wall,[door,window_]),[[0,70],[130,200]]);
 assert.equal(isPortal('door'),true);assert.equal(isPortal('arch'),true);assert.equal(isPortal('stair'),true);
 assert.equal(isPortal('window'),false);assert.equal(isPortal('glass'),false);assert.equal(isPortal('nope'),false);
});