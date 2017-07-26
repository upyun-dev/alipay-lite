Alipay = require ".."

{ createServer } = require "http"
body_parser = require "body-parser"
connect = require "connect"
url = require "url"
qs = require "qs"
fs = require "fs"
request = require "request"

cfg =
  host: "http://localhost:65531"
  app_id: "2016080500171563"
  url: "http://openapi.alipaydev.com/gateway.do"
  app_private_key: fs.readFileSync "./app_private_key.pem"
  alipay_public_key: fs.readFileSync "./alipay_public_key.pem"

alipay = new Alipay cfg

q = (req, res, next) ->
  req.query = if req.url.includes "?" then qs.parse url.parse(req.url).query else {}
  next()

# 提供支付服务
router = connect()
router.use q
router.use body_parser.json()
router.use "/pay", (req, res) ->
  order =
    out_trade_no: "345678" # 商户订单号, 商户网站订单系统中唯一订单号，必填
    subject: "测试" # 订单名称 必填
    total_amount: "0.01" # 付款金额,必填
    body: "支付测试使用" # 订单描述

  alipay
  .pay order, "PAGE_PAY"
  .then (resp) -> resp.pipe res

paymentserver = createServer router
paymentserver.listen 65532
