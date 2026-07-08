const DB_API='http://127.0.0.1:8767/api';
var dashboardChannels=[],dashboardSpecializations=[],dashboardPeriods=[];
async function loadDashboardPeriod(year,quarter){
 [dashboardChannels,dashboardSpecializations]=await Promise.all([
  fetch(`${DB_API}/partners?year=${year}&quarter=${quarter}`).then(r=>r.json()).then(rows=>rows.map(x=>({channel:x.channel,level:x.level,integrator:!!x.integrator,msspAccount:!!x.mssp_account,mssp:!!x.mssp,owner:x.owner}))),
  fetch(`${DB_API}/specializations?year=${year}&quarter=${quarter}`).then(r=>r.json())
 ]);
 return {year:Number(year),quarter:Number(quarter)}
}
window.dashboardDataReady=(async()=>{
 dashboardPeriods=await fetch(`${DB_API}/periods`).then(r=>r.json());
 if(!dashboardPeriods.length){
  const badge=document.querySelector('header>span');
  if(badge)badge.textContent='● Nenhuma base importada';
  return {year:'',quarter:'',empty:true}
 }
 const latest=dashboardPeriods[0];
 await loadDashboardPeriod(latest.year,latest.quarter);
 const badge=document.querySelector('header>span');
 if(badge)badge.textContent=`● Base atualizada · ${dashboardChannels.length} canais`;
 return latest
})();
