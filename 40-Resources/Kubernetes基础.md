---
created: "2026-11-09"
updated: "2026-11-09"
type: note
---

## 核心概念

Kubernetes（K8s）用来管理容器化应用的部署、扩缩容和运行。先分清三个问题：程序跑在哪、怎么维持运行、请求怎么进来。

下表基于 2026-11-09 提供的学习截图整理，结合官方文档补充了概念边界。

| 概念 | 作用 |
| --- | --- |
| 集群 Cluster | 由控制平面和工作节点组成的运行环境；学习环境也可以只有一台机器。 |
| 节点 Node | 集群中的一台物理机或虚拟机，提供 CPU、内存等资源，承载 Pod。 |
| 镜像 Image | 打包好的程序和依赖，用来创建容器。 |
| 容器 Container | 从镜像启动的运行实例，实际执行程序。 |
| Pod | K8s 最小的部署单元，包含一个或多个容器；同一个 Pod 的容器一起调度到同一节点，共享网络，可共享存储卷。 |
| Deployment | 声明 Pod 模板和期望副本数，通过 ReplicaSet 维持副本数量，并管理滚动更新。 |
| Service | 为一组后端提供稳定的访问入口；常见用法是通过标签选择 Pod，使调用方不必跟随 Pod 地址变化。 |
| Ingress | 定义外部 HTTP/HTTPS 请求按域名、URL 路径路由到哪个 Service；需要 Ingress Controller 执行规则。 |

参考：[集群组件](https://kubernetes.io/docs/concepts/overview/components/)、[Pod](https://kubernetes.io/docs/concepts/workloads/pods/)、[Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)、[Service](https://kubernetes.io/docs/concepts/services-networking/service/)、[Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)。

## 把关系串起来

以下是 AI 根据官方文档补充的记忆方式。

- **运行位置**：Cluster 包含 Node，Pod 在 Node 上运行，Container 在 Pod 内运行，Container 从 Image 创建。
- **副本管理**：Deployment → ReplicaSet → Pod。更新镜像时，Deployment 按策略替换 Pod。
- **典型 HTTP 访问路径**：外部请求 → Ingress Controller（按 Ingress 规则）→ Service 对应的后端 Pod → 容器中的程序。实际转发实现由控制器和网络方案决定。

例如部署一个 Web 服务：镜像装好程序；Deployment 声明运行 3 个 Pod；Service 提供稳定入口；Ingress 规定 `app.example.com/api` 交给哪个 Service。

容易混淆：Pod 被删除后，控制器可以创建新的 Pod 补足副本；容器进程崩溃时，同一个 Pod 内的容器也可能由节点上的 kubelet 按重启策略重启。两者不是同一个动作。参见 [Pod 生命周期](https://kubernetes.io/docs/concepts/workloads/pods/#pod-lifecycle)。

## 相关笔记

- [个人技术成长](../30-Areas/个人技术成长.md)：学习方向、实践与能力积累的长期入口。

## 来源

- 学习截图：2026-11-09 提供，包含 Cluster、Node、Image、Container、Pod、Deployment、Service、Ingress 八个概念。原作者、原始发布日期未提供。
- Kubernetes 官方文档：上文所列概念页及 [概览](https://kubernetes.io/docs/concepts/overview/)。查阅日期：2026-11-09。本文记录通用概念，未绑定具体集群版本。
