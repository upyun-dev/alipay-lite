crypto = require "crypto"
moment = require "moment"
url = require "url"

# 轻量级 alipay sdk, 目前支持即时到账功能
# 使用 md5 签名
class Alipay 
  basic_cfg:
    app_id: ""
    format: "json"
    charset: "utf-8"
    sign_type: "RSA2"
    app_private_key: ""
    alipay_public_key: ""
    url: "https://openapi.alipay.com/gateway.do"
    notify_url: "/"
    return_url: "/"

  methods:
    # 三种支付方式
    PAYMENT:
      PAGE_PAY: "alipay.trade.page.pay"
      WAP_PAY: "alipay.trade.wap.pay"
      APP_PAY: "alipay.trade.app.pay"

    REFUND: "alipay.trade.refund"
    PAY_QUERY: "alipay.trade.query"
    REFUND_QUERY: "alipay.trade.fastpay.refund.query"
    TRADE_CLOSE: "alipay.trade.close"

  constructor: (cfg = {}) ->
    @cfg = Object.assign {}, @basic_cfg, cfg

    for attr_name in ["notify_url", "return_url"]
      { protocol, hostname } = url.parse @cfg[attr_name]
      unless protocol? and hostname?
        @cfg[attr_name] = "http://#{@cfg.host}#{@cfg.notify_url}"

  # 创建订单
  get_charge: (biz_content, pay_type = "page_pay") ->
    method: "POST"
    url: @cfg.url
    charset: @cfg.charsetalipay.trade.app.pay
    params: @create JSON.stringify(biz_content), pay_type

  create: (biz_content, pay_type) ->
    { PAYMENT } = @methods
    params = Object.assign {
      biz_content
      version: "1.0"
      product_code: "FAST_INSTANT_TRADE_PAY"
      method: PAYMENT[pay_type] ? PAYMENT.page_pay
      timestamp: moment().format "YYYY-MM-DD HH:mm:ss"
    }, @cfg

    delete params.return_url if pay_type is "APP_PAY"

    params.sign = @sign params
    params

  sign: (params) ->
    delete params.sign
    @create_signature @concat @sort params

  # 异步通知校验签名
  verify: (params) ->
    { sign } = params
    delete params.sign
    delete params.sign_type
    decoded_sign = @btoa sign
    @signature_verify decoded_sign, @concat @sort params

  sort: (params) ->
    "#{k}=#{params[k]}" for k in Object.keys(params).sort()

  concat: (seq) ->
    seq.join "&"

  create_signature: (plaintext) ->
    signed_stream = crypto.createSign "RSA-SHA256"
    signed_stream.update plaintext
    signed_stream.sign @cfg.app_private_key, "base64"

  signature_verify: (signature, plaintext) ->
    verfied_stream = crypto.createVerify "RSA-SHA256"
    verfied_stream.update plaintext
    verfied_stream.verify @cfg.alipay_public_key, signature

  btoa: (base64_str) -> Buffer(base64_str, "base64").toString "utf-8"
  atob: (text) -> Buffer(text).toString "base64"

module.exports = Alipay
