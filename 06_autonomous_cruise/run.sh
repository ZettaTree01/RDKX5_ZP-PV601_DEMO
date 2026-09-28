#!/usr/bin/env bash
# 例程6 自主巡航拍摄入口。
# 加载演示环境与飞控安全封装后，启动 autonomous_cruise.launch.py。
# 其余 key:=value 透传给 launch（如 arm:=true、bench:=false）。
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source /app/zettatree_demo/_common/env.sh
# shellcheck disable=SC1091
source /app/zettatree_demo/_common/run_flight.sh
# Ctrl+C 必须打到 shell，退出陷阱才会经串口上锁。前台 ros2 launch 会吞掉信号。
_flight_run ros2 launch "$SCRIPT_DIR/autonomous_cruise.launch.py" "$@"
