# 02 台架位姿模拟器（例程2）

## 例程说明

文档 2.8。拆桨台架、室内无 GPS 时，飞控 EKF 拿不到位置估计，`OFFBOARD` 会被拒绝解锁。
一启动就回灌视觉；与飞控本地点或设定点偏差超过 1 m 时直接对齐，
避免室内气压计在几十米时从 0 慢慢爬、高度一直涨、又解不了锁。

## 本节目标

- 没有位置估计时 OFFBOARD 为什么不让解锁；室内无 GPS 就会卡在这一步。
- 掌握外部视觉位姿（`vision_pose`）回灌方法及飞控侧前置配置。
- 在拆桨台架上验证「解锁 → 起飞 → 任务 → 降落」完整流程。
- 起飞/悬停无水平速度时四电机应同速（只发总距、忽略姿态）；不要出现大幅度抬头、前电机快于后电机。

## 使用

```bash
# arm:=true 才会解锁起飞（必须拆桨）
bash /app/zettatree_demo/02_bench_pose_sim/run.sh arm:=true
```

不带 `arm:=true` 时管理器处于监视模式：只发设定点，不解锁。

本例程会给管理器传 `--bench`，只写三项，**不放宽任何预检**（无 GPS、磁、
IMU 一致性等保持 PX4 默认）：

| 参数 | 写入 | 默认 | 原因 |
|---|---|---|---|
| `EKF2_EV_CTRL` | `15` | `0` | 融合外部视觉的位置、速度和航向 |
| `COM_DISARM_PRFLT` | `-1` | `10` | 拆桨怠速达不到「已起飞」，避免 10 秒自动上锁 |
| `COM_RC_OVERRIDE` | `3` | `1` | OFFBOARD 下摇杆超阈值回到位置模式 |

不改 `COM_RC_IN_MODE`（默认 3，遥控仍有效）。不写 `EKF2_EV_DELAY`、
`EKF2_HGT_REF`（`3` 是视觉不是测距，且要重启才生效）、`COM_DISARM_LAND`（默认已是 2 秒）
和任何 `MPC_*`。台架转速由姿态设定点油门限制在约 600 r/min。
用姿态设定点切 OFFBOARD 后走强制解锁 21196（无遥控不要用 STABILIZED）。
写前会快照原值，进程退出时尽力写回。PX4 会把参数存到 SD，**重启不会恢复默认**。
若被预检拒绝，只按 QGC 单独回补被拒的那一项。若管理器日志里参数没写上，可另开终端：

```bash
source /app/zettatree_demo/_common/env.sh
ros2 service call /mavros/param/set mavros_msgs/srv/ParamSetV2 \
  "{force_set: true, param_id: 'EKF2_EV_CTRL', value: {type: 2, integer_value: 15}}"
ros2 service call /mavros/param/set mavros_msgs/srv/ParamSetV2 \
  "{force_set: true, param_id: 'COM_DISARM_PRFLT', value: {type: 3, double_value: -1.0}}"
ros2 service call /mavros/param/set mavros_msgs/srv/ParamSetV2 \
  "{force_set: true, param_id: 'COM_RC_OVERRIDE', value: {type: 2, integer_value: 3}}"
```

## 启动参数

| 参数 | 默认值 | 说明 |
|---|---|---|
| `fcu_url` | `/dev/ttyS2:57600` | X5↔飞控 40PIN UART2 串口及波特率 |
| `arm` | `false` | `true` 才切 OFFBOARD 并解锁（台架拆桨） |
| `altitude` | `0.1` | 起飞高度（米）；室内默认实飞 2 m 的 1/20 |
| `max_speed` | `0.1` | 模拟器跟随限速（m/s）；室内默认实飞 2 的 1/20 |
| `rate` | `5.0` | 位姿回灌频率（Hz）；57600 UART 不宜再高 |

## 验证位姿已稳定

```bash
source /app/zettatree_demo/_common/env.sh
ros2 topic hz /mavros/local_position/pose
# 期望 ≥ 30 Hz 且不漂移
```


## 安全

- **必须拆桨**：解锁后电机按飞控指令空转。
- 模拟出的位置只存在于飞控 EKF 内，飞机实际没有移动，不要据此判断真机位置。
- 正常退出会写回原参数。进程若中途断开，装桨前在 QGC 核对：`EKF2_EV_CTRL` 回到 `0`，`COM_DISARM_PRFLT` 回到 `10`。重启飞控不会清除这两项。
