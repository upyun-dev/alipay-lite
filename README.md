Alipay-lite
===

轻量级 SDK, 支持即时到账功能.
使用 md5 散列签名, http 明文通讯.

## 支付流程

1. 客户端请求业务服务器
2. 业务服务器根据客户端携带的订单信息, 返回一个 charge 对象.
3. 客户端拿到 charge 对象后拼接一个 url 或构建一个表单并提交给支付宝.
4. 支付完成后客户端会被重定向到到配置中定义的 return_url, 通知支付结果给用户.
   同时地, 支付宝也会发送一个 POST 请求到配置中定义的 notify_url, 通知真实的支付结果给服务器.
   (最终支付状态以支付宝的 POST 请求为准.)

4注:

+ 两种通知方式都需要先进行校验
+ 通过 POST 得到支付状态后, 校验成功需要响应一个字符串 "success", 并进行后续的自身业务处理(比如保存订单等).
+ 对于通过 GET 重定向, 校验成功后可以响应客户端自定义信息(比如支付成功等)

## API
```coffee
# cfg 对象见 example
alipay = new Alipay cfg

# 获取 charge 对象, 用于发起下一步支付请求
# charge 包含 `gateway`, `method`, `params`. 分别为请求地址, http verb, query string.
# 客户端拿到 charge 对象后拼接一个请求 url 或构建一个表单, 通过 method 提交 params 到 gateway.
# order 为订单相关信息, 参见 https://doc.open.alipay.com/docs/doc.htm?spm=a219a.7629140.0.0.56xJBr&treeId=62&articleId=104743&docType=1
alipay.get_charge(order)

# 验证请求方身份及数据一致性与正确性 (是否来自 alibaba, 订单是否正确)
# params 为 body 或 query object, 参见 example
alipay.verify(params) # => Promise
.then (verified) ->
  if verified
    # 响应 "success" 字符串给 alipay
    # 然后处理自己的业务逻辑
  else
    # ...
```

## cfg

```yaml
partner: "xxxxxxxxxxxx" # 合作身份者id，以2088开头的16位纯数字
key: "3b250072d1e74d8e36c2bab8d3ff2c03" # 安全检验码，以数字和字母组成的32位字符
seller_email: "abbshrsoufii@gmail.com" # 卖家支付宝帐户 必填
return_url: "http://10.0.4.65:65531/hook/return"
notify_url: "http://10.0.4.65:65531/hook/notify"
```

## usage

接收支付请求:
```coffee
router = express()
router.use "/pay", (req, res) ->
  order =
    out_trade_no: "123456" # 商户订单号, 商户网站订单系统中唯一订单号，必填
    subject: "测试订单" # 订单名称 必填
    total_fee: "0.01" # 付款金额,必填
    body: "支付测试使用" # 订单描述

  res.setHeader "Content-Type", "application/json"
  # 返回客户端 charge 对象, 由客户端决定如何发起请求.
  # 最简单方式为构建表单, 提交后重定向到支付页面
  res.end JSON.stringify alipay.get_charge(order), null, 2
```

接收异步通知:
```coffee
# 接收异步通知
hook = express()
hook.post "/hook/notify", (req, res) ->
  alipay.verify req.body
  .then (verify_ret) ->
    return res.end "failure" unless verify_ret
    # if logic procss successfully
    res.end "success"
    # custom logic
```

同步页面跳转:
```coffee
# 客户端接收成功后请求页面跳转
hook.get "/hook/return", (req, res) ->
  alipay.verify req.query
  .then (verify_ret) ->
    return res.end "failure" unless verify_ret
    # if logic procss successfully
    # another custom logic
```