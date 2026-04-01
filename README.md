# ClawApp FPK for 飞牛 fnOS

> 将 [ClawApp](https://github.com/qingchencloud/clawapp)（OpenClaw 手机聊天客户端）封装为飞牛 fnOS **原生应用**，桌面图标直接点击打开，无需 Docker 或代理。

## 功能特性

- ✅ **fnOS 原生桌面图标** — 安装后在桌面直接点击打开
- ✅ **iframe 嵌入** — 在 fnOS 桌面窗口内直接显示，不跳浏览器
- ✅ **流式对话** — 打字机效果，实时 AI 回复
- ✅ **PWA 移动端 UI** — 媲美原生 App 体验
- ✅ **无 Docker** — 纯 Node.js 原生运行
- ✅ **Ed25519 认证** — 兼容 OpenClaw 2.13+

## 安装

1. 进入 [Releases](https://github.com/Crafter-feng/clawapp-fpk/releases) 下载 `.fpk` 文件
2. 飞牛 NAS → 应用中心 → 从文件安装
3. 桌面找到 ClawApp 图标，点击打开

## 架构

```
ClawApp FPK（app.tgz）
├── manifest               ← fnOS 应用清单
├── cmd/service-setup      ← fnOS 生命周期脚本（安装/启动/停止/卸载）
├── bin/clawapp-server    ← 服务端启动脚本
├── ui/config             ← 桌面图标配置（iframe 嵌入）
├── config/privilege       ← 权限配置
├── config/resource        ← 资源配置
└── dist/                 ← ClawApp H5 前端（编译后）
    └── server/
        └── index.mjs     ← ClawApp Server（ncc 打包）
```

点击桌面图标 → fnOS 通过 `ui/config` → iframe 嵌入 `http://localhost:3210`

## 自行构建

```bash
git tag v1.6.3
git push origin v1.6.3
```

GitHub Actions 自动构建，Artifcats 下载 `.fpk`。

## License

MIT — ClawApp版权归 [qingchencloud](https://github.com/qingchencloud/clawapp) 所有
