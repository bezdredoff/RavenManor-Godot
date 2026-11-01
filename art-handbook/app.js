/* Read-only handbook. No ComfyUI requests, GPU jobs or source mutations. */
'use strict';
const {catalog, content, environment} = window.RAVEN_HANDBOOK;
const $ = (id) => document.getElementById(id);
const recipes = new Map(catalog.recipes.map(r => [r.id, r]));
const assets = new Map(catalog.assets.map(a => [a.id, a]));
const repoBase = `https://github.com/bezdredoff/RavenManor-Godot/blob/${catalog.baselineCommit}/`;
const rawBase = `https://raw.githubusercontent.com/bezdredoff/RavenManor-Godot/${catalog.baselineCommit}/`;
const groupNames = {Evelyn:'Эвелин', Ada:'Ада', Lucas:'Лукас', Rowan:'Роуэн'};
const statusNames = {accepted:'Принято',candidate:'Кандидат',pending_review:'Ожидает ревью',superseded:'Заменено',concept_only:'Концепт',technical_placeholder:'Тех. заглушка'};
const evidenceNames = {png_metadata:'Метаданные PNG',exact_saved_run:'Сохранённый запуск',executed_api_and_saved_ui:'Executed API + history',documented_intent_only:'Точные запросы не сохранены',reconstructed_not_verbatim:'Реконструкция',external_technical_placeholder:'Внешний placeholder',saved_template_and_review_manifest:'Шаблон + review manifest'};
function el(tag, attrs={}, children=[]) {
  const node = document.createElement(tag);
  for (const [key,value] of Object.entries(attrs)) {
    if (key === 'class') node.className = value;
    else if (key.startsWith('on') && typeof value === 'function') node.addEventListener(key.slice(2),value);
    else if (value !== null && value !== undefined) node.setAttribute(key,String(value));
  }
  for (const child of Array.isArray(children) ? children : [children]) {
    if (child !== null && child !== undefined) node.append(child instanceof Node ? child : document.createTextNode(String(child)));
  }
  return node;
}
function button(label, fn, cls='quiet') { return el('button',{type:'button',class:cls,onclick:fn},label); }
function badge(label, cls='recorded') { return el('span',{class:'badge '+cls},label); }
function format(value) { return typeof value === 'string' ? value : JSON.stringify(value,null,2); }
function toast(text) { $('toast').textContent=text; $('toast').hidden=false; clearTimeout(toast.timer); toast.timer=setTimeout(()=>{$('toast').hidden=true;},2200); }
async function copy(text) {
  try { await navigator.clipboard.writeText(text); toast('Скопировано'); }
  catch (_) { const t=el('textarea',{},text); document.body.append(t);t.select();document.execCommand('copy');t.remove();toast('Скопировано'); }
}
function codeBlock(label, value, certainty) {
  const text=value === null ? 'NOT RECORDED — исходные данные отсутствуют' : format(value);
  return el('div',{},[el('div',{class:'code-head'},[el('span',{},label),certainty ? badge(certainty,certainty.includes('unavailable')?'unknown':'recorded'):null,button('Копировать',()=>copy(text),'copy')]),el('pre',{},text)]);
}
function artifactLink(a) { return el('a',{href:a.path || repoBase+a.repoPath,download:a.path?'':null,target:a.repoPath?'_blank':null,rel:a.repoPath?'noopener':null},a.label+' ↗'); }
function openDialog(children, hash) {
  $('detail-body').replaceChildren(...children);
  if (!$('detail').open) $('detail').showModal();
  $('detail').scrollTop=0;
  history.replaceState(null,'','#'+hash);
}

function showAsset(id) {
  const a=assets.get(id); if(!a)return;
  const recipe=recipes.get(a.recipeId);
  const img=el('img',{src:a.image?'../'+a.image:a.preview,alt:a.title});
  img.addEventListener('error',()=>{if(a.preview && !img.src.endsWith(a.preview))img.src=a.preview;},{once:true});
  const picture=el('div',{class:'detail-image'},[img]);
  const background=el('div',{class:'download-row'},['Фон: ',button('Светлый',()=>{picture.style.background='#f7f5ef';}),button('Тёмный',()=>{picture.style.background='#29352e';}),button('Клетка',()=>{picture.style.background='repeating-conic-gradient(#ddd 0% 25%,#eee 0% 50%) 0 0 / 20px 20px';})]);
  const info=el('div',{class:'detail-content'},[
    badge(statusNames[a.status] || a.status,a.status==='accepted'?'recorded':'archive'),
    el('h2',{id:'detail-title'},a.title),el('div',{class:'id'},a.id),
    el('p',{},`${a.width} × ${a.height} · ${groupNames[a.group]||a.group}`),
    a.pose?el('p',{},`Поза: ${a.pose} · эмоция: ${a.emotion}`):null,
    a.lighting?el('p',{},`${a.lighting} / ${a.roomState}`):null,
    badge(evidenceNames[a.evidence] || a.evidence,a.kind==='character'?'recorded':'archive'),
    el('p',{},recipe?.title||a.recipeId),button('Открыть рецепт ↗',()=>showRecipe(a.recipeId),'primary'),
    a.image?el('p',{},el('a',{href:rawBase+a.image,target:'_blank',rel:'noopener'},'Оригинал в репозитории ↗')):el('p',{class:'muted'},'Оригинал хранится вне репозитория. В книге — проверенное превью и hash исходного файла.'),
    background,el('h3',{},'SHA-256 результата'),el('p',{class:'hash'},a.sha256),button('Копировать hash',()=>copy(a.sha256),'copy'),
    a.prompt?codeBlock('Prompt этого задания',a.prompt,'verbatim_manifest'):null,
    a.seed!==undefined?el('p',{},'Seed: '+a.seed):null,
    a.sourceImage?el('p',{class:'muted'},'Исходник: '+a.sourceImage):null,
    a.chain?el('div',{},[el('h3',{},'Цепочка производства'),...a.chain.map(rid=>button(recipes.get(rid)?.title||rid,()=>showRecipe(rid),'quiet'))]):null
  ]);
  openDialog([el('div',{class:'detail-grid'},[picture,info])],'asset='+encodeURIComponent(id));
}

function showRecipe(id) {
  const r=recipes.get(id);if(!r)return;
  const stage=content.stages[r.stage];
  const scalarParams=Object.entries(r.parameters).filter(([,v])=>v===null||typeof v!=='object');
  const inputs=el('div',{class:'artifact-list'},r.inputs.map(inp=>el('a',{href:inp.path,download:''},[el('img',{src:inp.path,alt:'',loading:'lazy',width:70,height:70,style:'object-fit:contain;display:block'}),inp.originalName])));
  const outputs=el('div',{class:'recipe-output-list'},r.outputs.map(aid=>{
    const a=assets.get(aid);return a?el('button',{type:'button',onclick:()=>showAsset(aid)},[a.preview?el('img',{src:a.preview,alt:'',loading:'lazy'}):null,a.title]):null;
  }).filter(Boolean));
  const nodes=el('div',{class:'recipe-detail'},[
    el('p',{class:'eyebrow'},stage?.name||r.stage),badge(evidenceNames[r.evidence]||r.evidence,['png_metadata','executed_api_and_saved_ui'].includes(r.evidence)?'recorded':'archive'),
    el('h2',{id:'detail-title'},r.title),el('p',{class:'id'},r.id),el('p',{class:'muted'},stage?.description||''),
    el('div',{class:'flow'},(stage?.pipeline||[]).map((text,i)=>el('span',{class:'pipeline-pill'},`${i+1}. ${text}`))),
    el('h3',{},'Что важно при повторении'),el('ul',{},r.notes.map(n=>el('li',{},n))),
    el('h3',{},'Параметры сохранённого запуска'),
    el('div',{class:'param-list'},scalarParams.map(([key,v])=>el('div',{class:'param-item'},[el('small',{},key),el('strong',{},v===null?'не записано':String(v))]))),
    el('details',{},[el('summary',{},'Показать все параметры и состояния узлов'),codeBlock('Parameters',r.parameters),codeBlock('Node settings',r.settings)]),
    el('h3',{},'Prompts и текстовые поля'),r.prompts.length?el('div',{},r.prompts.map(p=>el('div',{},[codeBlock(p.label,p.value,p.certainty),p.note?el('p',{class:'muted'},p.note):null]))):el('p',{class:'muted'},'Verbatim prompt не записан. Смотрите связанные документы; реконструкция не считается исходным запросом.'),
    el('h3',{},'Зависимости'),el('ul',{},r.requires.map(n=>el('li',{},n))),
    el('h3',{},'Скачать файлы'),el('div',{class:'artifact-list'},r.artifacts.map(artifactLink)),
    r.inputs.length?el('div',{},[el('h3',{},'Входные изображения и маски'),el('p',{class:'muted'},'Имена установки указаны в catalog.json. Replay API использует ComfyUI/input/RavenHandbook/.'),inputs]):null,
    el('h3',{},'Результаты этого рецепта'),outputs,
    r.nodeTypes?el('details',{},[el('summary',{},'Классы узлов'),codeBlock('Node types',r.nodeTypes)]):null,
    r.sourcePngSha256?el('p',{class:'muted'},'SHA исходного PNG первого сохранённого запуска: '+r.sourcePngSha256):null,
    el('div',{class:'note'},[el('strong',{},'До повторной генерации'),el('p',{},'Сверьте зависимости и namespace. API повторения содержит подготовленные изменения путей/выходов. GPU-прогон replay при создании этой книги не выполнялся. Новый результат требует отдельного художественного ревью.')])
  ]);
  openDialog([nodes],'recipe='+encodeURIComponent(id));
}

for(const [value,label] of [[62,'принятых кадров персонажей'],[26,'VN-фонов в каталоге'],[catalog.recipes.length,'рецепта и пути'],[catalog.assets.length,'изображения с учётом архива']])$('stats').append(el('div',{class:'stat'},[el('strong',{},value),el('span',{},label)]));
for(const stage of ['identity','clothes','emotions','pose','inpaint'])$('flow').append(el('div',{class:'flow-item'},[el('small',{},content.stages[stage].name.split(' · ')[0]),el('b',{},content.stages[stage].name.split(' · ')[1]),el('a',{href:'#recipes',onclick:()=>setStage(stage)},'Рецепты этапа')]));
for(const note of content.important)$('important').append(el('article',{class:'fact'},[el('h3',{},note.title),el('p',{},note.text)]));
let selectedStage='identity';
function setStage(stage) {
  selectedStage=stage;
  for(const b of $('stage-tabs').children)b.setAttribute('aria-pressed',String(b.dataset.stage===stage));
  $('recipe-list').replaceChildren(...catalog.recipes.filter(r=>r.stage===stage).map(r=>el('button',{type:'button',class:'recipe-card',onclick:()=>showRecipe(r.id)},[
    badge(evidenceNames[r.evidence]||r.evidence,['png_metadata','executed_api_and_saved_ui'].includes(r.evidence)?'recorded':'archive'),el('h3',{},r.title),el('p',{},r.stage==='identity'?'Служебная фигура · до финального костюма':`${r.outputs.length} результатов · ${r.inputs.length} входов`)
  ])));
}
for(const [stage,info] of Object.entries(content.stages)){
  const b=button(info.name,()=>setStage(stage));b.dataset.stage=stage;b.setAttribute('aria-pressed','false');$('stage-tabs').append(b);
}
setStage(selectedStage);
for(const group of [...new Set(catalog.assets.map(a=>a.group))].sort())$('group').append(el('option',{value:group},groupNames[group]||group));
function renderAssets() {
  const needle=$('search').value.trim().toLocaleLowerCase();
  const kind=$('kind').value, group=$('group').value, status=$('status').value, archive=$('archive').checked;
  const filtered=catalog.assets.filter(a=>{
    if(!archive && !['character','background'].includes(a.kind))return false;
    if(kind && a.kind!==kind || group && a.group!==group || status && a.status!==status)return false;
    return !needle || `${a.id} ${a.title} ${a.group} ${groupNames[a.group]||''} ${a.pose||''} ${a.emotion||''} ${a.prompt||''}`.toLocaleLowerCase().includes(needle);
  });
  $('asset-grid').replaceChildren(...filtered.map(a=>el('button',{type:'button',class:'asset-card '+a.kind,onclick:()=>showAsset(a.id),'aria-label':a.title},[
    el('div',{class:'asset-picture'},a.preview?el('img',{src:a.preview,alt:a.title,loading:'lazy',decoding:'async'}):'Превью отсутствует'),
    el('div',{class:'asset-caption'},[badge(statusNames[a.status]||a.status,a.status==='accepted'?'recorded':'archive'),el('h3',{},a.title),el('small',{},`${a.width} × ${a.height} · ${a.id}`)])
  ])));
  $('result-count').textContent=`Показано ${filtered.length} из ${catalog.assets.length}`;
  $('empty').hidden=filtered.length!==0;
}
$('filters').addEventListener('submit',e=>e.preventDefault());
$('filters').addEventListener('input',renderAssets);
$('kind').addEventListener('change',()=>{if(['archive','wall_candidate','technical'].includes($('kind').value))$('archive').checked=true;renderAssets();});
$('filters').addEventListener('change',renderAssets);
$('filters').addEventListener('reset',()=>setTimeout(renderAssets,0));
renderAssets();

const gib=b=>(Number(b)/(1024**3)).toFixed(2)+' GiB';
for(const [label,value,detail] of [
  ['Вычислительная система',(environment.gpu||'').split(',')[0],`${environment.cpu||''}\nRAM: ${gib(environment.ramBytes)}\n${environment.os}`],
  ['Python / PyTorch',`Python ${environment.python} · torch ${environment.torch}`,`CUDA runtime ${environment.cudaRuntime}\nDriver: ${(environment.gpu||'').split(',')[1]||'unknown'}\nComfy core ${environment.coreCommit?.slice(0,12)||'unknown'}`],
  ['Изолированный sandbox','D: · 127.0.0.1:8189',`${environment.paths.root}\nModels: ${environment.paths.models}\nSnapshot: ${environment.capturedAt}`]
])$('system-summary').append(el('div',{class:'system-card'},[el('small',{},label),el('strong',{},value),el('p',{style:'white-space:pre-line'},detail)]));
for(const n of environment.nodes)$('node-versions').append(el('p',{class:'muted'},[el('strong',{},n.name+' · '),n.commit?n.commit:'git commit не записан',el('br'),el('code',{},'source tree SHA-256: '+n.sourceTreeSha256)]));
for(const m of environment.models)$('models').append(el('tr',{},[el('td',{},m.filename),el('td',{},gib(m.bytes)),el('td',{},[el('code',{},m.path),el('code',{},m.sha256),button('Копировать SHA',()=>copy(m.sha256),'copy')])]));
for(const item of content.journey)$('timeline').append(el('li',{},[
  el('h3',{},item.title),el('p',{},item.text),
  item.recipe?button('Открыть связанный рецепт ↗',()=>showRecipe(item.recipe)):
    el('a',{href:item.evidence||repoBase+item.document},'Источник ↗')
]));
for(const p of catalog.additionalPipelines)$('additional-pipelines').append(el('a',{href:repoBase+p.path,target:'_blank',rel:'noopener'},p.title+' ↗'));
$('baseline').textContent=`Снимок ${catalog.captured} · baseline ${catalog.baselineCommit.slice(0,9)}`;
document.querySelector('.dialog-close').addEventListener('click',()=>$('detail').close());
$('detail').addEventListener('click',e=>{if(e.target===$('detail'))$('detail').close();});
$('detail').addEventListener('close',()=>{if(location.hash.startsWith('#asset=')||location.hash.startsWith('#recipe='))history.replaceState(null,'','#gallery');});
function route(){const q=new URLSearchParams(location.hash.slice(1));if(q.has('asset'))showAsset(q.get('asset'));else if(q.has('recipe'))showRecipe(q.get('recipe'));}
window.addEventListener('hashchange',route);route();
