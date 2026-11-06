/**
 * Room Builder screen/world math intentionally mirrors season1_map_greybox.gd:
 * screen=(world-center)*zoom with screen-Y multiplied by sin(cameraElevation).
 * Projection affects display and pointer mapping, NEVER persisted object geometry.
 */
export const GODOT_CAMERA_DEGREES = 65;
export const GODOT_DEFAULT_ZOOM = 0.74;
export const FLOOR_DEPTH_RATIO = Math.sin(GODOT_CAMERA_DEGREES * Math.PI / 180);
export const ROOM_AZIMUTH_DEGREES = 45;
export const ROOM_AXIS = Math.SQRT1_2;
export const VIEW_MODES = Object.freeze(['game','room','plan']);
export const depthRatio = mode => mode === 'game' ? FLOOR_DEPTH_RATIO : 1;
export function toScreen(point,view,mode='game') {
 if(mode==='room')return {x:view.x+(point.x-point.y)*ROOM_AXIS*view.scale,
  y:view.y+(point.x+point.y)*ROOM_AXIS*FLOOR_DEPTH_RATIO*view.scale};
 const depth=depthRatio(mode);
 return {x:view.x+point.x*view.scale,y:view.y+point.y*view.scale*depth};
}
export function toWorld(point,view,mode='game') {
 if(!(view.scale>0))throw new Error('Invalid camera zoom');
 if(mode==='room'){
  const u=(point.x-view.x)/(ROOM_AXIS*view.scale),v=(point.y-view.y)/(ROOM_AXIS*FLOOR_DEPTH_RATIO*view.scale);
  return {x:(u+v)/2,y:(v-u)/2};
 }
 const depth=depthRatio(mode);
 return {x:(point.x-view.x)/view.scale,y:(point.y-view.y)/(view.scale*depth)};
}
export function worldDragDelta(dx,dy,zoom,mode='game') {
 if(!(zoom>0))throw new Error('Invalid camera zoom');
 if(mode==='room')return {x:(dx/ROOM_AXIS+dy/(ROOM_AXIS*FLOOR_DEPTH_RATIO))/(2*zoom),
  y:(dy/(ROOM_AXIS*FLOOR_DEPTH_RATIO)-dx/ROOM_AXIS)/(2*zoom)};
 return {x:dx/zoom,y:dy/(zoom*depthRatio(mode))};
}
export function fitProjectedRoom(width,height,canvasWidth,canvasHeight,mode='game',padding=42) {
 if(mode==='room'){
  const projectedWidth=(width+height)*ROOM_AXIS,projectedHeight=(width+height)*ROOM_AXIS*FLOOR_DEPTH_RATIO;
  const scale=Math.max(0.01,Math.min((canvasWidth-padding)/projectedWidth,(canvasHeight-padding-170)/projectedHeight,3));
  return {scale,x:canvasWidth/2+(height-width)*ROOM_AXIS*scale/2,y:padding/2+170};
 }
 const d=depthRatio(mode);
 const scale=Math.max(0.01,Math.min((canvasWidth-padding)/width,(canvasHeight-padding)/(height*d),3));
 return {scale,x:(canvasWidth-width*scale)/2,y:(canvasHeight-height*d*scale)/2};
}
export function projectedPixelHeight(height,mode='game'){return Math.max(1,Math.ceil(height*depthRatio(mode)));}
export function gameRoomReference(project,map){
 if(!map||!Array.isArray(map.rooms))return null;
 const room=map.rooms.find(r=>r.id===project.roomId);
 if(!room||!Array.isArray(room.rect)||room.rect.length!==4)return null;
 const [x,y,w,h]=room.rect;
 const aligned=Math.abs(project.width-w)<0.001&&Math.abs(project.height-h)<0.001;
 return {roomId:room.id,origin:{x,y},width:w,height:h,aligned,
   doors:(map.doors||[]).filter(d=>d.a===map.rooms.indexOf(room)||d.b===map.rooms.indexOf(room))
     .map(d=>({id:d.id,status:d.status,x:d.point[0]-x,y:d.point[1]-y})),
   props:(map.props||[]).filter(p=>p.room===map.rooms.indexOf(room))
     .map(p=>({id:p.id,x:p.rect[0]-x,y:p.rect[1]-y,w:p.rect[2],h:p.rect[3]}))};
}


/**
 * Compare measured pilot painting with the PROPOSED Hall world map in world
 * plan-space units. Review-only: never move doors, sprites, or collision.
 * Fail closed if either copied reference drifts from the expected map.
 */
export function hallCalibrationReview(project,map,measurement,contract,threshold=12){
 const ref=gameRoomReference(project,map);
 const invalid=reason=>({ready:false,reason,doors:[],stairs:[],items:[],seating:null});
 if(!ref?.aligned||ref.roomId!=='RM-ROOM-HALL')return invalid('Нужен черновик Hall с геометрией Godot 700×690');
 if(measurement?.schemaVersion!==1||measurement.status!=='MEASURED_DRAFT_NOT_APPROVED')
  return invalid('Недоступны измерения пилотного фона Hall');
 if(!Array.isArray(measurement.openings)||measurement.openings.length!==ref.doors.length
    ||!Array.isArray(measurement.staircases)||!Array.isArray(measurement.seatingFootprints)
    ||measurement.staircases.length!==2||measurement.seatingFootprints.length!==3)
  return invalid('Неполный набор измерений Hall');
 const point=(xy)=>({x:xy[0]-ref.origin.x,y:xy[1]-ref.origin.y});
 const rect=(xy)=>({x:xy[0]-ref.origin.x,y:xy[1]-ref.origin.y,w:xy[2],h:xy[3]});
 const validPoint=a=>Array.isArray(a)&&a.length===2&&a.every(Number.isFinite);
 const validRect=a=>Array.isArray(a)&&a.length===4&&a.every(Number.isFinite)&&a[2]>0&&a[3]>0;
 const diff=(a,b)=>({dx:b.x-a.x,dy:b.y-a.y,distance:Math.hypot(b.x-a.x,b.y-a.y)});
 const doors=[],seen=new Set();
 for(const raw of measurement.openings){
  if(seen.has(raw.id)||!validPoint(raw.mapPoint)||!validPoint(raw.paintedPoint))
   return invalid('Некорректные измерения двери Hall');
  const official=ref.doors.find(d=>d.id===raw.id);
  if(!official||Math.hypot(raw.mapPoint[0]-ref.origin.x-official.x,raw.mapPoint[1]-ref.origin.y-official.y)>0.01)
   return invalid('Дверь изменилась в карте; измерения устарели: '+raw.id);
  const painted=point(raw.paintedPoint),mapPoint={x:official.x,y:official.y},delta=diff(mapPoint,painted);
  doors.push({id:raw.id,mapPoint,painted,...delta,needsReview:delta.distance>threshold});
  seen.add(raw.id);
 }
 const stairs=[];
 for(const raw of measurement.staircases){
  if(!validRect(raw.mapRect)||!validRect(raw.paintedApproxRect))
   return invalid('Некорректный контур лестницы');
  const official=ref.props.find(p=>p.id===raw.id);
  const expected=rect(raw.mapRect);
  if(!official||Math.max(Math.abs(official.x-expected.x),Math.abs(official.y-expected.y),Math.abs(official.w-expected.w),Math.abs(official.h-expected.h))>0.01)
   return invalid('Размеры лестницы изменились в карте: '+raw.id);
  const painted=rect(raw.paintedApproxRect);
  const boundsDelta={dx:painted.x-official.x,dy:painted.y-official.y,dw:painted.w-official.w,dh:painted.h-official.h};
  stairs.push({id:raw.id,mapRect:official,paintedRect:painted,...boundsDelta,needsReview:Object.values(boundsDelta).some(x=>Math.abs(x)>threshold)});
 }
 const items=[];
 if(Array.isArray(contract?.sprites)){
  const grouped=new Map();
  for(const s of contract.sprites){
   if(!s.mapPropId)continue;
   grouped.set(s.mapPropId,[...(grouped.get(s.mapPropId)||[]),s]);
  }
  for(const p of ref.props){
   const sprites=grouped.get(p.id)||[];
   if(sprites.length!==1)continue; // the three independent seats have one shared legacy footprint
   const objects=(project.objects||[]).filter(o=>o.assetRefId===sprites[0].assetRefId);
   if(objects.length!==1)continue; // user can intentionally duplicate a cutout; do not guess
   const o=objects[0],delta={dx:o.x-p.x,dy:o.y-p.y,dw:o.w-p.w,dh:o.h-p.h};
   items.push({id:p.id,assetRefId:o.assetRefId,mapRect:p,draftRect:{x:o.x,y:o.y,w:o.w,h:o.h},...delta,needsReview:Object.values(delta).some(x=>Math.abs(x)>threshold)});
  }
 }
 const legacy=ref.props.find(p=>p.id==='RM-ASSET-HALL-SEATS');
 if(!legacy)return invalid('Физический контур кресел отсутствует в карте');
 const footprints=[];
 for(const item of measurement.seatingFootprints){
  if(!validRect(item.rect))return invalid('Некорректный тестовый контур мебели');
  footprints.push({id:item.id,rect:rect(item.rect)});
 }
 return {ready:true,reason:'',threshold,origin:ref.origin,doors,stairs,items,
  seating:{legacy,footprints,status:'CANDIDATE_NOT_APPROVED'}};
}
