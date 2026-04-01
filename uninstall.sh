#!/bin/bash
# ClawApp FPK 卸载脚本
set -e

APP_NAME="clawapp"
APP_DIR="/opt/$APP_NAME"
DATA_DIR="$APP_DIR/data"
PID_FILE="$DATA_DIR/clawapp.pid"

echo "[ClawApp] 开始卸载..."

# 停止服务
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        kill "$PID" && echo "[✓] 服务已停止 (PID $PID)"
    fi
    rm -f "$PID_FILE"
fi

# 停止 systemd 服务
if command -v systemctl &> /dev/null; then
    systemctl --user disable clawapp.service 2>/dev/null || true
    rm -f "$HOME/.config/systemd/user/clawapp.service" 2>/dev/null || true
fi

# 删除桌面图标
rm -f "$HOME/.local/share/applications/clawapp.desktop" 2>/dev/null || true
rm -f "/app/deskapp/icons/clawapp.desktop" 2>/dev/null || true

# 删除应用目录
if [ -d "$APP_DIR" ]; then
    rm -rf "$APP_DIR" && echo "[✓] 应用目录已删除" || echo "[-] 应用目录删除失败"
fi

echo "[ClawApp] 卸载完成"
