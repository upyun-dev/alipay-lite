try {
  module.exports = require("./lib/alipay-lite");
} catch (e) {
  require("coffeescript/register");
  module.exports = require("./src/alipay-lite");
}
