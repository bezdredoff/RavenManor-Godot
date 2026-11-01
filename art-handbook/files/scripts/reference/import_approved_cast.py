"""Publish only reviewed clothed cast art; retain exact RGBA via lossless WebP."""
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import numpy as np
from PIL import Image

SOURCE = Path(r'D:\AI\RavenManor-GFX01-20261027')
TARGET = Path(r'D:\AI\RavenManor-character-integration')
CAST = SOURCE/'output/RavenCast'
jobs=[]
base_poses={'Evelyn':'relaxed','Ada':'composed','Lucas':'formal','Rowan':'work_ready'}
def add(name,variant,path,pose,emotion='neutral',props=(),default=False):
    jobs.append(dict(name=name,variant=variant,source=path,pose=pose,emotion=emotion,props=list(props),default=default))
for name,pose in base_poses.items():
    for path in sorted((CAST/'FullBodyEmotions'/name).glob('*.png')):
        emotion=path.stem.removeprefix(name+'_')
        add(name,'base_'+emotion,path,pose,emotion,default=True)
mapping={
 'Ada':{
  'apron_reach':('apron_reach',['PROP-APRON-SUPPLIES']), 'clothespins':('apron_reach',[]),
  'keys':('composed',[]),'lantern':('composed',['PROP-LANTERN']),
  'letters_bundle':('apron_reach',[]),'offer_tray':('offer_tray',[]),'teacup':('composed',[]),'twine':('apron_reach',[])},
 'Lucas':{
  'closed_folder':('formal',['PROP-NOTARY-FOLDER']), 'cost_sheet':('folder_present',['PROP-RESTORATION-COSTS']),
  'explain':('explain',[]),'folder_present':('folder_present',['PROP-NOTARY-FOLDER']),
  'glasses_adjust':('formal',[]),'inspect_photo':('explain',['PROP-FADED-PHOTO']),
  'legal_forms':('folder_present',[]),'page_align':('folder_present',[])},
 'Rowan':{
  'childhood_box':('work_ready',['PROP-CHILDHOOD-BOX']), 'garden_gloves':('work_ready',[]),
  'garden_plan':('point_route',[]),'point_route':('point_route',[]),'rest_tool':('rest_tool',[]),
  'sleeve_wipe':('work_ready',[]),'thermos_mug':('rest_tool',['PROP-THERMOS']),
  'toolbox':('rest_tool',[]),'weight_shift':('work_ready',[]),'work_ready':('work_ready',[])}
}
for name,variants in mapping.items():
    for variant,(pose,props) in variants.items():
        default=variant in ['offer_tray','apron_reach','folder_present','explain','rest_tool','point_route']
        add(name,variant,CAST/'PerformanceApproved'/name/(name+'_'+variant+'.png'),pose,props=props,default=default)
evelyn_props={
 'childhood_box':'PROP-CHILDHOOD-BOX','childhood_map':'PROP-CHILDHOOD-MAP','diary':'PROP-DIARY',
 'faded_photo':'PROP-FADED-PHOTO','household_ledger_v2':'PROP-HOUSEHOLD-LEDGER',
 'inheritance_envelope':'PROP-LETTER','small_key':'PROP-CHILDHOOD-OBJECT','unsigned_letter':'PROP-UNSIGNED-LETTER'}
for variant,prop in evelyn_props.items():
    add('Evelyn',variant.removesuffix('_v2'),CAST/'PropApproved/Evelyn'/('Evelyn_'+variant+'.png'),'investigate',props=[prop])
for variant,folder,pose,default in [
 ('relaxed_gesture','relaxed','relaxed',False),('decide','decide','decide',True),
 ('investigate_small','investigate_small','investigate',True),('investigate_wide','investigate_v2','investigate',False)]:
    paths=list((CAST/'StoryPoses/Evelyn'/folder/'full_body').glob('*.png'));assert len(paths)==1
    add('Evelyn',variant,paths[0],pose,default=default)

def publish(job):
    src=job['source']; im=Image.open(src).convert('RGBA'); original=np.asarray(im)
    assert im.getextrema()[3][0]==0,src
    relative=Path('assets/raven/characters')/job['name'].lower()/(job['variant']+'.webp')
    dest=TARGET/relative;dest.parent.mkdir(parents=True,exist_ok=True)
    im.save(dest,format='WEBP',lossless=True,exact=True,method=6)
    assert np.array_equal(original,np.asarray(Image.open(dest).convert('RGBA'))),src
    return dict(id='RM-VN-'+job['name'].upper()+'-'+job['variant'].upper().replace('_','-'),
      characterId='RM-CHAR-'+job['name'].upper(),variant=job['variant'],pose=job['pose'],emotion=job['emotion'],
      propIds=job['props'],defaultForPose=job['default'],path='res://'+relative.as_posix(),
      width=im.width,height=im.height,status='accepted',approved='2026-11-01',
      provenance=dict(generator='Local ComfyUI / VNCCS + Qwen Image 2.1',
        source=src.relative_to(SOURCE/'output').as_posix(),sourceSha256=hashlib.sha256(src.read_bytes()).hexdigest(),
        sourceWorkflowSha256=hashlib.sha256(str(Image.open(src).info['workflow']).encode()).hexdigest() if Image.open(src).info.get('workflow') else None,
        export='lossless WebP; decoded RGBA exactly equals source PNG',sha256=hashlib.sha256(dest.read_bytes()).hexdigest()))

with ThreadPoolExecutor(max_workers=4) as pool: entries=list(pool.map(publish,jobs))
labels = {
 'neutral':'Нейтрально','amused':'Улыбка','curious':'Любопытство','determined':'Решимость',
 'skeptical':'Скепсис','worried':'Тревога','concerned':'Беспокойство','dry_amused':'Сдержанная усмешка',
 'regretful':'Сожаление','stern':'Строгость','warm':'Тёплая улыбка','polite_smile':'Вежливая улыбка',
 'professional':'Деловой вид','reserved_worry':'Сдержанная тревога','serious':'Серьёзность',
 'focused':'Сосредоточенность','friendly':'Дружелюбие','nostalgic':'Ностальгия','wry':'Ирония',
 'apron_reach':'Рука в кармане фартука','clothespins':'Прищепки','keys':'Ключи','lantern':'Фонарь',
 'letters_bundle':'Связка писем','offer_tray':'Поднос с чаем','teacup':'Чашка чая','twine':'Бечёвка',
 'closed_folder':'Закрытая папка','cost_sheet':'Смета','explain':'Объясняет','folder_present':'Открытая папка',
 'glasses_adjust':'Поправляет очки','inspect_photo':'Оборот фотографии','legal_forms':'Бланки и ручка',
 'page_align':'Выравнивает бумаги','childhood_box':'Коробка из детства','garden_gloves':'Садовые перчатки',
 'garden_plan':'План сада','point_route':'Указывает путь','rest_tool':'Опустил молоток',
 'sleeve_wipe':'Вытирает лоб','thermos_mug':'Кружка чая','toolbox':'Ящик инструментов',
 'weight_shift':'Переносит вес','work_ready':'Готов к работе','childhood_map':'Детская карта',
 'diary':'Дневник','faded_photo':'Старая фотография','household_ledger':'Хозяйственная книга',
 'inheritance_envelope':'Конверт о наследстве','small_key':'Маленький ключ','unsigned_letter':'Письмо без подписи',
 'relaxed_gesture':'Разговорный жест','decide':'Уверенная стойка','investigate_small':'Осмотр · руки ближе',
 'investigate_wide':'Осмотр · руки шире'}
for entry in entries:
    variant=entry['variant']
    entry['labelRu']=('Базовая стойка · '+labels.get(variant[5:],variant[5:])) if variant.startswith('base_') else labels.get(variant,variant)
catalog=dict(schemaVersion=1,status='owner_accepted_art_integration_review',approval='Owner approved clothed cast, full-body emotions, Evelyn props and Ada/Lucas/Rowan performance sets in production chat; latest Rowan approval 2026-11-01.',
  scope='VN only. No chibi map art, blink/mouth overlays, nude identity studies, rejected experiments or new pose x emotion combinations.',entries=entries)
(TARGET/'data/raven/production/vn_character_catalog.json').write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Published',len(entries),'lossless images;',round(sum((TARGET/Path(e['path'].removeprefix('res://'))).stat().st_size for e in entries)/1024/1024,1),'MiB; exact pixel checks passed.')
