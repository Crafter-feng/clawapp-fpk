#!/bin/bash
set -euo pipefail
VERSION="${1:-}"
ARCH="${2:-$(uname -m)}"
[ -z "$VERSION" ] && { echo "VERSION is required" >&2; exit 1; }
echo "==> Building ClawApp $VERSION for $ARCH"

# 克隆源码，构建 H5 + 服务端
cd /tmp
rm -rf clawapp-src
git clone --depth=1 --branch "v$VERSION" https://github.com/qingchencloud/clawapp.git clawapp-src 2>/dev/null || \
git clone --depth=1 https://github.com/qingchencloud/clawapp.git clawapp-src

# 构建 H5 前端
cd clawapp-src/h5
npm install -g pnpm@9 --silent 2>/dev/null
pnpm install --frozen-lockfile 2>/dev/null || pnpm install
pnpm build

# 安装服务端依赖
cd ../server
pnpm install --frozen-lockfile 2>/dev/null || pnpm install

# ncc 打包服务端（单文件）
cd ..
npm install -g @vercel/ncc --silent 2>/dev/null
cp -r h5/dist server/h5_dist
sed -i "s|\.\./h5/dist|./h5_dist|g" server/index.js
ncc build server/index.js -o dist-server --no-source-map -m

# 组装 app_root
mkdir -p app_root
cp -r h5/dist app_root/dist
cp dist-server/index.js app_root/server/index.mjs
# 复制 service-setup 和 bin
cp -r fnos-app/fnos/cmd app_root/
cp -r fnos-app/fnos/bin app_root/ 2>/dev/null || mkdir -p app_root/bin
# manifest 已在 fnos-app 中
cp fnos-app/fnos/manifest app_root/
chmod +x app_root/cmd/service-setup

# 打包 app.tgz
tar -czvf app.tgz -C app_root .
echo "==> 构建完成: app.tgz ($(du -sh app.tgz | cut -f1))"
