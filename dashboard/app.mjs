const $ = (s) => document.querySelector(s);
const cfg = { tasks: [] };
const node = (tag, cls, content) => { const e = document.createElement(tag); if (cls) e.className = cls; if (content !== undefined) e.textContent = String(content); return e; };
const statuses = { proposed:"Предложено", ready:"К работе", in_progress:"В работе", PR_review:"PR на ревью", merged:"Смержено", integrated:"Интегрировано", device_verified:"Device QA", accepted:"Принято", blocked:"Блокировано", deferred:"Отложено" };
function field(box,title,value){box.append(node("h4","",title),node("p","",value||"—"))}
function counter(title,value){const card=node("article","stat");card.append(node("b","",value),node("span","",title));$("#stats").append(card)}
function detail(item){
  const d=node("div","detail");
  field(d,"Задача",item.description||item.title);
  field(d,"Что должно получиться",item.deliverable);
  field(d,"Приёмка",item.acceptance);
  field(d,"Зависимости",(item.dependsOn||[]).join(", ")||"нет");
  field(d,"Арт/код связи",(item.graphicsDependencies||[]).join(", ")||"—");
  field(d,"Размер / исполнитель",(item.size||"—")+" · "+(item.owner||"не назначен"));
  field(d,"Обновление",(statuses[item.status]||item.status)+(item.updated?" · "+item.updated:""));
  field(d,"Evidence",item.evidence||"Не подтверждено");
  field(d,"Источник",item.source||item.sourceDecision||"GFX roadmap");
  const evidence=typeof item.evidence==="string" ? item.evidence.split(" ")[0] : "";
  if(/^https:\/\/github\.com\/[^\s]+$/.test(evidence)){const a=node("a","","Открыть GitHub evidence");a.href=evidence;a.target="_blank";a.rel="noopener noreferrer";d.append(a)}
  return d;
}
function card(item){
  const box=node("details","task"), head=node("summary"), row=node("div","task-head");
  row.append(node("span","id",item.id),node("span","pill "+item.status,statuses[item.status]||item.status));
  head.append(row,node("h3","",item.title));
  const meta=node("div","meta");
  [item.domain,item.stage,item.priority,item.size].filter(Boolean).forEach(x=>meta.append(node("span","",x)));
  head.append(meta);box.append(head,detail(item));return box;
}
function progress(domain){
  const arr=cfg.tasks.filter(x=>x.domain===domain);
  const accepted=arr.filter(x=>x.status==="accepted").length;
  const shipped=arr.filter(x=>["merged","integrated","device_verified","accepted"].includes(x.status)).length;
  $("#"+domain.toLowerCase()+"-meter").style.width=(arr.length?100*accepted/arr.length:0)+"%";
  $("#"+domain.toLowerCase()+"-stats").textContent="Принято: "+accepted+"/"+arr.length+" · merged+: "+shipped+" (не обязательно принято)";
}
function render(){
  const q=$("#search").value.trim().toLowerCase(),domain=$("#domain").value,status=$("#state").value,priority=$("#priority").value,stage=$("#stage").value;
  const found=cfg.tasks.filter(t=>{
    const searchable=[t.id,t.title,t.description,t.deliverable,t.acceptance,t.source,t.evidence].join(" ").toLowerCase();
    return (!q||searchable.includes(q)) && (!domain||(domain==="other"?!["CODE","GFX"].includes(t.domain):t.domain===domain)) && (!status||t.status===status)&&(!priority||t.priority===priority)&&(!stage||t.stage===stage);
  });
  $("#shown").textContent="Показано "+found.length+" из "+cfg.tasks.length;
  const target=$("#tasks");target.replaceChildren();
  if(!found.length){target.append(node("div","empty","Нет задач для выбранного фильтра."));return}
  const fragment=document.createDocumentFragment();
  found.forEach(item=>fragment.append(card(item)));target.append(fragment);
}
async function init(){
  try{
    const response=await fetch("./status.json",{cache:"no-cache"});
    if(!response.ok)throw new Error("HTTP "+response.status);
    const data=await response.json();
    if(!Array.isArray(data.tasks))throw new Error("Неправильный формат данных");
    cfg.tasks=data.tasks;
    $("#source").textContent="Обновлено: "+data.updated+" · "+data.sourceFiles.join(" · ");
    counter("Всего задач",data.tasks.length);
    counter("Принято",data.tasks.filter(x=>x.status==="accepted").length);
    counter("Смержено",data.tasks.filter(x=>x.status==="merged").length);
    counter("В работе / PR",data.tasks.filter(x=>["in_progress","PR_review"].includes(x.status)).length);
    counter("Процессы / риски",data.tasks.filter(x=>!["CODE","GFX"].includes(x.domain)).length);
    progress("CODE");progress("GFX");
    Object.entries(statuses).forEach(([key,value])=>{const opt=node("option","",value);opt.value=key;$("#state").append(opt)});
    [...new Set(data.tasks.map(x=>x.stage).filter(Boolean))].sort().forEach(s=>{const opt=node("option","",s);opt.value=s;$("#stage").append(opt)});
    ["search","domain","state","priority","stage"].forEach(s=>$("#"+s).addEventListener(s==="search"?"input":"change",render));
    $("#reset").addEventListener("click",()=>{["search","domain","state","priority","stage"].forEach(s=>$("#"+s).value="");render()});
    render();
  }catch(err){
    $("#source").textContent="Не удалось загрузить status.json: "+String(err.message||err)+". Сгенерируйте данные build_production_dashboard.py и откройте через HTTP или Pages.";
    $("#tasks").append(node("div","empty","Не подменяем отсутствие данных предположениями о прогрессе."));
  }
}
init();