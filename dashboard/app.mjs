const $ = (selector) => document.querySelector(selector);
const cfg = {tasks: [], assets: {backgrounds:{total:0, artApproved:0},characterFrames:{total:0,artApproved:0}}};
const terminal = new Set(["merged","integrated","device_verified","accepted","superseded","not_planned"]);
const archived = new Set(["superseded","not_planned"]);
let shownLimit = 24;
const statuses = {proposed:"Предложено",ready:"К работе",in_progress:"В работе",PR_review:"PR на ревью",merged:"Смержено",integrated:"Интегрировано",device_verified:"Device QA",accepted:"Принято",blocked:"Блокировано",deferred:"Отложено",superseded:"Заменено",not_planned:"Не планируется"};
const implementation = {not_recorded:"Не зафиксировано",partial:"Реализовано частично",delivered:"Реализовано"};
const verification = {not_recorded:"Не зафиксировано",automated:"Автотесты / без ручного QA",manual_pending:"Ожидает ручной проверки",manual_verified:"Ручная проверка владельцем",device_verified:"Проверено на устройстве"};
const approval = {not_recorded:"Не зафиксировано",pending:"Ожидает приёмки",art_approved:"Арт утверждён",feature_approved:"Функция принята",rejected:"Отклонено"};
const node = (tag,cls,content) => {const e = document.createElement(tag); if(cls)e.className=cls; if(content!==undefined)e.textContent=String(content); return e;};
function field(box,title,value){box.append(node("h4","",title),node("p","",value||"—"));}
function counter(title,value){const e=node("article","stat");e.append(node("b","",value),node("span","",title));$("#stats").append(e);}
function showAssets(data){
  const a=data.assetSummary||cfg.assets;
  $("#art-summary").replaceChildren();
  for(const [title,value] of [["Утверждённые VN-фоны",a.backgrounds],["Утверждённые кадры персонажей",a.characterFrames]]){
    const box=node("div","art-stat");
    box.append(node("strong","",String(value.artApproved)+"/"+String(value.total)),node("span","",title));
    $("#art-summary").append(box);
  }
  $("#art-explainer").textContent=a.note||"Арт-приёмка не означает готовность игровых сцен.";
}
function detail(item){
  const d=node("div","detail");
  field(d,"Задача",item.description||item.title);
  field(d,"Результат",item.deliverable);
  field(d,"Критерии приёмки",item.acceptance);
  const axes=node("div","axes");
  for(const [label,value] of [
    ["Реализация",implementation[item.implementationState]||"Не зафиксировано"],
    ["Проверка",verification[item.qaState]||"Не зафиксировано"],
    ["Утверждение",approval[item.approvalState]||"Не зафиксировано"]]){
    const box=node("div","axis");box.append(node("span","",label),node("strong","",value));axes.append(box);
  }
  d.append(axes);
  if(item.workstreamId)field(d,"Общий рабочий поток",item.workstreamName+" · "+item.workstreamPhase+" · "+item.workstreamId);
  if(item.p2ReentryGroup)field(d,"Возврат P2 по условию",item.p2ReentryGroup);
  field(d,"Активные зависимости",(item.openDependsOn||[]).join(", ")||"нет");
  field(d,"Исторические связи плана",(item.dependsOn||[]).join(", ")||"нет");
  field(d,"Арт/код связи",(item.graphicsDependencies||[]).join(", ")||"—");
  if((item.supersededBy||[]).length)field(d,"Заменено на",item.supersededBy.join(", "));
  if((item.followUpTaskIds||[]).length)field(d,"Незавершённые следующие задачи",item.followUpTaskIds.join(", "));
  field(d,"Оценка / исполнитель",(item.size||"—")+" · "+(item.owner||"не назначен"));
  field(d,"Статус", (statuses[item.status]||item.status)+(item.updated?" · "+item.updated:""));
  field(d,"Evidence",item.evidence||"Не подтверждено");
  field(d,"Источник",item.source||item.sourceDecision||"GFX roadmap");
  const links = Array.from(String(item.evidence||"").matchAll(/https:\/\/github\.com\/bezdredoff\/RavenManor-Godot\/pull\/\d+/g)).map(x=>x[0]);
  if(links.length){const a=node("a","","Открыть связанный PR");a.href=links[links.length-1];a.target="_blank";a.rel="noopener noreferrer";d.append(a);}
  return d;
}
function card(item){
  const box=node("details","task"+(archived.has(item.status)?" archived":""));
  const head=node("summary"),top=node("div","task-head");
  top.append(node("span","id",item.id),node("span","pill "+item.status,statuses[item.status]||item.status));
  head.append(top,node("h3","",item.title));
  const meta=node("div","meta");
  [item.domain,item.stage,item.priority,item.size].filter(Boolean).forEach(x=>meta.append(node("span","",x)));
  if(item.approvalState==="art_approved")meta.append(node("span","art-approved","Арт принят"));
  head.append(meta);box.append(head,detail(item));return box;
}

function acceptanceList(container,heading,items){
  container.append(node("h4","",heading));
  const list=node("ul","");
  for(const item of items){list.append(node("li","",item));}
  container.append(list);
}
function renderAcceptance(data){
  const main=$("#acceptance-streams"),future=$("#p2-groups");
  main.replaceChildren();future.replaceChildren();
  for(const stream of data.workstreams||[]){
    const card=node("details","task"),summary=node("summary","");
    summary.append(node("strong","",stream.title+" · "+stream.taskCount+" задач"));
    summary.append(node("span","meta",stream.phase+" · "+stream.p0Count+" P0 / "+stream.p1Count+" P1"));
    const detail=node("div","detail"),matrix=stream.acceptancePlan;
    field(detail,"Общий gate",stream.gate);
    acceptanceList(detail,"ChatGPT / CI: что можно проверить автоматически",matrix.automatedChecks);
    acceptanceList(detail,"Владелец / реальный Godot / устройство",matrix.ownerChecks);
    acceptanceList(detail,"Новая работа — только при необходимости",matrix.newWorkIfFailed);
    field(detail,"Условие закрытия",matrix.decision);
    card.append(summary,detail);main.append(card);
  }
  for(const group of data.p2Groups||[]){
    const card=node("details","task"),summary=node("summary","");
    summary.append(node("strong","",group.label+" · "+group.taskCount+" задач"));
    const detail=node("div","detail");
    field(detail,"Возвращать при условии",group.trigger);
    field(detail,"Решение",group.action);
    field(detail,"Код группы",group.id);
    card.append(summary,detail);future.append(card);
  }
  if(!main.childElementCount)main.append(node("p","hint","Матрица приёмки отсутствует в реестре."));
  if(!future.childElementCount)future.append(node("p","hint","Политика P2 отсутствует в реестре."));
}

function showPriority(){
  const active=cfg.tasks.filter(t=>t.priority==="P0"&&!terminal.has(t.status));
  active.sort((a,b)=>a.id.localeCompare(b.id));
  const focus=active.slice(0,6);
  const target=$("#quick-tasks");
  target.replaceChildren();
  for(const task of focus){
    const link=node("a","quick-task");
    link.href="#work";
    link.append(node("strong","",task.id),node("span","",task.title),node("small","",statuses[task.status]||task.status));
    link.addEventListener("click",()=>{
      $("#search").value=task.id;
      $("#scope").value="all";
      shownLimit=24;
      render();
    });
    target.append(link);
  }
  target.dataset.spotlightCount=String(focus.length);
  $("#quick-work-info").textContent="Открытых P0-задач: "+active.length+" · показаны первые "+focus.length+". Полный реестр ниже.";
  if(!focus.length)target.append(node("p","hint","Открытых P0-задач в текущем реестре нет."));
}

function progress(domain){
  const arr=cfg.tasks.filter(x=>x.domain===domain);
  const delivered=arr.filter(x=>["merged","integrated","device_verified","accepted"].includes(x.status)).length;
  const ownerAccepted=arr.filter(x=>x.status==="accepted").length;
  $("#"+domain.toLowerCase()+"-meter").style.width=(arr.length?100*delivered/arr.length:0)+"%";
  $("#"+domain.toLowerCase()+"-stats").textContent="Поставлено: "+delivered+"/"+arr.length+" · принято: "+ownerAccepted+" · без ручной приёмки — отдельно";
}
function render(){
  const q=$("#search").value.trim().toLowerCase(),domain=$("#domain").value,status=$("#state").value,priority=$("#priority").value,stage=$("#stage").value,scope=$("#scope").value,workstream=$("#workstream").value;
  const matched=cfg.tasks.filter(t=>{
    const search=[t.id,t.title,t.description,t.deliverable,t.acceptance,t.source,t.evidence,t.workstreamId,t.workstreamName,(t.supersededBy||[]).join(" ")].join(" ").toLowerCase();
    const hasScope = scope==="all" || (scope==="open" && !terminal.has(t.status)) || (scope==="archived" && archived.has(t.status)) || (scope==="qa" && t.qaState==="manual_pending") || (scope==="art" && t.approvalState==="art_approved");
    return hasScope && (!q||search.includes(q)) && (!domain||(domain==="other"?!["CODE","GFX"].includes(t.domain):t.domain===domain)) && (!status||t.status===status) && (!priority||t.priority===priority) && (!stage||t.stage===stage) && (!workstream||t.workstreamId===workstream);
  });
  const order={P0:0,P1:1,P2:2};
  matched.sort((a,b)=>(order[a.priority]??3)-(order[b.priority]??3)||a.id.localeCompare(b.id));
  $("#shown").textContent="Показано "+matched.length+" из "+cfg.tasks.length;
  const target=$("#tasks");target.replaceChildren();
  if(!matched.length){target.append(node("div","empty","Задачи по выбранным фильтрам не найдены."));target.dataset.renderedCount="0";$("#more").hidden=true;return;}
  const fragment=document.createDocumentFragment();for(const task of matched.slice(0,shownLimit))fragment.append(card(task));target.append(fragment);
  target.dataset.renderedCount=String(target.querySelectorAll(".task").length);
  $("#more").hidden=matched.length<=shownLimit;
  $("#more").textContent="Показать ещё задачи ("+Math.min(24,matched.length-shownLimit)+" из "+(matched.length-shownLimit)+")";
}
async function init(){
  try{
    const response=await fetch("./status.json",{cache:"no-store"});if(!response.ok)throw Error("HTTP "+response.status);
    const data=await response.json();if(!Array.isArray(data.tasks))throw Error("Неверный формат JSON");
    cfg.tasks=data.tasks;cfg.assets=data.assetSummary||cfg.assets;
    $("#source").textContent="Обновлено: "+data.updated+" · из "+(data.sourceFiles||[]).length+" канонических источников";
    counter("Всего задач",data.tasks.length);
    counter("Открытый бэклог",data.openTaskCount??data.tasks.filter(x=>!terminal.has(x.status)).length);
    counter("В работе",data.tasks.filter(x=>x.status==="in_progress").length);
    counter("На ревью",data.tasks.filter(x=>x.status==="PR_review").length);
    counter("Закрытая поставка",data.tasks.filter(x=>["merged","integrated","device_verified","accepted"].includes(x.status)).length);
    counter("Формально принято",data.tasks.filter(x=>x.status==="accepted").length);
    counter("В архиве",data.tasks.filter(x=>archived.has(x.status)).length);
    showAssets(data);showPriority();renderAcceptance(data);progress("CODE");progress("GFX");
    Object.entries(statuses).forEach(([key,value])=>{const opt=node("option","",value);opt.value=key;$("#state").append(opt);});
    [...new Set(data.tasks.map(t=>t.stage).filter(Boolean))].sort().forEach(v=>{const opt=node("option","",v);opt.value=v;$("#stage").append(opt);});
    (data.workstreams||[]).forEach(w=>{const opt=node("option","",w.title+" · "+w.taskCount+" задач ("+w.p0Count+" P0)");opt.value=w.id;$("#workstream").append(opt);});
    ["search","domain","state","priority","stage","workstream","scope"].forEach(k=>$("#"+k).addEventListener(k==="search"?"input":"change",()=>{shownLimit=24;render();}));
    $("#more").addEventListener("click",()=>{shownLimit+=24;render();});
    $("#reset").addEventListener("click",()=>{["search","domain","state","priority","stage","workstream"].forEach(k=>$("#"+k).value="");$("#scope").value="open";shownLimit=24;render();});
    render();
  }catch(err){$("#source").textContent="Ошибка отображения реестра: "+String(err.message||err);$("#quick-work-info").textContent="Загрузка не удалась: "+String(err.message||err);$("#tasks").replaceChildren(node("div","empty","Не удалось показать задачи. Откройте status.json из ссылки в верхнем блоке или проверьте опубликованный CI."));$("#more").hidden=true;}
}
init();
