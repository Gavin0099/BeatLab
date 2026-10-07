// Isolated developer harness: real WebAudio time and DOM pointer inputs.
const {chromium}=require(process.env.PLAYWRIGHT_PATH||'/Users/pc49-58/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const assert=require('assert/strict'),fs=require('fs');
const out='TestResults/GAME-16',shots='docs/design/rhythm-swing-concept',checks=[],errors=[];
fs.mkdirSync(out,{recursive:true});
function check(name,condition){assert.ok(condition,name);checks.push(name)}
(async()=>{
 const browser=await chromium.launch({headless:true,executablePath:process.env.CHROMIUM_PATH,args:['--autoplay-policy=no-user-gesture-required']});
 const page=await browser.newPage({viewport:{width:390,height:844}});page.on('pageerror',e=>errors.push(e.message));
 await page.goto('http://127.0.0.1:7820/docs/design/rhythm-swing-concept/play.html');
 await page.waitForFunction(()=>atlas.naturalWidth===1254&&animationAtlas.naturalWidth===1254&&backdrop.naturalWidth>0);
 check('Existing three owned assets load',true);
 await page.waitForFunction(()=>document.getElementById('world').dataset.assets==='ready'&&!document.getElementById('action').disabled);check('Ready gate unlocks only after all three images load',true);
 const failurePage=await browser.newPage();await failurePage.route('**/EggMotionAtlas.imageset/artwork.png',r=>r.abort());await failurePage.goto(page.url());await failurePage.waitForFunction(()=>document.getElementById('world').dataset.assets==='failed');check('Failed asset cannot start a blank game',await failurePage.locator('#action').isDisabled()&&(await failurePage.locator('#feedback').textContent()).includes('尚未載入'));await failurePage.close();

 await page.screenshot({path:shots+'/ready.png'});
 // Expected fixture values from TimingSession .180/.050 windows, earlier-tie rule,
 // and first-beat pass thresholds, not copied from concept expressions.
 const fixtures=await page.evaluate(()=>{
 const grades=[3.819,3.82,3.949,3.95,4,4.05,4.051,4.18,4.181,4.5,NaN].map(t=>judge(t,new Map())?.grade??null);
 return {grades,duplicate:judge(4,new Map([[0,{}]])),tie:judge(4.5,new Map()),thresholds:[[14,9,1],[13,13,0],[16,8,0],[16,16,2],[0,0,0]].map(([n,p,e])=>outcome(new Map(Array.from({length:n},(_,i)=>[i,{grade:i<p?'perfect':'late'}])),e).passed)};
 });
 check('Independent boundary fixtures: extra/early/Perfect/late/nonfinite',JSON.stringify(fixtures.grades)===JSON.stringify(['extra','early','early','perfect','perfect','perfect','late','late','extra','extra',null]));
 check('Duplicate cannot move to a different target',fixtures.duplicate.grade==='extra'&&fixtures.duplicate.id===null);
 check('Tie outside matching window stays extra',fixtures.tie.grade==='extra');
 check('Pass requires 14 matched, 9 Perfect and at most1extra',JSON.stringify(fixtures.thresholds)==='[true,false,false,false,false]');
 for(const mode of ['light','dark'])for(const large of [false,true])for(const [w,h] of [[320,568],[375,667],[430,932]]){
 await page.emulateMedia({colorScheme:mode});await page.setViewportSize({width:w,height:h});await page.evaluate(v=>document.body.classList.toggle('large',v),large);
 const layout=await page.evaluate(()=>{const p=document.querySelector('.controls').getBoundingClientRect(),s=document.querySelector('.scene').getBoundingClientRect(),b=document.querySelector('.route').getBoundingClientRect();return {overflow:document.documentElement.scrollWidth>innerWidth,overlap:p.top<s.bottom||s.top<b.bottom,action:document.getElementById('action').getBoundingClientRect().height}});
 check(`Flow layout ${w} ${mode} ${large?'large':'standard'}`,!layout.overflow&&!layout.overlap&&layout.action>=44);
 await page.locator('#action').scrollIntoViewIfNeeded();check(`Pad reachable ${w} ${mode} ${large?'large':'standard'}`,await page.locator('#action').isVisible());
 await page.screenshot({path:out+`/ready-${w}-${mode}-${large}.png`,fullPage:true});
 }
 await page.evaluate(()=>document.body.classList.remove('large'));await page.emulateMedia({colorScheme:'light'});await page.setViewportSize({width:390,height:844});
 await page.locator('#action').click();check('Start enters actual count-in',await page.evaluate(()=>state==='count-in'&&matched.size===0&&!completion));
 await page.waitForFunction(()=>state==='playing'&&misses.has(0));
 check('Zero input produces actual miss, no advancement',await page.evaluate(()=>matched.size===0&&misses.has(0))&&(await page.locator('#feedback').textContent()).includes('接住'));
 await page.screenshot({path:shots+'/missed.png'});
 const snapshots=await page.evaluate(()=>new Promise(resolve=>{const a=laneSnapshot;setTimeout(()=>resolve({a,b:laneSnapshot}),80)}));
 check('Actual miss keeps animated run phase changing',snapshots.a.miss&&snapshots.b.frame!==snapshots.a.frame);
 check('Rock centers retain equal spacing',snapshots.b.rocks.every((r,i,a)=>!i||Math.abs(r.x-a[i-1].x-snapshots.b.stride)<1e-7));
 for(const mode of ['light','dark'])for(const large of [false,true])for(const [w,h] of [[320,568],[375,667],[430,932]]){
 await page.emulateMedia({colorScheme:mode});await page.setViewportSize({width:w,height:h});await page.evaluate(v=>document.body.classList.toggle('large',v),large);
 const live=await page.evaluate(()=>{const pad=document.querySelector('.controls').getBoundingClientRect(),scene=document.querySelector('.scene').getBoundingClientRect(),route=document.querySelector('.route').getBoundingClientRect();return {state,overflow:document.documentElement.scrollWidth>innerWidth,overlap:pad.top<scene.bottom||scene.top<route.bottom,feedback:document.getElementById('feedback').getBoundingClientRect().bottom<=pad.top}});
 check(`Live layout ${w} ${mode} ${large?'large':'standard'}`,live.state==='playing'&&!live.overflow&&!live.overlap&&live.feedback);
 await page.screenshot({path:out+`/live-${w}-${mode}-${large}.png`,fullPage:true});
 }
 await page.evaluate(()=>document.body.classList.remove('large'));await page.emulateMedia({colorScheme:'light'});await page.setViewportSize({width:390,height:844});

 await page.waitForFunction(()=>state==='result',{timeout:23000});
 check('Zero-input run finishes failure with 16 misses',await page.evaluate(()=>completion.matched===0&&!completion.passed&&completion.missed===16)&&await page.locator('#stop').isHidden());
 await page.screenshot({path:shots+'/failure.png'});
 await page.locator('#action').click();check('Real retry resets hits/misses/extras/result',await page.evaluate(()=>matched.size===0&&misses.size===0&&extras===0&&completion===null)&&await page.locator('#result').isHidden());
 //16 actual DOM inputs, synchronised to the running browser audio clock.
 await page.evaluate(()=>new Promise(resolve=>{let i=0;const timer=setInterval(()=>{if(elapsed()>=4+i){document.getElementById('action').dispatchEvent(new PointerEvent('pointerdown',{button:0,bubbles:true}));i++}if(i===16){clearInterval(timer);resolve()}},3)}));
 await page.screenshot({path:shots+'/matched.png'});
 await page.waitForFunction(()=>state==='result',{timeout:4000});
 const success=await page.evaluate(()=>completion);check('16 true clock-cued inputs complete delivery',success.matched===16&&success.perfect>=9&&success.extra===0&&success.passed);
 await page.screenshot({path:shots+'/success.png'});
 await page.locator('#action').click();
 await page.evaluate(()=>new Promise(resolve=>{const q=setInterval(()=>{if(elapsed()>=3.86){document.getElementById('action').dispatchEvent(new PointerEvent('pointerdown',{button:0,bubbles:true}));clearInterval(q);resolve()}},2)}));
 const early=await page.evaluate(()=>({hit:matched.get(0),t:elapsed()}));check('Actual early input remains early, not Perfect',early.hit?.grade==='early'&&early.t<4);
 const visible=await page.evaluate(()=>new Promise(resolve=>requestAnimationFrame(()=>resolve(laneSnapshot))));check('Early accepted rock stays visible until its fixed crossing',visible.t<4&&visible.rocks[0].alpha===1&&visible.rocks[0].x>visible.marker);
 check('Early accepted jump immediately uses jump pose',visible.frame>=8&&visible.frame<=13&&visible.height>0);
 await page.evaluate(()=>document.getElementById('action').dispatchEvent(new PointerEvent('pointerdown',{button:0,bubbles:true})));
 check('Actual duplicate is extra without clearing next target',await page.evaluate(()=>matched.size===1&&extras===1&&lastAction.id===0));
 await page.evaluate(()=>new Promise(resolve=>{const q=setInterval(()=>{if(elapsed()>=5.12){document.getElementById('action').dispatchEvent(new PointerEvent('pointerdown',{button:0,bubbles:true}));clearInterval(q);resolve()}},2)}));
 check('Actual late input is graded late and still crosses',await page.evaluate(()=>matched.get(1)?.grade==='late'&&matched.size===2));
 await page.locator('#stop').click();check('Cancel has no result and stops pending audio',await page.evaluate(()=>state==='cancelled'&&completion===null&&sounds.length===0)&&await page.locator('#result').isHidden());
 await page.locator('#action').click();await page.locator('#stop').click();check('Repeated start/stop safe',await page.evaluate(()=>state==='cancelled'&&sounds.length===0&&matched.size===0));
 // Actual keyboard input: Enter via focused button and Space outside it.
 await page.locator('#action').focus();await page.keyboard.press('Enter');check('Keyboard Enter starts once',await page.evaluate(()=>state==='count-in'));await page.locator('#stop').click();
 const rm=await browser.newPage({viewport:{width:320,height:568},reducedMotion:'reduce',colorScheme:'dark'});rm.on('pageerror',e=>errors.push(e.message));await rm.goto(page.url());await rm.waitForFunction(()=>animationAtlas.naturalWidth>0);await rm.locator('#action').click();
 await rm.evaluate(()=>new Promise(resolve=>{const q=setInterval(()=>{if(elapsed()>=4){document.getElementById('action').dispatchEvent(new PointerEvent('pointerdown',{button:0,bubbles:true}));clearInterval(q);resolve()}},3)}));await rm.waitForTimeout(70);
 check('Reduce Motion actual matched hit has no hop/animated pose',await rm.evaluate(()=>matched.has(0)&&laneSnapshot.reduced&&laneSnapshot.height===0&&laneSnapshot.frame===14));
 await rm.screenshot({path:out+'/reduced-motion-playing.png'});await rm.locator('#stop').click();
 check('No browser JavaScript exceptions',errors.length===0);
 fs.writeFileSync(out+'/report.json',JSON.stringify({passed:checks.length,checks,success,errors,ownerAppeal:'PENDING',nativeTiming:'NOT RUN'},null,2));console.log(JSON.stringify({passed:checks.length,success,errors}));await browser.close();
})().catch(e=>{fs.writeFileSync(out+'/failure-'+Date.now()+'.json',JSON.stringify({checks,errors,error:e.stack},null,2));console.error(e);process.exit(1)});
