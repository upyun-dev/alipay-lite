{ createHash } = require "crypto"
axios = require "axios"

# 轻量级 alipay sdk, 目前支持即时到账功能
# 使用 md5 签名, http 明文数据传输
class Alipay 
  BASIC_CFG:
    partner: ""
    key: ""
    seller_email: ""
    notify_url: ""
    return_url: ""
    _input_charset: "utf-8"
    sign_type: "MD5"
    verify_url: "http://notify.alipay.com/trade/notify_query.do"
    gateway: "https://mapi.alipay.com/gateway.do"

  constructor: (cfg = {}) ->
    @cfg = Object.assign @BASIC_CFG, cfg

  # 用于请求支付界面
  get_charge: (order) ->
    method: "get"
    gateway: @cfg.gateway
    params: @create order

  # Promisify
  # 用于检验 return 和 notify 接口得到的信息的正确性, 返回 true / false
  verify: (params) ->
    @verify_notify_id params.notify_id
    .then (ret) -> ret is true and @verify_sign params

  create: (order) ->
    { partner, notify_url, return_url, seller_email, _input_charset, sign_type } = @cfg

    params = {
      service: "create_direct_pay_by_user"
      payment_type: "1"

      partner
      notify_url
      return_url
      seller_email
      _input_charset
    }

    params = Object.assign params, order
    params.sign = @sign params
    params.sign_type = sign_type
    params

  sign: (params) -> @md5 @concat @sort @filter params

  verify_notify_id: (notify_id) ->
    axios.get "#{@cfg.verify_url}?partner=#{@cfg.partner}&notify_id=#{notify_id}"
    .then ({ data, status }) -> data

  verify_sign: (params) ->
    { sign } = params
    sign is @sign params

  filter: (params) ->
    delete params.sign
    delete params.sign_type
    params

  sort: (params) ->
    "#{k}=#{params[k]}" for k in Object.keys(params).sort()

  concat: (seq) ->
    "#{seq.join '&'}#{@cfg.key}"

  md5: (plaintext) ->
    createHash "md5"
    .update plaintext, "utf-8"
    .digest "hex"

module.exports = Alipay
