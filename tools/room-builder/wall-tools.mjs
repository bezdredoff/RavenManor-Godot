export const WALL_STYLES = Object.freeze({
  grand: {label:'Парадная', color:'#5f463f', trim:'#c29a68'},
  residential: {label:'Жилая', color:'#6c5b55', trim:'#bca186'},
  service: {label:'Служебная / влажная', color:'#596063', trim:'#9da9aa'},
  glass: {label:'Оранжерея', color:'#52706c', trim:'#a9d0c5'}
});

// `portal` means the opening is traversable, so it cuts a hole in the wall. Windows and
// glazed sections are not traversable: they stay on a solid wall and are never cut out.
export const OPENING_KINDS = Object.freeze({
  door: {label:'Обычная дверь', color:'#d39b73', defaultWidth:75, portal:true},
  double_door: {label:'Двойная дверь', color:'#e0ae72', defaultWidth:110, portal:true},
  arch: {label:'Арка', color:'#cba5d9', defaultWidth:110, portal:true},
  window: {label:'Окно', color:'#82cce0', defaultWidth:70, portal:false},
  glass: {label:'Стеклянная секция', color:'#75d4c7', defaultWidth:80, portal:false},
  stair: {label:'Лестничный проём', color:'#d9c27d', defaultWidth:140, portal:true}
});
export const isPortal = kind => Boolean(OPENING_KINDS[kind]?.portal);

const finite = value => Number.isFinite(value);
export const wallLength = wall => Math.hypot(wall.bx-wall.ax,wall.by-wall.ay);

// Height of the textured wall band in world pixels. One module is 80x80 game pixels, so the
// band shows exactly one framed row — the same proportion the game would use.
export const WALL_BAND_HEIGHT = 80;

/**
 * Oriented band for a solid wall run, used by the textured-wall preview.
 * The run is re-ordered so the band always sits on the same side of the stroke, which keeps
 * horizontal walls above the line and vertical walls to its right.
 */
export function wallBand(wall,start,end,height=WALL_BAND_HEIGHT){
  const total=wallLength(wall);
  if(!(total>0)||!(end>start))return null;
  const dx=(wall.bx-wall.ax)/total,dy=(wall.by-wall.ay)/total;
  const p0={x:wall.ax+dx*start,y:wall.ay+dy*start};
  const p1={x:wall.ax+dx*end,y:wall.ay+dy*end};
  const reverse=dx<0||(Math.abs(dx)<1e-9&&dy<0);
  const a=reverse?p1:p0,b=reverse?p0:p1;
  return {x:a.x,y:a.y,length:Math.hypot(b.x-a.x,b.y-a.y),angle:Math.atan2(b.y-a.y,b.x-a.x),height};
}

export function normalizeWall(a,b,grid=25){
  const ax=Math.round(a.x/grid)*grid,ay=Math.round(a.y/grid)*grid;
  let bx=Math.round(b.x/grid)*grid,by=Math.round(b.y/grid)*grid;
  if(Math.abs(bx-ax)>=Math.abs(by-ay))by=ay;else bx=ax;
  if(ax===bx&&ay===by)return null;
  return {ax,ay,bx,by};
}

export function nearestWall(walls,point,maxDistance=45){
  let result=null,best=maxDistance;
  for(const wall of walls){
    const dx=wall.bx-wall.ax,dy=wall.by-wall.ay,l2=dx*dx+dy*dy;
    if(!l2)continue;
    const t=Math.max(0,Math.min(1,((point.x-wall.ax)*dx+(point.y-wall.ay)*dy)/l2));
    const x=wall.ax+t*dx,y=wall.ay+t*dy,d=Math.hypot(point.x-x,point.y-y);
    if(d<=best){best=d;result={wall,t,x,y,distance:d};}
  }
  return result;
}

export function openingInterval(opening,wall){
  const length=wallLength(wall),half=Math.min(opening.width/2,length/2);
  const center=Math.max(half,Math.min(length-half,(opening.offset??0.5)*length));
  return {start:center-half,end:center+half,length};
}

export function solidWallRuns(wall,openings){
  // Only traversable openings remove wall material; a window sits on a solid wall.
  const intervals=openings.filter(o=>o.wallId===wall.id&&isPortal(o.kind))
    .map(o=>openingInterval(o,wall)).sort((a,b)=>a.start-b.start);
  const runs=[];let cursor=0;
  for(const interval of intervals){if(interval.start>cursor)runs.push([cursor,interval.start]);cursor=Math.max(cursor,interval.end);}
  const length=wallLength(wall);if(cursor<length)runs.push([cursor,length]);return runs;
}

export function endpointTopology(walls,wall,atStart){
  const p=atStart?{x:wall.ax,y:wall.ay}:{x:wall.bx,y:wall.by};
  const connected=walls.filter(w=>w.id!==wall.id&&([[w.ax,w.ay],[w.bx,w.by]].some(q=>q[0]===p.x&&q[1]===p.y)));
  if(!connected.length)return 'cap';
  const horizontal=wall.ay===wall.by;
  if(connected.some(w=>(w.ay===w.by)!==horizontal))return 'corner';
  return connected.length>1?'junction':'straight';
}

export function validateWalls(project){
  const walls=Array.isArray(project.walls)?project.walls:[],openings=Array.isArray(project.openings)?project.openings:[];
  if(walls.length>4000||openings.length>2000)throw new Error('Слишком много стен или проёмов');
  const wallIds=new Set(),openingIds=new Set();
  for(const wall of walls){
    if(!wall||typeof wall.id!=='string'||wallIds.has(wall.id)||![wall.ax,wall.ay,wall.bx,wall.by,wall.thickness].every(finite))throw new Error('Некорректная стена');
    if(!WALL_STYLES[wall.style]||wallLength(wall)<1||wall.thickness<4||wall.thickness>100)throw new Error('Некорректный стиль или размер стены');
    if([wall.ax,wall.bx].some(x=>x<0||x>project.width)||[wall.ay,wall.by].some(y=>y<0||y>project.height))throw new Error('Стена выходит за границы комнаты');
    if(wall.ax!==wall.bx&&wall.ay!==wall.by)throw new Error('Стены должны идти по ортогональной сетке');
    wallIds.add(wall.id);
  }
  for(const opening of openings){
    if(!opening||typeof opening.id!=='string'||openingIds.has(opening.id)||!wallIds.has(opening.wallId)||!OPENING_KINDS[opening.kind]||!finite(opening.width)||!finite(opening.offset))throw new Error('Некорректный проём');
    const wall=walls.find(w=>w.id===opening.wallId);
    if(opening.width<16||opening.width>wallLength(wall)||opening.offset<0||opening.offset>1)throw new Error('Проём не помещается на стене');
    if(opening.doorId&&!/^RM-DOOR-[A-Z0-9-]+$/.test(opening.doorId))throw new Error('Некорректный RM-DOOR ID');
    openingIds.add(opening.id);
  }
  for(const wall of walls){
    const intervals=openings.filter(o=>o.wallId===wall.id).map(o=>openingInterval(o,wall)).sort((a,b)=>a.start-b.start);
    for(let i=1;i<intervals.length;i++)if(intervals[i].start<intervals[i-1].end)throw new Error('Проёмы на одной стене пересекаются');
  }
  return {walls,openings};
}
// Which kit sprite represents a solid wall run. Openings win over the plain wall, so the run
// under a door is drawn with the door piece instead of a stretched straight one.
export function chooseWallPiece(wall, openings, run){
  const [start,end]=run||[0,wallLength(wall)];
  const mid=(start+end)/2;
  const own=openings.filter(o=>o.wallId===wall.id).map(o=>({kind:o.kind,interval:openingInterval(o,wall)}));
  const inside=own.find(o=>o.interval.start<=mid&&mid<=o.interval.end);
  if(inside&&['door','arch','window'].includes(inside.kind))return inside.kind;
  return 'straight';
}