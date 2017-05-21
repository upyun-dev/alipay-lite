crypto = require "crypto"
axios = require "axios"
url = require "url"
moment = require "moment"

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
  
  # 三种支付方式
  payment_methods:
    page_pay: "alipay.trade.page.pay"
    wap_pay: "alipay.trade.wap.pay"
    app_pay: "alipay.trade.app.pay"

  other_methods:
    refund: "alipay.trade.refund"
    pay_query: "alipay.trade.query"
    refund_query: "alipay.trade.fastpay.refund.query"
    trade_close: "alipay.trade.close"

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
    params = Object.assign {
      biz_content
      version: "1.0"
      product_code: "FAST_INSTANT_TRADE_PAY"
      method: @payment_methods[pay_type] ? @payment_methods.page_pay
      timestamp: moment().format "YYYY-MM-DD HH:mm:ss"
    }, @cfg

    delete params.return_url if pay_type is "app_pay"

    params.sign = @sign params
    params

  sign: (params) ->
    delete params.sign
    @create_signature @sort params

  # 异步通知校验签名
  verify: (params) ->
    { sign } = params
    delete params.sign
    delete params.sign_type
    decoded_sign = @btoa sign
    params_str = @sort params
    @signature_verify params_str, decoded_sign

  sort: (params) ->
    "#{k}=#{params[k]}" for k in Object.keys(params).sort()

  create_signature: (plaintext) ->
    signed_stream = crypto.createSign "RSA-SHA256"
    signed_stream.update plaintext
    signed_stream.sign @cfg.app_private_key, "base64"

  signature_verify: (params_str, signature) ->
    verfied_stream = crypto.createVerify "RSA-SHA256"
    verfied_stream.update params_str
    verfied_stream.verify @cfg.alipay_public_key, signature

  btoa: (base64_str) -> Buffer(base64_str, "base64").toString "utf-8"
  atob: (text) -> Buffer(text).toString "base64"

module.exports = Alipay
