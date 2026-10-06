from pathlib import Path
p=Path('docs/design/runner-motion/play.html').read_text()
p=p.replace('<h1>','<p><label><input id="stable" type="checkbox" checked> Fixed beat arrivals (off: compare early disappearance)</label></p><h1>',1)
p=p.replace('function draw(){','''function obstacleAlpha(id,t,matched,rm){
 if(!matched || t<=4+id)return 1;
 return rm?0:Math.max(0,1-(t-(4+id))/.25);
}
function draw(){''',1)
old="if(hits.has(i)){ctx.fillStyle='#ffd550';ctx.font='26px system-ui';ctx.fillText('✦',x-10,ground-14)}else{if(smooth)cachedSprite(8,x,ground+5,54);else sprite(8,x,ground+5,74)}}"
new="""const alpha=$('stable').checked?obstacleAlpha(i,t,hits.has(i),reduced):hits.has(i)?0:1;
 ctx.globalAlpha=alpha;cachedSprite(8,x,ground+5,54);ctx.globalAlpha=1;
 if(hits.has(i)&&(!$('stable').checked||t>=4+i)){ctx.fillStyle='#ffd550';ctx.font='26px system-ui';ctx.fillText('✦',x-10,ground-64)}}
 const pulse=t>=4&&t<20?1-Math.min(1,(t-4)%1/.12):0;
 if($('stable').checked){ctx.fillStyle=`rgba(22,61,48,${reduced?.55:.3+pulse*.7})`;ctx.fillRect(px-3,ground-20,6,36)}
 window.laneSnapshot={t,width:w,marker:px,stride,rocks:Array.from({length:16},(_,id)=>({id,x:px+(id-(reduced?Math.floor(p):p))*stride,alpha:$('stable').checked?obstacleAlpha(id,t,hits.has(id),reduced):hits.has(id)?0:1}))};"""
assert old in p;p=p.replace(old,new)
Path('docs/design/beat-spacing/play.html').write_text(p)
