# 性能基线采集

本页规定如何在 **profile 模式**下采集可复现的帧时间基线，用于验证性能改动。开发政策见根 [`AGENTS.md`](../AGENTS.md)；事故恢复见 [`runbook.md`](runbook.md)。本文不授予推送、合并或 bypass 权限。

> 只适用于有真实渲染目标的环境（带显示或可用的桌面 / 移动设备）。**定时巡检的 agent 容器不具备该能力**，见文末[环境限制](#环境限制)。

## 目的与范围

- 目标：在改动前后用**同一场景、同一目标**对比 UI/raster 帧时长与丢帧数，用测量结论而非成本估算支撑 `⚡ Bolt:` 性能 PR。
- 本流程与 `tool/compare_perf_baselines.py` **只比较帧时长与丢帧**。内存（分配/常驻）需另行用 DevTools Memory 在指定生命周期点采集并在 PR 记录，本工具不比较内存，不得用本流程支撑内存主张。
- debug 构建与 widget 测试的耗时**不能**作为性能证据。`flutter test`（含 golden）跑在 debug/JIT，`flutter_tester` 的耗时与真机 profile 无关。

## 命名目标

固定使用一个**命名目标**，前后两次必须一致：

| 项 | 约定 |
| -- | -- |
| 目标 | Linux 桌面，`flutter run -d linux --profile`（从 `app/` 运行） |
| 设备标识 | `device` 必须唯一标识**物理机器**（如 hostname），`target.hardware` 记录 CPU/GPU，前后必须一致 |
| 窗口 | 1280×900，文本缩放 1.0，采集前确认实际尺寸 |
| 刷新率 | 60 Hz（帧预算 16.67 ms；其他刷新率按 `1000 / hz` 换算） |
| 构建 | `--profile`，记录 Flutter / Dart 版本与源码 revision |
| 数据源 | 固定数据集（固定条目数/排序）；采集期间不变，前后一致（见[固定数据集](#固定数据集前置条件)） |

移动端请另立目标（记录设备型号、OS、刷新率），但同一对比的两侧不能混用目标。

## 采集步骤

1. 确认 SDK 与仓库 pin 一致（见 [`CONTRIBUTING.md`](../CONTRIBUTING.md#开发环境)），在仓库根执行 `flutter pub get`。
2. 从 `app/` 启动 profile 构建：

   ```bash
   (cd app && flutter run -d linux --profile)
   ```

3. 把窗口固定为 1280×900 并确认实际尺寸（例如 `wmctrl -r :ACTIVE: -e 0,0,0,1280,900`，或用 DevTools 读取 `MediaQuery.sizeOf`）；尺寸不符时测量结果不可比。
4. 每个场景先**预热**（例如 5 秒滚动 / 播放）再开始采样，固定交互序列与缓存状态（冷 / 热）。
5. 每个场景**至少重复 3 次**（同一时长或交互次数）。每次记录：

   - `ui_frame_ms_median`、`ui_frame_ms_p90`：UI 线程帧时长（ms）；
   - `raster_frame_ms_median`、`raster_frame_ms_p90`：raster 线程帧时长（ms）；
   - `missed_frames`：超过帧预算（60 Hz 为 16.67 ms）的帧数（整数）。

   用 DevTools 的 Performance / Timeline 视图或 `flutter run --profile` 的 VM service timeline 采集，取中位数与 p90，不用平均值掩盖尾部。

6. 场景（三选一或全部，按改动热点选择）：

   | 键 | 交互 |
   | -- | -- |
   | `home_feed_scroll` | 首页「热门视频」两列列表连续滚动 |
   | `video_danmaku` | 视频详情页播放，弹幕浮层开启 |
   | `live_danmaku` | 直播间播放，弹幕浮层开启 |

## 固定数据集（前置条件）

profile 运行默认使用真实数据源与 HTTP 客户端（[`app/lib/main.dart`](../app/lib/main.dart)），仓库目前**没有**内建的离线 fixture 开关。要得到可复现的基线，先固定数据集，二选一：

- 使用本地 fixture 服务，把条目数、来源写入基线备注；
- 在**仅用于采集的临时分支**上注入固定 `MediaSource` / fake HTTP client（不入库），固定条目数与排序。

列表数据固定即可；`video_danmaku` / `live_danmaku` 还需要一个**可访问的固定播放流 URL**（允许网络），把该 URL 一并记入基线，前后必须一致。无法固定时，只能接受网络数据变化带来的噪声，并在 PR 中记录数据集来源；改动前后必须使用同一数据集。

## 基线 JSON 结构

一次采集结果存成一个 JSON，**入库到版本控制**（建议 `docs/perf-baselines/<date>-<slug>.json`）。`tool/compare_perf_baselines.py` 依赖以下结构：

```json
{
  "schema_version": 1,
  "target": {
    "device": "workstation-01",
    "hardware": "AMD Ryzen 7 5800X / AMD RX 6700 XT",
    "os": "Debian GNU/Linux 13",
    "display_refresh_hz": 60,
    "viewport": "1280x900",
    "text_scale": 1.0
  },
  "build": {
    "mode": "profile",
    "flutter": "3.50.0",
    "dart": "3.14.0",
    "revision": "0123456"
  },
  "scenarios": {
    "home_feed_scroll": {
      "duration_seconds": 20,
      "warmup_seconds": 5,
      "runs": [
        {
          "ui_frame_ms_median": 8.1,
          "ui_frame_ms_p90": 12.4,
          "raster_frame_ms_median": 4.2,
          "raster_frame_ms_p90": 7.9,
          "missed_frames": 3
        }
      ]
    }
  }
}
```

- `build.mode` 必须是 `profile`，否则工具拒绝比较。
- `runs` 至少 3 条；少于 3 条时工具给出警告（协议要求 ≥3 次以体现波动）。
- `missed_frames` 必须是整数；场景键只允许字母、数字、`_`、`.`、`-`（会打印到终端）。
- `target` 的 `device` / `os` / `display_refresh_hz` / `viewport` / `text_scale` 在前后两次中必须一致；`device` 须唯一标识物理机器，`hardware`（CPU/GPU）可选但两侧都记录时必须一致。
- 同一场景的 `duration_seconds` 在前后两次中必须一致，否则工具拒绝比较；缺失时只给警告（无法确认采样长度一致）。
- `build.revision` 前后不同是正常的（就是要比较改动前后）；`flutter` / `dart` 默认必须一致，否则工具拒绝比较。

## 前后对比

采集改动前后的两份基线后，用工具对比：

```bash
python3 tool/compare_perf_baselines.py before.json after.json
```

- 输出每个场景、每个指标的中位数、百分比变化与波动范围；
- 任一「越低越好」的指标相对基线上升超过 `--threshold`（默认 `5.0`%）即判为回归，退出码 `1`；否则退出码 `0`；输入不合规、目标不兼容或前后没有可配对场景时退出码 `2`。
- 只比较指定场景：`--scenario home_feed_scroll --scenario live_danmaku`。
- 机器可读输出：`--json`。
- 只有在工具链确实不可避免变化时才用 `--allow-toolchain-drift`，并在 PR 中说明。

工具只做数值对比，**不采集数据**。采集必须按上文在命名目标上完成，不得用估算或 debug 耗时替代。

## 环境限制

定时巡检（`.jules/bolt-prompt.md`）在无显示、无 GPU、无 Flutter SDK 的 agent 容器内运行，**结构上无法**建立 profile 基线：

- 容器内 `flutter` / `dart` 可能不存在，也没有桌面 / 移动设备；
- 即使临时装 SDK，也没有可渲染的命名目标，也没有可注入固定数据集的运行环境；视频/直播场景还依赖真实流。

因此这类运行**只产出工单，不产出实测性能 PR**；边界与产出模板见 `.jules/bolt-prompt.md`。需要实测时，由具备桌面或设备的环境按下文采集，再用 `tool/compare_perf_baselines.py` 对比。
