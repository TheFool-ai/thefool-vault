---
id: procedure.wait
kind: procedure
media-type: text/markdown
---

## 等待与核对规程

partial 表示业务未完成，Host 保存等待原因和关联请求，挂起运行。业务回调、用户回到 H5、重新进入会话或受控定时任务唤醒后，先刷新 Facts 再求值。来源不可用、证据缺失、版本失效或假报完成时，调用 reconcile 查询权威结果并解释，不提交新业务操作。
