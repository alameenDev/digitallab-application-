const { chromium } = require('playwright');
const fs = require('fs');
(async () => {
  fs.mkdirSync('previews', { recursive: true });
  const browser = await chromium.launch({ headless: true, args: ['--no-sandbox'] });
  const page = await browser.newPage({ viewport: { width: 390, height: 900 }, deviceScaleFactor: 1 });
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  await page.goto('http://127.0.0.1:8000', { waitUntil: 'networkidle' });
  await page.waitForFunction(() => document.querySelector('flutter-view') !== null, null, { timeout: 60000 });
  await page.waitForTimeout(3500);
  await page.screenshot({ path: 'previews/initial-mobile.png' });
  const semantics = page.locator('flt-semantics-placeholder');
  if (await semantics.count()) await semantics.evaluate(element => element.click());
  await page.waitForTimeout(500);
  const first = page.getByRole('button', { name: 'عرض البانر 1', exact: true });
  if (await first.count()) {
    for (let i = 1; i <= 3; i++) {
      await page.getByRole('button', { name: 'عرض البانر ' + i, exact: true }).dispatchEvent('click');
      await page.waitForTimeout(500);
      await page.screenshot({ path: 'previews/banner-' + i + '-mobile.png' });
    }
    await first.dispatchEvent('click');
    await page.waitForTimeout(500);
  }
  await page.screenshot({ path: 'previews/home-ar-mobile.png' });
  await page.mouse.move(195, 700);
  await page.mouse.wheel(0, 720);
  await page.waitForTimeout(700);
  await page.screenshot({ path: 'previews/features-ar-mobile.png' });
  await page.mouse.wheel(0, -4000);
  await page.setViewportSize({ width: 1366, height: 1000 });
  await page.waitForTimeout(1000);
  await page.screenshot({ path: 'previews/home-ar-desktop.png' });
  console.log('PREVIEW_MOBILE_BASE64=' + fs.readFileSync('previews/home-ar-mobile.png').toString('base64'));
  console.log('PREVIEW_FEATURES_BASE64=' + fs.readFileSync('previews/features-ar-mobile.png').toString('base64'));
  fs.writeFileSync('previews/browser-errors.json', JSON.stringify(errors, null, 2));
  await browser.close();
  if (errors.length) throw new Error(errors.join('\n'));
})().catch(error => { console.error(error); process.exit(1); });
