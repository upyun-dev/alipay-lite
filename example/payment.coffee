require "./yamlc"

Alipay = require ".."
cfg = require "./config"

{ createServer } = require "http"
body_parser = require "body-parser"
connect = require "connect"
url = require "url"
qs = require "qs"
fs = require "fs"

alipay = new Alipay
  host: "localhost:65531"
  app_id: "2088511441334570"
  app_private_key: fs.readFileSync "./server-key.pem", "utf-8"
  alipay_public_key: fs.readFileSync "./server-pkkey.pem", "utf-8"
  notify_url: "/hook/notify"
  return_url: "/hook/return"

# 接收支付宝的支付结果
hook = connect()
q = (req, res, next) ->
  req.query = if req.url.includes "?" then qs.parse url.parse(req.url).query else {}
  next()

hook.use q
hook.use body_parser.json()
# 接收异步通知
hook.use "/hook/notify", (req, res) ->
  res.end "failure" if req.method isnt "POST"

  alipay.verify req.body
  .then (verify_ret) ->
    return res.end "failure" unless verify_ret
    # custom logic
    console.log req.body
    # if logic procss successfully
    res.end "success"

# 客户端接收成功后请求页面跳转
hook.use "/hook/return", (req, res) ->
  res.end "failure" if req.method isnt "GET"

  alipay.verify req.query
  .then (verify_ret) ->
    return res.end "failure" unless verify_ret
    # another custom logic
    console.log req.query
    # if logic procss successfully
    res.end "success"

# 提供支付服务
router = connect()
router.use q
router.use body_parser.json()
router.use "/pay", (req, res) ->
  order =
    out_trade_no: "123456" # 商户订单号, 商户网站订单系统中唯一订单号，必填
    subject: "测试订单" # 订单名称 必填
    total_amount: "0.01" # 付款金额,必填
    body: "支付测试使用" # 订单描述

  res.setHeader "Content-Type", "application/json"
  # 返回客户端 charge 对象, 由客户端决定如何发起请求.
  # 最简单方式为构建表单, 提交后重定向到支付页面
  res.end JSON.stringify alipay.get_charge(order, "APP_PAY"), null, 2

  # 其他可用 order 参数
    # show_url: "http://upyun.com" # 商品展示地址 需以http://开头的完整路径，例如：http://www.xxx.com/myorder.html
    # payment_type
    # seller_id
    # seller_email
    # seller_account_name
    # buyer_id
    # buyer_email
    # buyer_account_name
    # price
    # quantity
    # enable_paymethod
    # disable_paymethod
    # anti_phishing_key
    # exter_invoke_ip
    # extra_common_param
    # it_b_pay
    # token
    # qr_pay_mode
    # qrcode_width
    # need_buyer_realnamed
    # hb_fq_param
    # goods_type
    # extend_param
  # send to alipay & wait for user payment
  # pay.create_direct_pay_by_user charge, res

hookserver = createServer hook
paymentserver = createServer router

hookserver.listen 65531
paymentserver.listen 65532