Alipay-lite
===

轻量级 SDK, 支持即时到账功能.
使用 md5 散列签名, http 明文通讯.

## API
```coffee
# cfg 对象见 example
alipay = new Alipay cfg

# 获取 charge 对象, 用于发起下一步支付请求
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

## usage
见 example