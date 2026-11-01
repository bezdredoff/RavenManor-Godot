import pathlib,json,shutil
from PIL import Image
r=pathlib.Path(r'D:\AI\RavenManor-GFX01-20261027');m=json.loads((r/'production/cast_emotions_official/manifest.json').read_text(encoding='utf-8'))
dest=r/'output/RavenCast/FullBodyEmotions';report={}
for name,v in m.items():
 w=json.loads(pathlib.Path(v['workflow']).read_text(encoding='utf-8'));e=next(n for n in w['nodes'] if n['type']=='EmotionGeneratorV2');cn=e['widgets_values'][3];costume=json.loads(e['widgets_values'][4])[0]
 neutral=r/f'output/VNCCS/Characters/{cn}/Sprites/{costume}/neutral/base.png'
 folder=dest/name;folder.mkdir(parents=True,exist_ok=True);report[name]={}
 for emotion,src in zip(v['emotions'],[str(neutral)]+v['sprites']):
  im=Image.open(src)
  if im.size!=(1088,1920):raise ValueError((src,im.size))
  target=folder/f'{name}_{emotion}.png';shutil.copy2(src,target)
  report[name][emotion]={'path':str(target),'size':list(im.size),'alpha_bounds':im.getchannel('A').getbbox()}
 # Keep future sprite exports and face crops in different directories.
 for n in w['nodes']:
  if n['type']=='SaveImage':
   n['widgets_values']=[f'RavenCast/EmotionsOfficial/{name}/'+('full_body/sprite' if n['id']==500 else 'face_crops/face')]
 pathlib.Path(v['workflow']).write_text(json.dumps(w,indent=2),encoding='utf-8')
(dest/'manifest.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(dest)
print('Copied',sum(len(v) for v in report.values()),'full-body images')
print(json.dumps(report))
