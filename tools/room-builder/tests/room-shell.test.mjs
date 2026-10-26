import test from 'node:test';
import assert from 'node:assert/strict';
import {detectRooms,normalizedSegments,shellSegments,segmentOpenings} from '../room-shell.mjs';

const wall=(id,ax,ay,bx,by)=>({id,ax,ay,bx,by,style:'grand',thickness:18});

test('a closed wall rectangle becomes one room with a two-face cutaway',()=>{
 const walls=[wall('n',0,0,200,0),wall('e',200,0,200,150),wall('s',200,150,0,150),wall('w',0,150,0,0)];
 assert.deepEqual(detectRooms(walls),[{x0:0,y0:0,x1:200,y1:150}]);
 assert.deepEqual(shellSegments(walls).map(s=>[s.a,s.b]),[
  [{x:0,y:0},{x:200,y:0}],[{x:0,y:0},{x:0,y:150}]
 ]);
});

test('an adjacent rectangle becomes a second room and the shared wall is visible once',()=>{
 const walls=[wall('n1',0,0,200,0),wall('n2',200,0,400,0),wall('outer',400,0,400,150),
  wall('s2',400,150,200,150),wall('s1',200,150,0,150),wall('west',0,150,0,0),
  wall('shared-a',200,0,200,150),wall('shared-b',200,150,200,0)];
 assert.equal(detectRooms(walls).length,2);
 const shell=shellSegments(walls);
 assert.equal(shell.filter(s=>s.a.x===200&&s.b.x===200).length,1);
 assert.equal(normalizedSegments(walls).find(s=>s.a.x===200&&s.b.x===200).wallIds.length,2);
});

test('a smaller side room can attach partway along a taller room wall',()=>{
 const walls=[wall('n1',0,0,300,0),wall('shared-long',300,0,300,300),wall('s1',300,300,0,300),wall('w1',0,300,0,0),
  wall('n2',300,100,500,100),wall('e2',500,100,500,240),wall('s2',500,240,300,240)];
 assert.deepEqual(detectRooms(walls),[{x0:0,y0:0,x1:300,y1:300},{x0:300,y0:100,x1:500,y1:240}]);
});

test('opening on a shared wall remains attached to the rendered segment',()=>{
 const walls=[wall('shared-a',200,0,200,150),wall('shared-b',200,150,200,0)];
 const segment=normalizedSegments(walls)[0];
 const openings=[{id:'door',wallId:'shared-b',kind:'door',width:60,offset:.5}];
 const result=segmentOpenings(segment,walls,openings);
 assert.equal(result.length,1);assert.equal(result[0].start,45);assert.equal(result[0].end,105);
});
