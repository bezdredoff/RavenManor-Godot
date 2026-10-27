const REPO = "bezdredoff/RavenManor-Godot";
const ROOT = "https://github.com/" + REPO;
const ENDPOINT = "https://api.github.com/repos/" + REPO + "/actions/workflows/pages.yml/runs?event=workflow_dispatch&per_page=100";
const $ = (s) => document.querySelector(s);
const make = (tag, label, cls) => { const x=document.createElement(tag); if(label!==undefined)x.textContent=String(label);if(cls)x.className=cls;return x; };
let items=[];
function card(run){
  const section=make("article",undefined,"card");
  const title=make("h3",run.head_branch || "candidate");
  const outcome=run.conclusion||run.status||"unknown";
  section.append(title,make("div",outcome,"status "+(outcome==="success"?"ok":outcome==="failure"?"bad":"pending")));
  section.append(make("p","SHA: "+String(run.head_sha||"").slice(0,12),"info"),make("p","Run "+run.id+" · "+new Date(run.created_at).toLocaleString(),"info"));
  const link=make("a","Открыть тесты и артефакты");link.href=ROOT+"/actions/runs/"+run.id;link.target="_blank";link.rel="noopener noreferrer";
  section.append(link);return section;
}
function render(){
  const q=$("#query").value.trim().toLowerCase();
  const filtered=items.filter(x=>(x.head_branch+" "+x.head_sha+" "+x.id).toLowerCase().includes(q));
  const root=$("#runs");root.replaceChildren();
  if(!filtered.length)root.append(make("p","Подходящих candidate-сборок нет."));
  else{const frag=document.createDocumentFragment();filtered.forEach(x=>frag.append(card(x)));root.append(frag);}
  $("#status").textContent=items.length+" запусков candidate найдено. Просмотр тестов и загрузка Web-артефактов — в GitHub Actions.";
}
async function refresh(){
  $("#status").textContent="Обновляем последние запуски…";
  try{
    const response=await fetch(ENDPOINT,{headers:{"Accept":"application/vnd.github+json"},cache:"no-store"});
    if(!response.ok)throw new Error("GitHub API returned "+response.status);
    const body=await response.json();
    if(!Array.isArray(body.workflow_runs))throw new Error("Unexpected GitHub API response");
    items=body.workflow_runs.filter(x=>String(x.head_branch||"").startsWith("candidate/mobile-")).sort((a,b)=>Date.parse(b.created_at)-Date.parse(a.created_at));
    render();
  }catch(error){
    $("#status").textContent="Не удалось загрузить GitHub Actions: "+error.message+". Откройте список запусков в GitHub.";
    const a=make("a","Открыть все запуски GitHub Actions");a.href=ROOT+"/actions/workflows/pages.yml";$("#runs").replaceChildren(a);
  }
}
$("#refresh").addEventListener("click",refresh);
$("#query").addEventListener("input",render);
refresh();