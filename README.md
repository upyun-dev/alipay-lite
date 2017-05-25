Alipay-lite
===

轻量级 SDK, 支持支付宝新版支付/退款/查询功能.
支持 RSA(SHA1withRSA) 以及 RSA2(SHA256withRSA) 签名算法.

+ 新旧接口对比: https://doc.open.alipay.com/docs/doc.htm?docType=1&articleId=106759
+ 签名流程: https://doc.open.alipay.com/docs/doc.htm?docType=1&articleId=106118
+ 签名校验流程: https://doc.open.alipay.com/docs/doc.htm?treeId=270&articleId=105902&docType=1#s7
+ 同步跳转参数: https://doc.open.alipay.com/doc2/detail.htm?treeId=270&articleId=105901&docType=1#s3
+ 异步通知参数: https://doc.open.alipay.com/docs/doc.htm?treeId=270&articleId=105902&docType=1#s0

## 支付流程

1. 客户端请求业务服务器
2. 业务服务器根据客户端携带的订单信息, 返回一个 charge 对象.
3. 客户端拿到 charge 对象后 POST 内容到一个 url.
4. 支付完成后客户端会被重定向到到配置中定义的 return_url, 通知支付结果给用户.
   同时地, 支付宝也会发送一个 POST 请求到配置中定义的 notify_url, 通知真实的支付结果给服务器.
   (最终支付状态以支付宝的 POST 请求为准.)
5. 如果未接收到异步通知, 业务服务器应该主动查询付款结果.

4注:

+ 异步通知方式需要先进行校验
+ 通过 POST 得到支付状态后, 校验成功需要响应一个字符串 "success", 并进行后续的自身业务处理(比如保存订单等).
+ 支付宝服务器会不断重发通知，直到超过24小时22分钟。一般情况下，25小时以内完成8次通知（通知的间隔频率一般是：4m,10m,10m,1h,2h,6h,15h）；
+ 异步通知的作用主要防止订单丢失，即页面跳转同步通知没有处理订单更新，它则去处理；
+ 当商户收到服务器异步通知并打印出success时，服务器异步通知参数notify_id才会失效。也就是说在支付宝发送同一条异步通知时（包含商户并未成功打印出success导致支付宝重发数次通知），服务器异步通知参数notify_id是不变的。

+ 页面跳转同步通知通过 GET 重定向, 可以响应客户端自定义信息(比如支付成功/正在处理订单等)

## API
```coffee
# cfg 对象见 example / src
Alipay = require "alipay-lite"
alipay = new Alipay cfg

# 获取 charge 对象, 用于发起下一步支付请求
# charge 包含 `url`, `method`, `charset`, `params`. 分别为请求地址, http verb, 字符集, body content.
# 客户端拿到 charge 对象后 POST params 内容到 url.
# pay_type 根据客户端环境可选择 "PAGE_PAY", "WAP_PAY", "APP_PAY", 分别为电脑网页, 手机网页, 手机app

alipay.get_charge(order, pay_type) # => Object { method, charset, url, params }

# 验证请求方身份及数据一致性与正确性 (是否来自 alibaba, 订单是否正确)
# params 为 body, 参见 example
alipay.verify(params) # => Promise
.then (verified) ->
  if verified
    # verfiy 需要针对自己的业务系统做些额外验证, 比如金额是否匹配等, 见支付宝文档描述.
    # 响应 "success" 字符串给 alipay
    # 然后处理自己的业务逻辑
  else
    # ...

# 退款
alipay.refund(order) # => axios Promise

# 付款结果查询
alipay.query_payment(order) # => axios Promise

# 退款结果查询
alipay.query_refund(order) # => axios Promise
```

## cfg

必须选项:

```yaml
app_id: ""
charset: "utf-8"
sign_type: "RSA2"
app_private_key: "" # 商户私钥
alipay_public_key: "" # 支付宝提供的公钥
notify_url: "/hook/notify"
host: "localhost:2333" # notify 服务器地址, 如果没有在 notify_url 中配置 host, 那么这里需要配置.
```

## usage

接收支付请求:
```coffee
router = express()
router.use "/pay", (req, res) ->
  order =
    out_trade_no: "123456" # 商户订单号, 商户网站订单系统中唯一订单号，必填
    subject: "测试订单" # 订单名称 必填
    total_amount: "0.01" # 付款金额,必填
    body: "支付测试使用" # 订单描述

  res.setHeader "Content-Type", "application/json"
  # 返回客户端 charge 对象, 由客户端决定如何发起请求.
  # 最简单方式为构建表单, 提交后重定向到支付页面
  res.end JSON.stringify alipay.get_charge(order, "PAGE_PAY"), null, 2
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