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
