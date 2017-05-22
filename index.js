try {
  module.exports = require("./lib/alipay-lite");
} catch (e) {
  require("coffee-script/register");
  module.exports = require("./src/alipay-lite");
}
