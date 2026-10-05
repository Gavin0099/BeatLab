// Real browser audio clock + actual button input. No forced outcomes or stored scores.
const { chromium } = require(process.env.PLAYWRIGHT_PATH || '/Users/pc49-58/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs = require('fs'), assert = require('assert/strict');
const out='TestResults/GAME-10', checks=[], errors=[];
function check(name,condition){assert.ok(condition,name);checks.push(name)}
(async()=>{
 const browser=await chromium.launch({headless:true,executablePath:process.env.CHROMIUM_PATH,args:['--autoplay-policy=no-user-gesture-required']});
 const page=await browser.newPage({viewport:{width:390,height:844}});
 page.on('pageerror',e=>errors.push(e.message));
 await page.goto('http://127.0.0.1:7810/docs/design/egg-mission/play.html');
 await page.waitForFunction(()=>atlas.complete&&atlas.naturalWidth===1254&&backdrop.complete);
 check('Original atlas + backdrop loaded',true);
 await page.screenshot({path:out+'/concept-ready.png'});
 await page.locator('#action').click();
 check('Real start shows count-in',await page.locator('#action').textContent()==='跳！'&&await page.locator('#result').isHidden());
 await page.waitForFunction(()=>elapsed()>4.5);
 check('No input has a visible recovery',await page.locator('#cue').textContent()==='接住了！下一拍再跳');
 await page.screenshot({path:out+'/concept-miss.png'});
 await page.waitForFunction(()=>ended,{timeout:23000});
 check('Zero input fails with real 0/16 result',(await page.locator('#result').textContent()).includes('再試一次')&&(await page.locator('#result').textContent()).includes('0 / 16'));
 await page.screenshot({path:out+'/concept-fail.png'});
 await page.locator('#action').click();
 check('Retry clears prior result',await page.locator('#result').isHidden()&&await page.evaluate(()=>hits.size===0&&extra===0));
 // Input is triggered on the actual rendered audio cue, never by setting hits.
 for(let i=0;i<16;i++){
  await page.waitForFunction(i=>elapsed()>=4+i,i,{polling:5,timeout:6500});
  await page.locator('#action').dispatchEvent('pointerdown');
 }
 await page.waitForFunction(()=>ended,{timeout:5000});
 const outcome=await page.evaluate(()=>({matched:hits.size,perfect:[...hits.values()].filter(x=>x.perfect).length,extra}));
 check('Sixteen clock-cued inputs reach real success',outcome.matched===16&&outcome.perfect>=9&&outcome.extra===0&&(await page.locator('#result').textContent()).includes('安全回到巢'));
 await page.screenshot({path:out+'/concept-success.png'});
 await page.locator('#action').click();await page.waitForFunction(()=>elapsed()>=4,{polling:5});
 await page.locator('#action').dispatchEvent('pointerdown');await page.locator('#action').dispatchEvent('pointerdown');
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
