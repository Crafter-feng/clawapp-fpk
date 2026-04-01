# ClawApp FPK for 飞牛 fnOS

> 将 [ClawApp](https://github.com/qingchencloud/clawapp)（OpenClaw 手机聊天客户端）封装为飞牛 fnOS 原生 FPK 应用，桌面图标直接打开，无需 Docker。

![Version](https://img.shields.io/badge/version-1.6.3-blue)
![Platform](https://img.shields.io/badge/platform-fnOS-0066CC)
![Arch](https://img.shields.io/badge/arch-amd64%7Carm64-green)

---

## 功能特性

- ✅ **fnOS 桌面原生图标** — 安装后桌面直接显示，点击打开
- ✅ **手机浏览器体验** — PWA 移动端 UI，媲美原生 App
- ✅ **流式对话** — 打字机效果，实时 AI 回复
- ✅ **图片收发** — 拍照、相册上传，AI 图片回复
- ✅ **Ed25519 认证** — 兼容 OpenClaw 2.13+ 设备签名
- ✅ **离线缓存** — 离线消息本地存储，联网后同步
- ✅ **无 Docker** — 纯 Node.js，fnOS 原生运行
- ✅ **双架构** — amd64 / arm64 自动适配

## 架构原理

```
fnOS 桌面浏览器
    ↓ 点击 ClawApp 图标
http://NAS:3210  ← ClawApp Server（Node.js 代理）
    ↓ WebSocket + Ed25519 签名
OpenClaw Gateway（本地 18789 或远程）
    ↓
AI 大模型（云端/本地）
```

ClawApp Server 是 H5 前端与 OpenClaw Gateway 之间的桥梁，解决手机无法直接访问 NAS 本地 Gateway 的问题。

## 安装 FPK（推荐）

进入 [Releases](https://github.com/Crafter-feng/clawapp-fpk/releases) 页面，下载对应架构的 `.fpk`：

| 文件 | 架构 | 适用设备 |
|------|------|---------|
| `clawapp-amd64-X.X.X.fpk` | x86_64 | Intel / AMD CPU NAS |
| `clawapp-arm64-X.X.X.fpk` | ARM64 | 树莓派 / ARM NAS |

**安装步骤：**
1. 上传 `.fpk` 文件到飞牛 NAS
2. 进入「应用中心」→「从文件安装」
3. 安装完成，桌面出现 ClawApp 图标
4. 点击图标，用浏览器打开
5. 首次输入访问密码（显示在安装日志中）

## 自行构建

```bash
# 触发 GitHub Actions 构建
git tag v1.6.3
git push origin v1.6.3

# 或手动触发：
# GitHub → Actions → Build ClawApp FPK → Run workflow
```

构建完成后在 Artifacts 下载 `.fpk` 文件。

## 初始配置

安装后首次访问需要配置：

| 配置项 | 说明 |
|--------|------|
| 服务地址 | `http://<NAS_IP>:3210`（自动填写） |
| 访问密码 | 首次随机生成，见 `data/.env` |
| Gateway 地址 | `ws://127.0.0.1:18789`（本地 OpenClaw） |
| Gateway Token | OpenClaw 的访问令牌（未设置则留空） |

## 目录结构

```
/opt/clawapp/            # 安装目录
├── fnpack.json          # FPK 清单
├── data/
│   ├── dist/             # H5 前端静态文件
│   ├── server/
│   │   └── index.mjs     # 服务端（ncc 编译，单文件）
│   ├── config/
│   │   └── .env          # 服务配置（密码、端口、Gateway）
│   └── logs/             # 运行日志
└── clawapp.pid          # 进程 PID
```

## 常见问题

**Q: 桌面没有图标？**
在 fnOS 桌面右键刷新，或重启桌面服务。

**Q: 提示连接失败？**
检查 OpenClaw Gateway 是否在运行：`curl http://localhost:18789/health`

**Q: 如何查看访问密码？**
```bash
cat /opt/clawapp/data/.env | grep PROXY_TOKEN
```

**Q: 端口被占用？**
修改 `data/.env` 中的 `PROXY_PORT`，然后重启。

**Q: 如何卸载？**
在 fnOS 应用中心卸载，或运行 `uninstall.sh`。

## License

MIT — ClawApp版权归 [qingchencloud](https://github.com/qingchencloud/clawapp) 所有
