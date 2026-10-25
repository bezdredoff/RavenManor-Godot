const CACHE='raven-room-builder-v5';
const APP_FILES=['./','./index.html','./app.mjs','./catalog.mjs','./projection.mjs','./reference/season1_world_map.json','./catalog/room-items.json','./model.mjs','./style.css','./manifest.webmanifest','./icons/icon.svg','./icons/icon-192.png','./icons/icon-512.png'];
self.addEventListener('install',event=>{event.waitUntil(caches.open(CACHE).then(cache=>cache.addAll(APP_FILES)).then(()=>self.skipWaiting()));});
self.addEventListener('activate',event=>{event.waitUntil(Promise.all([caches.keys().then(keys=>Promise.all(keys.filter(k=>k.startsWith('raven-room-builder-')&&k!==CACHE).map(k=>caches.delete(k)))),self.clients.claim()]));});
// Prefer published editor assets online; use the cached shell when offline.
self.addEventListener('fetch',event=>{
 const request=event.request,url=new URL(request.url);
 if(request.method!=='GET'||url.origin!==self.location.origin||!url.pathname.startsWith(new URL(self.registration.scope).pathname))return;
 event.respondWith((async()=>{
  try{const fresh=await fetch(request);if(fresh.ok){const cache=await caches.open(CACHE);cache.put(request,fresh.clone()).catch(()=>{});}return fresh;}
  catch(error){const cached=await caches.match(request);if(cached)return cached;throw error;}
 })());
});