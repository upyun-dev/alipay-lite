crypto = require "crypto"
moment = require "moment"
axios = require "axios"
url = require "url"

# 轻量级 alipay sdk, 支持 app 支付, 手机/电脑网站支付, 支付查询, 退款, 退款查询
# 签名支持 alipay 的 RSA 和 RSA2
class Alipay
  digest_algorithms:
    "RSA": "RSA-SHA1"
    "RSA2": "RSA-SHA256"

  basic_cfg:
    url: "https://openapi.alipay.com/gateway.do"
    host: ""
    app_id: ""
    # format: "JSON"
    charset: "UTF-8"
    sign_type: "RSA2"
    app_private_key: ""
    alipay_public_key: ""
    notify_url: "/"
    # return_url: "/"

  methods:
    # 三种支付方式
    payment:
      PAGE_PAY: "alipay.trade.page.pay"
      WAP_PAY: "alipay.trade.wap.pay"
      APP_PAY: "alipay.trade.app.pay"

    REFUND: "alipay.trade.refund"
    PAY_QUERY: "alipay.trade.query"
    REFUND_QUERY: "alipay.trade.fastpay.refund.query"

  constructor: (cfg = {}) ->
    @cfg = Object.assign {}, @basic_cfg, cfg

    for attr_name in ["notify_url", "return_url"] when attr_name of @cfg
      { protocol, hostname } = url.parse @cfg[attr_name]
      @cfg[attr_name] = "#{@cfg.host}#{@cfg[attr_name]}" unless hostname? and protocol?

  # 创建订单
  get_charge: (biz_content, pay_type) ->
    method: "POST"
    url: @cfg.url
    charset: @cfg.charset
    params: @create_order biz_content, pay_type

  # 异步通知校验签名
  verify: (params) ->
    { sign } = params
    params = @wash params, ["sign", "sign_type"]
    decoded_sign = @btoa sign
    @signature_verify decoded_sign, @concat @sort params

  # 退款
  refund: (biz_content) -> @common_request biz_content, "REFUND"

  # 支付结果查询
  query_payment: (biz_content) -> @common_request biz_content, "PAY_QUERY"

  # 退款查询
  query_refund: (biz_content) -> @common_request biz_content, "REFUND_QUERY"

  common_request: (biz_content, method_constant) ->
    params = Object.assign {
      biz_content: JSON.stringify biz_content
      version: "1.0"
      method: @methods[method_constant]
      timestamp: moment().format "YYYY-MM-DD HH:mm:ss"
    }, @cfg

    params = @wash params, ["url", "host", "app_private_key", "alipay_public_key", "notify_url", "return_url"]
    params.sign = @sign params
    axios.get @cfg.url, { params }

  wash: (object, attrs_to_remove = []) ->
    cloned = {}
    cloned[k] = v for own k, v of object when k not in attrs_to_remove
    cloned

  create_order: (biz_content, pay_type) ->
    { payment } = @methods
    Object.assign biz_content, product_code: "FAST_INSTANT_TRADE_PAY"
    params = Object.assign {
      biz_content: JSON.stringify biz_content
      version: "1.0"
      method: payment[pay_type] ? payment.PAGE_PAY
      timestamp: moment().format "YYYY-MM-DD HH:mm:ss"
    }, @cfg

    params = @wash params, ["url", "host", "app_private_key", "alipay_public_key"]
    params = @wash params, ["return_url"] if pay_type is "APP_PAY"

    params.sign = @sign params
    params

  sign: (params) ->
    params = @wash params, ["sign"]
    @create_signature @concat @sort params

  sort: (params) ->
    "#{k}=#{params[k]}" for k in Object.keys(params).sort()

  concat: (seq) ->
    seq.join "&"

  create_signature: (plaintext) ->
    signed_stream = crypto.createSign @digest_algorithms[@cfg.sign_type]
    signed_stream.update plaintext
    signed_stream.sign @cfg.app_private_key, "base64"

  signature_verify: (signature, plaintext) ->
    verfied_stream = crypto.createVerify @digest_algorithms[@cfg.sign_type]
    verfied_stream.update plaintext
    verfied_stream.verify @cfg.alipay_public_key, signature

  btoa: (base64_str) -> Buffer(base64_str, "base64").toString "utf-8"
  atob: (text) -> Buffer(text).toString "base64"

module.exports = Alipay
