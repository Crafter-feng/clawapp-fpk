#!/bin/bash
# ClawApp FPK 安装脚本（纯原生，无 Docker）
# 功能：解压 → 启动 Node.js 代理服务 → 注册 fnOS 桌面图标

set -e

APP_NAME="clawapp"
APP_DIR="/opt/$APP_NAME"           # fnOS 应用安装目录
DATA_DIR="$APP_DIR/data"           # 用户数据目录
DIST_DIR="$DATA_DIR/dist"           # H5 前端静态文件
SERVER_BIN="$APP_DIR/server/index.mjs"  # 编译后的服务端（ncc 打包）
CONF_FILE="$DATA_DIR/.env"          # 服务端配置
LOG_DIR="$DATA_DIR/logs"
PID_FILE="$DATA_DIR/clawapp.pid"
DEFAULT_PORT=3210

# ── 颜色输出 ──────────────────────────────────────────────────────
RED='\033[0;31m'; GRN='\033[0;32m'; YEL='\033[1;33m'; NC='\033[0m'
log() { echo -e "${GRN}[ClawApp]${NC} $1"; }
warn() { echo -e "${YEL}[ClawApp]${NC} $1"; }
err()  { echo -e "${RED}[ClawApp]${NC} $1" >&2; }

# ── 前置检查 ──────────────────────────────────────────────────────
if ! command -v node &> /dev/null; then
    warn "未检测到 Node.js，开始安装..."
    if command -v apt-get &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
        apt-get install -y nodejs > /dev/null 2>&1
    elif command -v apk &> /dev/null; then
        apk add --no-cache nodejs npm
    else
        err "不支持的包管理器，请手动安装 Node.js >= 18"
        exit 1
    fi
fi
NODE_VER=$(node -v | tr -d 'v')
log "Node.js 版本: $NODE_VER"

# ── 解压 FPK ──────────────────────────────────────────────────────
log "安装 ClawApp 到 $APP_DIR ..."

# FPK 安装时，解压自身到 /opt/clawapp
# （FPK 本身 = tar.gz，install.sh 在解压后的根目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 如果当前目录就是解压出来的结构（正常安装流程）
if [ -d "$SCRIPT_DIR/data" ]; then:
    mkdir -p "$APP_DIR"
    # 复制所有文件到安装目录
    cp -r "$SCRIPT_DIR/data" "$APP_DIR/"
    cp "$SCRIPT_DIR/fnpack.json" "$APP_DIR/" 2>/dev/null || true
    chmod -R 755 "$APP_DIR"
    log "文件已复制到 $APP_DIR"
else
    log "安装源目录: $SCRIPT_DIR"
fi

mkdir -p "$DATA_DIR" "$LOG_DIR" "$DIST_DIR" "$APP_DIR/server"

# ── 生成配置文件 ───────────────────────────────────────────────────
if [ ! -f "$CONF_FILE" ]; then
    RANDOM_TOKEN=$(python3 -c "import secrets; print(secrets.token_urlsafe(16))")
    cat > "$CONF_FILE" << EOF
# ClawApp 配置文件
PROXY_PORT=$DEFAULT_PORT
PROXY_TOKEN=$RANDOM_TOKEN
SETUP_PENDING=true
OPENCLAW_GATEWAY_URL=ws://127.0.0.1:18789
OPENCLAW_GATEWAY_TOKEN=
EOF
    log "配置文件已生成: $CONF_FILE"
    log "　　访问密码（首次）: $RANDOM_TOKEN"
fi

# ── 复制前端静态文件（如果缺失）──────────────────────────────────
if [ ! -f "$DIST_DIR/index.html" ] && [ -d "$APP_DIR/dist" ]; then
    cp -r "$APP_DIR/dist/"* "$DIST_DIR/" 2>/dev/null || true
fi

# ── 启动服务端 ─────────────────────────────────────────────────────
start_server() {
    if [ -f "$PID_FILE" ]; then
        OLD_PID=$(cat "$PID_FILE")
        if kill -0 "$OLD_PID" 2>/dev/null; then
            log "服务已运行 (PID $OLD_PID)，跳过启动"
            return
        else
            rm -f "$PID_FILE"
        fi
    fi

    if [ ! -f "$SERVER_BIN" ]; then
        err "服务端文件不存在: $SERVER_BIN"
        err "请确认 FPK 构建完整（server/index.mjs 缺失）"
        exit 1
    fi

    log "启动 ClawApp 服务端 ..."

    # 启动 Node.js 服务端
    cd "$APP_DIR/server"
    nohup node "$SERVER_BIN" > "$LOG_DIR/server.log" 2>&1 &
    SERVER_PID=$!
    echo "$SERVER_PID" > "$PID_FILE"

    sleep 2
    if kill -0 "$SERVER_PID" 2>/dev/null; then
        PORT=$(grep '^PROXY_PORT=' "$CONF_FILE" | cut -d= -f2)
        NAS_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "localhost")
        log "✅ ClawApp 服务已启动 (PID $SERVER_PID)"
        log ""
        log "═══════════════════════════════════════"
        log "　　ClawApp 安装完成！"
        log ""
        log "　　📱 访问地址："
        log "　　http://$NAS_IP:$PORT"
        log ""
        log "　　🔑 访问密码："
        grep '^PROXY_TOKEN=' "$CONF_FILE" | cut -d= -f2
        log ""
        log "　　💡 首次使用："
        log "　　在页面输入上述地址和密码即可连接"
        log "═══════════════════════════════════════"
    else
        err "服务启动失败，查看日志："
        tail -20 "$LOG_DIR/server.log" 2>/dev/null || echo "无日志"
        exit 1
    fi
}

# ── fnOS 桌面图标注册 ─────────────────────────────────────────────
register_desktop() {
    log "注册 fnOS 桌面图标 ..."

    # fnOS 桌面图标通过 ~/.local/share/applications 或 fnOS 数据库注册
    # 检测 fnOS 桌面环境
    FNOS_DESKTOP_DIR="$HOME/.local/share/applications"
    mkdir -p "$FNOS_DESKTOP_DIR"

    PORT=$(grep '^PROXY_PORT=' "$CONF_FILE" | cut -d= -f2 2>/dev/null || echo "$DEFAULT_PORT")
    NAS_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "localhost")
    APP_URL="http://$NAS_IP:$PORT"

    # 创建 .desktop 文件（Linux 桌面标准）
    cat > "$FNOS_DESKTOP_DIR/clawapp.desktop" << EOF
[Desktop Entry]
Version=1.6.3
Name=ClawApp
Comment=OpenClaw 手机聊天客户端
Exec=xdg-open $APP_URL
Icon=web-clawapp
Type=Application
Terminal=false
Categories=Network;Chat;
StartupNotify=true
MimeType=text/html;
EOF

    # 尝试复制到 fnOS 应用中心图标目录（如存在）
    if [ -d "/app/deskapp/icons" ]; then
        cp "$FNOS_DESKTOP_DIR/clawapp.desktop" "/app/deskapp/icons/" 2>/dev/null || true
    fi

    # 写一个标记文件，供 fnOS 桌面识别
    cat > "$APP_DIR/.appinfo" << EOF
{
  "name": "ClawApp",
  "version": "1.6.3",
  "type": "web",
  "url": "$APP_URL",
  "icon": "web-clawapp",
  "port": $PORT
}
EOF

    log "✅ 桌面图标已注册"
    log "　　请在 fnOS 桌面刷新查看 ClawApp 图标"
}

# ── 设置开机自启 ──────────────────────────────────────────────────
enable_autostart() {
    # 创建 systemd 用户服务
    SERVICE_FILE="$HOME/.config/systemd/user/clawapp.service"
    mkdir -p "$(dirname "$SERVICE_FILE")"

    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=ClawApp Server
After=network.target

[Service]
Type=simple
WorkingDirectory=$APP_DIR/server
ExecStart=/usr/bin/node $SERVER_BIN
Restart=always
RestartSec=5
Environment=NODE_ENV=production

[Install]
WantedBy=default.target
EOF

    # 启用服务
    if command -v systemctl &> /dev/null; then
        systemctl --user daemon-reload 2>/dev/null || true
        systemctl --user enable clawapp.service 2>/dev/null || true
        log "✅ 开机自启已配置（systemd）"
    else
        # 备用：写入 rc.local 或 profile
        log "　　（非 systemd 系统，请手动配置自启）"
    fi
}

# ── 主流程 ────────────────────────────────────────────────────────
log "开始安装 ClawApp FPK ..."
log "安装目录: $APP_DIR"
echo ""

start_server
register_desktop
enable_autostart

echo ""
log "安装完成！"
