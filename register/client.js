const puppeteer = require("puppeteer");
const config = require(process.argv[2]);

let success = true;
const sleep = (seconds) =>
  new Promise((resolve) => setTimeout(resolve, (seconds || 1) * 1000));

(async () => {
  const browser = await puppeteer.launch({
    // headless: false,
    headless: true,
    args: ["--no-sandbox"],
  });
  const page = await browser.newPage();
  await page.goto(
    `https://login.microsoftonline.com/common/oauth2/v2.0/authorize?client_id=${config.client_id}&scope=offline_access%20User.Read&response_type=code&redirect_uri=${config.redirect_uri}`
  );

  try {
    // email
    await page.waitForSelector("input[type=email]");
    await page.type("input[type=email]", config.username);
    // next
    await sleep(1);
    await page.click('[type="submit"]');

    // password
    await page.waitForSelector("input[type=password]");
    await page.type("input[type=password]", config.password);
    // login
    await sleep(3);
    await page.click("[type=submit]");
    await page.waitForNavigation();

    // consent
    await page.waitForSelector("[type=checkbox]");
    await sleep(1);
    await page.click("[type=checkbox]");

    // accept
    await page.waitForSelector("[type=submit]");
    await page.click("[type=submit]");
    // request redirect uri
    await sleep(3);
  } catch (error) {
    console.error(
      `✘ 账号 [${config.username}] 注册失败, 请按照链接说明关闭多因素认证，注册成功后再打开：`,
      "https://docs.microsoft.com/zh-cn/azure/active-directory/fundamentals/concept-fundamentals-security-defaults#disabling-security-defaults",
      error
    );
    success = false;
  }
  await browser.close();
  if (!success) process.exit(1);
})();
