import {openingInterval,wallLength} from './wall-tools.mjs';

const EPS=1e-6;
const sortedUnique=values=>[...new Set(values)].sort((a,b)=>a-b);
const canonical=(a,b)=>a.x<b.x||(a.x===b.x&&a.y<=b.y)?[a,b]:[b,a];
export const segmentKey=(a,b)=>canonical(a,b).map(p=>`${p.x},${p.y}`).join('|');

export function normalizedSegments(walls=[]){
 const seen=new Map();
 for(const wall of walls){
  const [a,b]=canonical({x:wall.ax,y:wall.ay},{x:wall.bx,y:wall.by});
  if(Math.hypot(b.x-a.x,b.y-a.y)<EPS)continue;
  const key=segmentKey(a,b),existing=seen.get(key);
  if(existing){existing.wallIds.push(wall.id);continue;}
  seen.set(key,{a,b,style:wall.style||'grand',thickness:wall.thickness||18,wallIds:[wall.id]});
 }
 return [...seen.values()];
}

function covers(segments,a,b){
 const horizontal=Math.abs(a.y-b.y)<EPS;
 const start=horizontal?Math.min(a.x,b.x):Math.min(a.y,b.y);
 const end=horizontal?Math.max(a.x,b.x):Math.max(a.y,b.y);
 const intervals=segments.filter(s=>horizontal
  ?Math.abs(s.a.y-a.y)<EPS&&Math.abs(s.b.y-a.y)<EPS
  :Math.abs(s.a.x-a.x)<EPS&&Math.abs(s.b.x-a.x)<EPS)
  .map(s=>horizontal?[Math.min(s.a.x,s.b.x),Math.max(s.a.x,s.b.x)]:[Math.min(s.a.y,s.b.y),Math.max(s.a.y,s.b.y)])
  .sort((u,v)=>u[0]-v[0]);
 let cursor=start;
 for(const [lo,hi] of intervals){if(hi<cursor+EPS)continue;if(lo>cursor+EPS)return false;cursor=Math.max(cursor,hi);if(cursor>=end-EPS)return true;}
 return false;
}

/** Find elementary closed rectangular rooms. Adjacent rectangles stay separate cells. */
export function detectRooms(walls=[]){
 const segments=normalizedSegments(walls);
 const xs=sortedUnique(segments.flatMap(s=>[s.a.x,s.b.x]));
 const ys=sortedUnique(segments.flatMap(s=>[s.a.y,s.b.y]));
 const rooms=[];
 // Enumerating coordinate pairs lets a smaller side room attach halfway along a taller room.
 // A fully spanning internal wall rejects the larger composite rectangle, leaving the two
 // actual rooms. Very large imported plans use adjacent coordinate cells as a safe bound.
 const bounded=xs.length<=60&&ys.length<=60;
 const xPairs=[];for(let i=0;i<xs.length-1;i++)for(let j=bounded?i+1:i+1;j<=(bounded?xs.length-1:i+1);j++)xPairs.push([i,j]);
 const yPairs=[];for(let i=0;i<ys.length-1;i++)for(let j=bounded?i+1:i+1;j<=(bounded?ys.length-1:i+1);j++)yPairs.push([i,j]);
 for(const [xi,xj] of xPairs)for(const [yi,yj] of yPairs){
  const x0=xs[xi],x1=xs[xj],y0=ys[yi],y1=ys[yj];
  const closed=covers(segments,{x:x0,y:y0},{x:x1,y:y0})&&covers(segments,{x:x0,y:y1},{x:x1,y:y1})&&
   covers(segments,{x:x0,y:y0},{x:x0,y:y1})&&covers(segments,{x:x1,y:y0},{x:x1,y:y1});
  if(!closed)continue;
  const divided=xs.slice(xi+1,xj).some(x=>covers(segments,{x,y:y0},{x,y:y1}))||
   ys.slice(yi+1,yj).some(y=>covers(segments,{x:x0,y},{x:x1,y}));
  if(!divided)rooms.push({x0,y0,x1,y1});
 }
 return rooms;
}

function sourceFor(segments,a,b){
 const horizontal=a.y===b.y;
 return segments.find(s=>horizontal
  ?s.a.y===a.y&&s.b.y===a.y&&s.a.x<=a.x+EPS&&s.b.x>=b.x-EPS
  :s.a.x===a.x&&s.b.x===a.x&&s.a.y<=a.y+EPS&&s.b.y>=b.y-EPS);
}

/** Cutaway convention: north and west faces are visible; near south/east faces are omitted. */
export function shellSegments(walls=[]){
 const base=normalizedSegments(walls),rooms=detectRooms(walls);
 if(!rooms.length)return base;
 const result=new Map();
 for(const room of rooms){
  for(const [a,b] of [[{x:room.x0,y:room.y0},{x:room.x1,y:room.y0}],
                      [{x:room.x0,y:room.y0},{x:room.x0,y:room.y1}]]){
   const source=sourceFor(base,a,b);if(!source)continue;
   result.set(segmentKey(a,b),{...source,a,b});
  }
 }
 return [...result.values()];
}

export function segmentOpenings(segment,walls=[],openings=[]){
 const result=[];
 for(const wall of walls.filter(w=>segment.wallIds.includes(w.id))){
  const total=wallLength(wall),ux=(wall.bx-wall.ax)/total,uy=(wall.by-wall.ay)/total;
  for(const opening of openings.filter(o=>o.wallId===wall.id)){
   const interval=openingInterval(opening,wall);
   const p0={x:wall.ax+ux*interval.start,y:wall.ay+uy*interval.start};
   const p1={x:wall.ax+ux*interval.end,y:wall.ay+uy*interval.end};
   const horizontal=segment.a.y===segment.b.y;
   const lo=horizontal?Math.min(p0.x,p1.x):Math.min(p0.y,p1.y);
   const hi=horizontal?Math.max(p0.x,p1.x):Math.max(p0.y,p1.y);
   const base=horizontal?segment.a.x:segment.a.y,end=horizontal?segment.b.x:segment.b.y;
   if(hi>base+EPS&&lo<end-EPS)result.push({...opening,start:Math.max(base,lo)-base,end:Math.min(end,hi)-base});
  }
 }
 return result.sort((a,b)=>a.start-b.start);
}
