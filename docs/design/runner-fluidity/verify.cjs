// Real browser audio clock + actual button input. No forced outcomes or stored scores.
const { chromium } = require(process.env.PLAYWRIGHT_PATH || '/Users/pc49-58/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs = require('fs'), assert = require('assert/strict');
const out='TestResults/GAME-11', checks=[], errors=[];
function check(name,condition){assert.ok(condition,name);checks.push(name)}
(async()=>{
 const browser=await chromium.launch({headless:true,executablePath:process.env.CHROMIUM_PATH,args:['--autoplay-policy=no-user-gesture-required']});
 const page=await browser.newPage({viewport:{width:390,height:844}});
 page.on('pageerror',e=>errors.push(e.message));
 await page.goto('http://127.0.0.1:7811/docs/design/runner-fluidity/play.html');
 await page.waitForFunction(()=>atlas.complete&&atlas.naturalWidth===1254&&backdrop.complete);
 check('Original atlas + backdrop loaded',true);
 await page.waitForFunction(()=>spriteCache[2]&&spriteCache[7]&&spriteCache[2].getContext('2d').getImageData(180,180,1,1).data[3]>0);
 check('Cached loaded character has actual opaque pixels',true);
 const fixture=await page.evaluate(()=>{
 const a=motion(11.9999,.2,'perfect',false),b=motion(12.0001,.2002,'perfect',false);
 return {resetDelta:Math.abs(b.drift-a.drift),rise:motion(5,.01,'perfect',false).height,land:motion(5,.56,'perfect',false),rm:motion(5,.24,'perfect',true)};
 });
 check('Background is continuous at old 8-second reset',fixture.resetDelta<.001);
 check('Immediate positive rise and finite landing follow-through',fixture.rise>0&&fixture.land.height===0&&fixture.land.sx>1&&fixture.land.sy<1);
 check('Reduced motion has no hop/rotation/stretch',fixture.rm.height===0&&fixture.rm.angle===0&&fixture.rm.sx===1);

 await page.screenshot({path:out+'/concept-ready.png'});
 await page.locator('#action').click();
 check('Real start shows count-in',await page.locator('#action').textContent()==='跳！'&&await page.locator('#result').isHidden());
 await page.waitForFunction(()=>elapsed()>4.5);
 check('No input has a visible recovery',await page.locator('#cue').textContent()==='接住了！下一拍再跳');
 await page.screenshot({path:out+'/concept-miss.png'});
 await page.waitForFunction(()=>ended,{timeout:23000});
 check('Zero input fails with real 0/16 result',(await page.locator('#result').textContent()).includes('再試一次')&&(await page.locator('#result').textContent()).includes('0 / 16'));
 check('Stop is visually hidden on actual failure',await page.locator('#stop').isHidden());
 await page.screenshot({path:out+'/concept-fail.png'});
 await page.locator('#action').click();
 check('Retry clears prior result',await page.locator('#result').isHidden()&&await page.evaluate(()=>hits.size===0&&extra===0));
 // Input is triggered on the actual rendered audio cue, never by setting hits.
 await page.evaluate(()=>new Promise(resolve=>{
  let i=0;const input=setInterval(()=>{
   if(elapsed()>=4+i){document.getElementById('action').dispatchEvent(new PointerEvent('pointerdown',{bubbles:true}));i++}
   if(i===16){clearInterval(input);resolve()}
  },5);
 }));
 await page.waitForFunction(()=>ended,{timeout:5000});
 const outcome=await page.evaluate(()=>({matched:hits.size,perfect:[...hits.values()].filter(x=>x.perfect).length,extra}));
 fs.writeFileSync(out+'/concept-input-outcome.json',JSON.stringify(outcome,null,2));
 check('Sixteen clock-cued inputs reach real success',outcome.matched===16&&outcome.perfect>=9&&outcome.extra===0&&(await page.locator('#result').textContent()).includes('安全回到巢'));
 check('Stop is visually hidden on actual success',await page.locator('#stop').isHidden());
 await page.screenshot({path:out+'/concept-success.png'});
 await page.locator('#action').click();await page.waitForFunction(()=>elapsed()>=4,{polling:5});
 await page.locator('#action').dispatchEvent('pointerdown');await page.locator('#action').dispatchEvent('pointerdown');
 const retained=await page.evaluate(()=>lastMatched?.kind!=='extra'&&last.kind==='extra'&&lastMatched.id===0);
 check('Extra does not replace the accepted airborne action',retained);
 check('Duplicate press is extra and does not clear a second rock',await page.evaluate(()=>hits.size===1&&extra===1)&&(await page.locator('#cue').textContent()).includes('先站穩'));
 await page.locator('#stop').click();
 check('Cancel stops without a result',await page.locator('#result').isHidden()&&await page.evaluate(()=>!active&&!ended));
 for(const [w,h] of [[320,568],[375,667],[430,932]]){
  await page.setViewportSize({width:w,height:h});
  check(`No horizontal overflow at ${w}`,await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));
  await page.locator('#action').scrollIntoViewIfNeeded();check(`Action reachable at ${w}`,await page.locator('#action').isVisible());
 }
 check('No browser runtime errors',errors.length===0);
 fs.writeFileSync(out+'/concept-report.json',JSON.stringify({checks,outcome,errors,hardwareTiming:'NOT RUN',ownerAppeal:'PENDING'},null,2));
 await browser.close();console.log(JSON.stringify({passed:checks.length,outcome}));
})().catch(e=>{fs.writeFileSync(out+'/concept-failure.json',JSON.stringify({checks,errors,error:e.stack},null,2));console.error(e);process.exit(1)});
