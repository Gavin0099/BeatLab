const {chromium}=require('/Users/pc49-58/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('fs'),assert=require('assert/strict');
(async()=>{
 const browser=await chromium.launch({headless:true,executablePath:'/Users/pc49-58/Library/Caches/ms-playwright/chromium_headless_shell-1243/chrome-headless-shell-mac-arm64/chrome-headless-shell',args:['--autoplay-policy=no-user-gesture-required']});
 const results=[];
 for(const theme of ['cat','robot']){
  const page=await browser.newPage({viewport:{width:390,height:844}}),errors=[],checks=[];
  page.on('pageerror',e=>errors.push(e.message));
  function check(name,condition){assert.ok(condition,name);checks.push(name)}
  await page.goto('http://127.0.0.1:7811/docs/design/companion-motion/play.html');
  await page.locator('#theme').selectOption(theme);
  await page.waitForFunction(()=>animationAtlas.complete&&animationAtlas.naturalWidth===1024&&backdrop.complete&&backdrop.naturalWidth>0);
  check('Theme original atlas/backdrop loaded',true);
  await page.screenshot({path:`docs/design/companion-motion/${theme}-ready.png`});
  await page.locator('#action').click();await page.waitForFunction(()=>ended,{timeout:25000});
  check('No-input real failure 0/16',(await page.locator('#result').textContent()).includes('0 / 16')&&(await page.locator('#result').textContent()).includes('再試一次'));
  await page.locator('#action').click();check('Retry clears outcome',await page.evaluate(()=>hits.size===0&&extra===0&&!ended));
  await page.evaluate(()=>new Promise(resolve=>{let i=0;const timer=setInterval(()=>{if(elapsed()>=4+i){$('action').dispatchEvent(new PointerEvent('pointerdown',{bubbles:true}));i++}if(i===16){clearInterval(timer);resolve()}},5)}));
  await page.waitForFunction(()=>ended,{timeout:5000});
  const outcome=await page.evaluate(()=>({matched:hits.size,perfect:[...hits.values()].filter(x=>x.perfect).length,extra}));
  check('Clock-cued genuine input success',outcome.matched===16&&outcome.perfect>=9&&outcome.extra===0);
  check('Themed actual completion', (await page.locator('#result').textContent()).includes(theme==='cat'?'魚送到小屋':'能源送到充電站'));
  await page.screenshot({path:`docs/design/companion-motion/${theme}-success.png`});
  await page.locator('#action').click();await page.waitForFunction(()=>elapsed()>=4,{polling:5});
  await page.locator('#action').dispatchEvent('pointerdown');await page.locator('#action').dispatchEvent('pointerdown');
  check('Duplicate/Extra no advance',await page.evaluate(()=>hits.size===1&&extra===1&&lastMatched.kind!=='extra'));
  await page.locator('#stop').click();check('Cancel no result',await page.evaluate(()=>!active&&!ended&&$('result').hidden));
  for(const [width,height] of [[320,568],[430,932]]){await page.setViewportSize({width,height});check('No horizontal overflow '+width,await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));}
  check('No runtime errors',errors.length===0);results.push({theme,checks,outcome,errors});await page.close();
 }
 fs.writeFileSync('TestResults/GAME-13/concept-report.json',JSON.stringify(results,null,2));await browser.close();console.log(JSON.stringify(results));
})().catch(e=>{fs.writeFileSync('TestResults/GAME-13/concept-failure.txt',e.stack);console.error(e);process.exit(1)});
