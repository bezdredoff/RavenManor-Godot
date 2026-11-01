"""Offline preflight by default. --submit explicitly requests a new GPU run.
This prepared replay helper was not GPU-executed while building the handbook.
"""
import argparse
import json
from pathlib import Path
import re
import shutil
import time
import urllib.request

def preflight(book,recipe_id):
    data=json.loads((book/'catalog.json').read_text(encoding='utf-8'))
    recipe=next(r for r in data['recipes'] if r['id']==recipe_id)
    artifact=next(a for a in recipe['artifacts'] if a.get('kind')=='replay')
    graph=json.loads((book/artifact['path']).read_text(encoding='utf-8'))
    for key,node in graph.items():
        if not isinstance(node.get('inputs'),dict) or not node.get('class_type'):raise ValueError('Invalid API node '+key)
        for value in node['inputs'].values():
            if isinstance(value,list) and len(value)==2 and isinstance(value[0],str) and isinstance(value[1],int):
                if value[0] not in graph:raise ValueError('Missing link target '+value[0])
    for inp in recipe['inputs']:
        path=book/inp['path']
        if not path.is_file():raise ValueError('Missing packaged input '+str(path))
    return recipe,graph

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--recipe',required=True)
    p.add_argument('--book',type=Path,default=Path(__file__).resolve().parents[2])
    p.add_argument('--server',default='http://127.0.0.1:8189')
    p.add_argument('--comfy-root',type=Path)
    p.add_argument('--namespace',help='Required for library-writing stages; create the character/costume slots in this new namespace first')
    p.add_argument('--check-server',action='store_true')
    p.add_argument('--submit',action='store_true')
    a=p.parse_args();recipe,graph=preflight(a.book,a.recipe)
    print(json.dumps({'recipe':recipe['id'],'nodes':len(graph),'inputs':len(recipe['inputs']),'stage':recipe['stage'],'submit':a.submit},indent=2))
    def api(path,payload=None):
        req=urllib.request.Request(a.server.rstrip('/')+path,data=json.dumps(payload).encode() if payload is not None else None,headers={'Content-Type':'application/json','Origin':a.server})
        with urllib.request.urlopen(req,timeout=60) as f:return json.load(f)
    if a.check_server or a.submit:
        info=api('/object_info')
        missing=sorted({n['class_type'] for n in graph.values()}-info.keys())
        if missing:raise ValueError('Missing node classes: '+', '.join(missing))
    if not a.submit:
        print('Offline preflight passed. No files copied, models loaded or GPU job queued.');return
    if recipe['stage']=='archive':raise ValueError('Archive batch templates need their original runner; see the linked manifest.')
    if not a.comfy_root or not a.comfy_root.is_dir():raise ValueError('--comfy-root must name an existing installation')
    if recipe['stage']!='inpaint':
        if not a.namespace or not re.fullmatch(r'[A-Za-z0-9_-]+',a.namespace):raise ValueError('Library stages require an isolated --namespace')
        payload=json.dumps(graph,ensure_ascii=False).replace('D:\\AI\\RavenManor-GFX01-20261027',str(a.comfy_root).replace('\\','\\\\'))
        payload=re.sub(r'(Evelyn|Ada|Lucas|Rowan)_(?:CastDraft|StoryPoseStudies)_[A-Za-z0-9_]+',lambda m:a.namespace+'_'+m[1],payload)
        graph=json.loads(payload)
    for inp in recipe['inputs']:
        destination=(a.comfy_root/'input'/inp['installName']).resolve()
        if not destination.is_relative_to((a.comfy_root/'input').resolve()):raise ValueError('Input outside ComfyUI/input')
        destination.parent.mkdir(parents=True,exist_ok=True)
        if destination.exists() and destination.read_bytes()!=(a.book/inp['path']).read_bytes():raise ValueError('Existing input differs: '+str(destination))
        if not destination.exists():shutil.copy2(a.book/inp['path'],destination)
    pid=api('/prompt',{'prompt':graph})['prompt_id'];print('Queued',pid,flush=True)
    while True:
        time.sleep(10);history=api('/history/'+pid)
        if pid in history:break
    result=history[pid]
    if result['status']['status_str']!='success':raise RuntimeError(result['status'])
    print('Generation succeeded:',pid)
    if recipe['stage']=='inpaint':
        from restore_protected_pixels import restore
        inputs={i['node']:a.book/i['path'] for i in recipe['inputs']}
        image=result['outputs']['31']['images'][0]
        raw=a.comfy_root/'output'/image['subfolder']/image['filename']
        crop=recipe['parameters']['crop']
        print(restore(inputs['10'],raw,inputs['13'],[crop[k] for k in ['x','y','width','height']],raw.with_name('restored_'+raw.name)))

if __name__=='__main__':main()
