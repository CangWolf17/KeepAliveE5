const fs = require("fs");
const qs = require("qs");
const axios = require("axios");
const express = require("express");

const configFile = process.argv[2];
const config = require(configFile);
const app = express();

app.get("/", async (req, res) => {
  res.send(req.query.code);

  const resp = await axios.post(
    "https://login.microsoftonline.com/common/oauth2/v2.0/token",
    qs.stringify({
      client_id: config.client_id,
      client_secret: config.client_secret,
      code: req.query.code,
      redirect_uri: config.redirect_uri,
      grant_type: "authorization_code",
    })
  );

  let success = false;
  server.close(() => {
    try {
      config.refresh_token = resp.data.refresh_token;
      fs.writeFileSync(configFile, JSON.stringify(config));

      success = config.refresh_token && config.refresh_token.length > 50;

    } catch (error) {
      console.error(`✘ 账号 [${config.username}] 注册失败, 请按照链接说明关闭多因素认证，注册成功后再打开：`,
        "https://docs.microsoft.com/zh-cn/azure/active-directory/fundamentals/concept-fundamentals-security-defaults#disabling-security-defaults",
        error
      );
    }
    if (success) console.log(`✔ 账号 [${config.username}] 注册成功.`);
    else process.exit(1);
  });
});

const server = app.listen(config.redirect_uri.match(/\d+/)[0]);
