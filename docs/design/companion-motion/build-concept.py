from pathlib import Path
import json
here = Path(__file__).parent
text = (here.parent/'runner-motion/play.html').read_text()
text = text.replace('<h1>把恐龍蛋帶回家</h1>', '<p><label>選夥伴 <select id="theme"><option value="cat">貓咪雲端</option><option value="robot">機器人科技平台</option></select></label></p><h1 id="missionTitle">把魚送回雲端小屋</h1>')
text = text.replace("const atlas=new Image();", "const themeData="+json.dumps(json.loads((here/'art-source.json').read_text()))+";\nlet theme='cat';\nconst atlas=new Image();")
text = text.replace("animationAtlas.src='../../../BeatLab/Resources/Assets.xcassets/EggMotionAtlas.imageset/artwork.png';", "animationAtlas.src='../../../BeatLab/Resources/Assets.xcassets/CatMotionAtlas.imageset/artwork.png';\nfunction applyTheme(){theme=$('theme').value;animationAtlas.src='../../../BeatLab/Resources/Assets.xcassets/'+(theme==='cat'?'CatMotionAtlas':'RobotMotionAtlas')+'.imageset/artwork.png';backdrop.src='../../../BeatLab/Resources/Assets.xcassets/'+(theme==='cat'?'RunnerCloud':'RunnerCircuit')+'.imageset/artwork.png';animatedCache.length=0;backdropSize='';backdropCache=null;$('missionTitle').textContent=theme==='cat'?'把魚送回雲端小屋':'把能源送回充電站';$('theme').disabled=active;}\n$('theme').onchange=applyTheme;")
start=text.index('function animatedSprite('); end=text.index('function background(',start)
text=text[:start]+'''function themedSprite(index,x,foot,size,sx=1,sy=1,angle=0){
 if(!animationAtlas.complete||!animationAtlas.naturalWidth)return;
 const f=themeData[theme==='cat'?'CatMotionAtlas':'RobotMotionAtlas'].frames[index], c=f.cell,b=f.bbox;
 const scale=index<18?size/240:size/(b[3]-b[1]);
 ctx.save();ctx.translate(x,foot);ctx.rotate(angle);ctx.scale(sx,sy);
 ctx.drawImage(animationAtlas,c[0]+b[0],c[1]+b[1],b[2]-b[0],b[3]-b[1],-(b[2]-b[0])*scale/2,-(b[3]-b[1])*scale,(b[2]-b[0])*scale,(b[3]-b[1])*scale);ctx.restore();
}
function animatedSprite(...args){themedSprite(...args)}
function themeSprite(index,x,y,size){themedSprite(index===8?20:index===7?19:index===6?18:index===5?17:16,x,y,size)}
''' +text[end:]
text=text.replace("cachedSprite(8,x,ground+5,54)","themeSprite(8,x,ground+5,38)")
text=text.replace("cachedSprite(pose,px,ground+5-hop-bob,Math.min(145,w*.37),m.sx,m.sy,m.angle)","themeSprite(pose,px,ground+5-hop-bob,Math.min(145,w*.37))")
text=text.replace("cachedSprite(7,Math.min(w*1.4,nestX),ground+12,65)","themeSprite(7,Math.min(w*1.4,nestX),ground+12,65)")
text=text.replace("ctx.fillStyle='#a8d985'", "ctx.fillStyle=theme==='cat'?'#ffe4d5':'#5ac9ec'").replace("ctx.fillStyle='#d9ad69'", "ctx.fillStyle=theme==='cat'?'#fff5ea':'#547ab5'")
text=text.replace("const bob=smooth", "const bob=smooth").replace("Math.sin(t*Math.PI*10)*2", "Math.sin(t*Math.PI*(theme==='cat'?8:12))*(theme==='cat'?2.5:1)")
text=text.replace("if(active&&t>=20.18)finish();", "$('theme').disabled=active;if(active&&t>=20.18)finish();")
text=text.replace("'蛋安全回到巢了！'", "theme==='cat'?'魚送到小屋了！':'能源送到充電站了！'")
text=text.replace("漂亮！蛋亮起來了", "漂亮！包裹亮起來了").replace("恐龍接住蛋了，再試一次", "包裹接住了，再試一次").replace("守護恐龍蛋，跟著鼓声前進。", "守護包裹，跟著鼓聲前進。").replace("把蛋帶回巢", "跟拍送包裹").replace("蛋在你手上", "包裹在你手上").replace("石頭來到腳下", "障礙來到腳下").replace("石頭到腳下", "障礙到腳下")
text=text.replace("requestAnimationFrame(draw);\n</script>", "applyTheme();requestAnimationFrame(draw);\n</script>")
text=text.replace('目的地：溫暖的巢','目的地：夥伴的家').replace('16 個拍點，陪恐龍一路回家','16 個拍點，跟拍送包裹回家').replace('恐龍帶著蛋，跟著拍子跨過石頭前往巢穴','夥伴帶著包裹，跟拍跨過障礙').replace('蛋準備好了','包裹準備好了').replace('把蛋帶回家','送包裹回家').replace('巢就在這裡','目的地就在這裡').replace('蛋安全回到巢','包裹安全送到家').replace('連續動作幀（關閉可比較上一版）','連續動作幀').replace('<p><label><input id="smooth" type="checkbox" checked> 連續動作幀</label></p>','<input id="smooth" type="checkbox" checked hidden>')
(here/'play.html').write_text(text)
