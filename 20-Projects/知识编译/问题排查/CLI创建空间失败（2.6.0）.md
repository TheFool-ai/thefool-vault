---
created: "2026-11-04"
updated: "2026-11-05"
type: project
---

## 当前结论

截至 11-04：CLI 路径修复后，继续定位并修复 Open Application 功能目录、正文检查和转发路径未同步导致的 403，提交 29475ca 已推送。缺陷单已收到 CLOSED 通知；真实创建空间回归结果待确认。

## 问题来源

- **发现方式**：内部集成测试发现。Meego 描述为绑定 CLI 后创建编译空间失败，环境为 V2.6.0 集成测试。
- **反馈人 / 建单人**：李振琪。
- **入口与时间**：[Meego 缺陷 7388711661](https://meego.feishu.cn/xqd1pw/issue/detail/7388711661)，2026-11-03 14:57:43 创建；自动建立同步群，14:59 李振琪在群内[请我检查路由](https://applink.feishu.cn/client/chat/open?openChatId=oc_79cc638cd01f66e661f608ebae4af66e&position=3)。
- **单据状态**：11-04 早间读取为 RESOLVED；17:20 同步群通知变为 CLOSED。未见具体回归操作与结果。

## 现象与定位

CLI 创建空间失败。合并 2.5.0 后 VeraG URL 变化、Ingress rewrite 移除，CLI 路径未同步。

11-04 继续定位：CLI 已使用 /marketing_agent/knowledge-compiler，但 Open Application 的功能目录、请求检查和流式转发仍按旧路径识别，导致 no_matching_capability 403。此次沿用既有 UAT、用户、应用和项目权限体系，统一新前缀。测试中修改前拒绝、修改后可转发，上游使用替身；全套 2,285 项通过。

开放平台接口列表的隐藏问题另见[独立记录](开放平台知识编译接口展示.md)。

## 时间线

时间均为北京时间，记录反馈或结果被确认的时间。

| 时间 | 进展与依据 |
| --- | --- |
| 2026-11-03 14:57:43 | 李振琪创建 Meego 缺陷，随后同步群建立。[缺陷单](https://meego.feishu.cn/xqd1pw/issue/detail/7388711661) |
| 2026-11-03 14:59 | 李振琪反馈创建空间失败，请我检查接口路由。[消息](https://applink.feishu.cn/client/chat/open?openChatId=oc_79cc638cd01f66e661f608ebae4af66e&position=3) |
| 2026-11-03 20:41 | 我确认 URL 变更未同步的问题已处理。[消息](https://applink.feishu.cn/client/chat/open?openChatId=oc_79cc638cd01f66e661f608ebae4af66e&position=9) |
| 2026-11-03 20:42 | 我明确已变更 CLI 代码，询问部署方式。[消息](https://applink.feishu.cn/client/chat/open?openChatId=oc_79cc638cd01f66e661f608ebae4af66e&position=10) |
| 2026-11-03 20:43 | 缺陷状态变为 `RESOLVED`；未见部署与回归结果。[状态通知](https://applink.feishu.cn/client/chat/open?openChatId=oc_79cc638cd01f66e661f608ebae4af66e&position=11) |
| 2026-11-03 20:45 | 李振琪表示重新打包；打包完成与部署结果尚无确认。[消息](https://applink.feishu.cn/client/chat/open?openChatId=oc_79cc638cd01f66e661f608ebae4af66e&position=14) |
| 2026-11-04 14:36–14:37 | 李振琪反馈最新集成包仍不可用。[反馈](https://applink.feishu.cn/client/chat/open?openChatId=oc_79cc638cd01f66e661f608ebae4af66e&position=16) |
| 2026-11-04 15:25–15:28 | Open Application 新路径匹配修复 29475ca 已推送，2,285 项测试通过；提交 [MR 264](https://code.byted.org/dp/open_application/merge_requests/264)。 |
| 2026-11-04 15:51 | 我告知已更新开放平台路径，请重新验证。[消息](https://applink.feishu.cn/client/chat/open?openChatId=oc_79cc638cd01f66e661f608ebae4af66e&position=23) |
| 2026-11-04 17:20 | 缺陷同步群通知 RESOLVED → CLOSED；未附业务回归结果。[通知](https://applink.feishu.cn/client/chat/open?openChatId=oc_79cc638cd01f66e661f608ebae4af66e&position=25) |

## 待办

- 确认交付包包含 CLI 与 Open Application 配套修复，验证真实授权、创建空间及旧入口兼容。
- 梁子恺 11-04 23:58 请同步对齐 MCP 新路径；适配及验证结果待补充。[消息](https://applink.feishu.cn/client/chat/open?openChatId=oc_091de2d98c859c041722e91cb6a10b25&position=514)
- 关联检查：于子奇已补充 CLI 新增命令与功能权限映射，请我核对遗漏；[MR 262](https://code.byted.org/dp/open_application/merge_requests/262) 的检查结果待补充。来源：11-03 [与于子奇的讨论](https://applink.feishu.cn/client/thread/open?open_chat_id=oc_0ac080f4b08a8db533c2f51902bf09d4&open_thread_id=omt_198c25a04f4f0763&openchatid=oc_0ac080f4b08a8db533c2f51902bf09d4&openthreadid=omt_198c25a04f4f0763&thread_position=-1)。

## 代码依据

Codex《定位这个问题》（local，ID 01a1a558-e12b-7870-b1af-4cb1fa620d7b），2026-11-04；结合提交 29475ca、测试和推送成功结果核对。
