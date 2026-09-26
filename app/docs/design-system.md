# bili 设计系统规范 v0.1（草案）

> 状态：**已定稿**（2026-09-26，zhiq liu 逐条拍板）。
> 事实基线快照：`main` = `f7a2b97`（#99 已合）。#104 `f6d1498`（暗色）与 #97 `0b946f0`（截图基建）
> 当时尚未合入，本规范建在两者之上。
> 所有对比度均为实算（WCAG 2.1 相对亮度公式），非估计。

---

## 0. 已拍板的四条

| # | 决策 |
|---|---|
| 1 | `toThemeData()` **接进生产**，设计系统拥有 ColorScheme。DynamicColor 保留并作为**首选**，当前"品牌色"作不支持动态色设备上的 fallback |
| 2 | 色 token 换成**角色命名**，111 个调用点一次改完 |
| 3 | 硬编码色用 **custom_lint** 规则治（`plugins:` 块要重新加回 `analysis_options.yaml`） |
| 4 | 字体六族**删除配置**，退回系统字体 |
| 5 | 亮色色板**重新取值**，接受亮色观感变化 |
| 6 | DynamicColor 开启时，**自研 widget 也跟随壁纸色相** |

---

## 1. 现状事实

### 1.1 散落点：3 个目录，0 个单一入口

| 位置 | 行数 | 作用 |
|---|---|---|
| `app/lib/styles/styles.dart` | 294 | `AppStyle` + `_Text/_Times/_Corners/_Insets/_Shadows/_Sizes` |
| `app/lib/styles/colors.dart` | 59 | `AppColors`（10 个色 token + `toThemeData()`） |
| `app/lib/styles/color_utils.dart` | 20 | `ColorUtils` |
| `app/lib/styles/color_extensions.dart` | 5 | `Color.colorFilter` |
| **`app/lib/theme_wrapper.dart`** | 49 | **生产主题的真实来源**（在 `styles/` 之外） |
| `app/lib/feature/theme/bloc/` | 15 | themeMode 状态 |
| `app/lib/app_scaffold.dart:30` | — | 唯一引用 `toThemeData()` 的地方，**被注释掉** |

`$styles` 定义在 `main.dart:114`：`AppStyle get $styles => AppScaffold.style;` —— 一个在 `AppScaffold.build` 里被覆写的 **mutable static**。

只有 3 个文件 import `styles/`（全在 `app/` 内），`packages/components` 不依赖 `app`，**没有跨包约束**，可以自由搬。

### 1.2 色 token 表面：10 个，全按外观命名

| token | 调用点 | token | 调用点 |
|---|---|---|---|
| `accent1` | 28 | `greyStrong` | 7 |
| `caption` | 16 | `body` | 5 |
| `black` | 15 | `accent2` | 5 |
| `white` | 11 | `accent3` | 2 |
| `greyMedium` | 11 | `toThemeData` | 1 |
| `offWhite` | 10 | **合计** | **111** |

**零个角色语义**。`black` 一个 token 同时承担前景文字（9 处）和容器背景（6 处）—— 两种语义在暗色下方向相反，这是 #104 那个 bug 的机制。

### 1.3 亮色色板从未做过对比度检查（**本规范的核心依据**）

| 组合 | 实算比值 | 门槛 | 判定 |
|---|---|---|---|
| `accent1` 亮 压 `surface` | **2.10** | 4.5 | **FAIL**（28 处调用中落在浅色页面上的部分） |
| `accent2` 亮 压 `surface` | **1.90** | 3.0 | **FAIL**（forum/播放图标） |
| `accent3` 亮 压 `surface` | **3.01** | 4.5 | **FAIL** |
| `caption` 亮 压 `surface` | **3.77** | 4.5 | **FAIL**（16 处） |
| `greyMedium` 亮 alpha.2 压 `surface` | **2.44** | 3.0 | **FAIL**（分隔线/骨架） |
| `white` 压 `accent1`（onPrimary） | **2.43** | 4.5 | **FAIL**（#104 已修 → 7.04） |
| `body` 亮 压 `surface` | 7.04 | 4.5 | PASS |
| `accent1` 暗 压 `surface` 暗 | 8.68 | 4.5 | PASS |
| `caption` 暗 压 `surface` 暗 | 6.79 | 4.5 | PASS |
| `white` 压 `scrim` | 17.1 / 18.7 | 4.5 | PASS |

**必须推翻的一条既有说法**：#104（和我此前的记忆）把「亮色取值逐字节不变」当作暗色 PR 的**优点**，理由是保证零回归。实算说明它恰恰是**亮色模式至今不可访问的原因**——暗色色板是这次逐个算过的，亮色色板是从 Wonderous 原样搬来的、从未校验过。

### 1.4 已经漏出去的硬编码色（`app/lib/`，排除注释/`Colors.transparent`）

| 位置 | 值 |
|---|---|
| `filter_bar.dart:81` | `Colors.grey[300]` |
| `video_info_view.dart:30/40/50` | `Color(0xFF00A1D6)` `#EF5350` `#FB7299`（B 站服务身份色） |
| `video_card.dart:143` | `Colors.grey` |
| `video_card.dart:238/248` | `Colors.black alpha .75` / `Colors.white` |
| `creator_profile_item.dart:68/74` | `Colors.grey` ×2 |
| `video_player_placeholder.dart:191` | `Colors.black alpha 0.6` |

### 1.5 死代码（调用点为 0 或只存不读）

> 下表在 `51cdc4f` 上用 `git grep` 全仓核实（`app/` + `packages/`，不含本文件）。
> 标「实测」的两项是 P1 落地时新发现的，原清单漏了。

- `ColorUtils` 全类 —— 唯一调用者是 `AppColors.shift()`，而 `shift()` **零调用点**
- `_Shadows`（3 组阴影定义）—— `$styles.shadows` **0 调用点**
- `_Sizes`（maxContentWidth1/2/3、minAppSize）—— `$styles.sizes` **0 调用点**
- `AppStyle.highContrast` —— 只写入，**从不读取**
- `colors.dart` 里「改色值记得同步 web/manifest.json / web/index.html」是**假的**：`app/web/manifest.json:6` 的 `background_color` 现在是 `#0175C2`（Flutter 默认蓝），从没同步过
- **实测**：`color_extensions.dart` 的 `Color.colorFilter` 扩展 —— 全仓 0 调用点（唯一 `export` 在 `colors.dart`）
- **实测**：10 个 0 调用点的 `TextStyle`——`dropCase` / `wonderTitle`（Wonderous 遗留）、`h1` / `h2` / `h4` / `title1` / `quote1` / `quote2` / `quote2Sub` / `callout`，以及 5 个字体族 getter `titleFont` / `quoteFont` / `wonderTitleFont` / `contentFont` / `monoTitleFont`
- **实测**：`fontFeatures: [FontFeature.enable('kern')]` **不是**死配置，R6 不得顺手删。见 R6。

---

## 2. 规范条款

### R1 —— 色值只有一个合法来源

整个 `app/lib/` 里，**字面量颜色只允许出现在两个文件**：

- `app/lib/design/brand_palette.dart` —— 品牌 fallback 色板（亮/暗两套）
- `app/lib/design/service_brands.dart` —— 服务身份色（B 站蓝/粉、YouTube 红），**不参与暗色反转**

其余一切颜色从 `ColorScheme` 派生。G1 门禁强制。

### R2 —— token 按角色命名，外观名一律禁止

不存在 `black` / `white` / `offWhite` / `greyMedium` / `accent1` 这类名字。

| 类别 | token | 来源 |
|---|---|---|
| 表面 | `surface` / `surfaceVariant` / `surfaceContainerHighest` | ColorScheme |
| 前景 | `onSurface` / `onSurfaceVariant` / `outline` / `outlineVariant` | ColorScheme |
| 恒定承载面 | `scrim`（恒深） / `onScrim`（恒浅） | `AppColors` 自有，ColorScheme 无此角色 |
| 强调 | `accentFill`（容器底） / `onAccentFill`（压在上面） / `accentText`（**直接压 surface**，必须 ≥4.5:1） | ColorScheme + 派生 |

**R2.1** `accent` 一个色相必须拆成 **Fill** 和 **Text** 两个角色：现状 `accent1` 在浅色 `surface` 上只有 2.10:1，28 处调用全部共用这一个值。门槛按**用途**分，不按控件分：

| 用途 | 门槛 | 落到哪个 token |
|---|---|---|
| 文本（`Text`、`TabBar.labelColor`、按钮文字） | **4.5:1** | `accentText` |
| 非文本指示器与图形对象（`Slider.activeTrackColor` / `thumbColor`、`CircularProgressIndicator`、Tab 指示条本身） | 3:1 | `accentFill` |

`TabBar.labelColor` 是**文本**，归 4.5:1 一档；3:1 只留给 `activeTrackColor` 这类非文本指示器（WCAG 2.1 Understanding §1.4.3：3:1 是「大文本」与非文本内容的门槛，普通字号文本一律 4.5:1）。

**R2.2 语义不能混用**：`scrim` 与 `onSurface` 在暗色下方向相反，禁止共用常量 —— 这条已由 #104 的注释确立，保留。

### R3 —— 亮度单源

`isDark` 只有一个来源：`Theme.of(context).brightness`，由 `AppScaffold` 注入 `AppStyle`。**禁止任何位置硬编码 `isDark = false`**（这就是接入 Wonderous 时暗色失效的原因）。

### R4 —— ColorScheme 是唯一真值

Material 组件读 `ColorScheme`；`$styles.colors.*` 从**同一个** `ColorScheme` 派生。禁止两套独立色板并存 —— 现状正是如此，所以 `filter_bar.dart:113` 的 `FilledButton` 会算出 2.43:1。

`AppColors` 签名从 `{required bool isDark}` 改为 `AppColors(ColorScheme scheme)`，构造后**不再持有任何硬编码色值**。

### R5 —— DynamicColor 优先，品牌色 fallback

```
DynamicColorBuilder 拿到壁纸色  →  ThemeData.copyWith(colorScheme: dynamic)
拿不到（桌面/旧设备）         →  brand_palette 构造的 fallback ColorScheme
```

因 R4，`$styles.colors` 会自动跟随最终生效的 ColorScheme，**不需要在两处各维护一份色值**。

### R6 —— 字体配置删除

`styles.dart` 里 5 个字体族（Tenor / B612Mono / Cinzel / MaShanZheng / Yeseva / Raleway）× 3 张 Map = 15 条 `TextStyle`，仓库 0 个 `.ttf`/`.otf`，全部静默回落系统字体。半死的配置比没有更糟 —— 删除，文字走 Material `textTheme`。`$styles.text` 保留，但只管字号/行高/字重，不再指定 `fontFamily`。

**`kern` 必须留下。** Raleway 那条 `TextStyle` 上挂着 `fontFeatures: [FontFeature.enable('kern')]`，它不是死配置：实测用 SDK 自带 Roboto 经 `FontLoader` 装载后逐字形比对 caret 位置，开启 `kern` 会让 23 个字形里的 **22 个**发生位移，`fontSize 40` 时最大差约 **15px**。R6 只删 `fontFamily`，`kern` 照旧。`h3` / `title2` 原先走 Tenor、本就没有这个特性，所以保留两个基底样式而不是统一成一个 —— 统一任一方向都会改变真实设备的渲染结果。

### R7 —— 死代码清理

删除 §1.5 全部条目。

---

## 3. 目录结构

目标结构（P2 落地时建立，当前 `app/lib/styles/` 尚未迁移）：

```
app/lib/design/
  brand_palette.dart     # R1 白名单①：品牌 fallback 色板
  service_brands.dart    # R1 白名单②：服务身份色
  app_colors.dart        # 从 ColorScheme 派生的角色访问器，零硬编码色值
  app_theme.dart         # 构造 ThemeData（原 toThemeData 的归宿）
  app_style.dart         # 原 styles.dart：scale / corners / insets / times / text
  contrast.dart          # WCAG 相对亮度与对比度计算（供测试与调色用）
  design.dart            # 唯一入口，re-export 以上全部
```

`app/lib/theme_wrapper.dart` 与 `app/lib/feature/theme/` 并入本目录。`app/lib/styles/` 整体删除。

---

## 4. 门禁

### G1 —— custom_lint：禁止硬编码色

- 新增 workspace 包 `packages/design_lints/`，依赖 `custom_lint` + `custom_lint_builder`
- 一条规则 `no_hardcoded_color`：报**所有**直接构造颜色的形式 —— `Color(0x…)`、`Color.fromARGB`、`Color.fromRGBO`、`Color.from`、以及任何 `Colors.xxx` 常量引用。
- **allow-list 与 R1 逐字一致：只有 `app/lib/design/brand_palette.dart` 和 `app/lib/design/service_brands.dart` 两个文件，无任何例外。** 特别地**不豁免 `.g.dart`** —— 实测当前仓库的生成文件里颜色字面量命中数为 0，豁免它只会留下一条没人用的旁路。
- `analysis_options.yaml` 重新加回 `plugins:` 块（该块刚被删掉，这次是有理由地加回来）
- 选 `custom_lint` 自写规则而非第三方 rule set 的原因：语义要精确到「白名单只有这两个文件」，`altive_lints`（2022 年）和 `clean_code_lints`（0.1.0，带 20+ 条主观规则）都不匹配。规则必须覆盖完整的构造器集合——漏掉 `Color.fromRGBO` 之类就等于门禁形同虚设。

### G2 —— 对比度测试

`app/test/design/contrast_test.dart` 枚举 §1.3 的**受支持组合清单**（不做 18×18 笛卡尔积），在亮/暗两种亮度下各断言一次。

这条测试如果早存在，会当场抓住：#104 的 onPrimary 2.43:1、今天 offWhite-on-scrim 隐形、亮色 `accent1` 2.10:1。**三次事故都是本可自动拦截的。**

---

## 5. 111 个调用点的角色映射

| 现有 | 角色判定 | 新 token | 处数 |
|---|---|---|---|
| `black` | 前景文字 | `onSurface` | 9 |
| `black` | 承载面/渐变 | `scrim`（#104 已改） | 6 |
| `offWhite` | 页面/面板背景 | `surface` | 7 |
| `offWhite` | 深底上的文字 | `onScrim` | 2 |
| `white` | scrim 上前景 | `onScrim` | 待逐个判定 |
| `caption` | 弱化文字 | `onSurfaceVariant` | 16 |
| `body` | 正文 | `onSurface` | 5 |
| `greyMedium`(带 alpha) | 分隔线/弱图形 | `outline` / `outlineVariant` | 11 |
| `greyStrong` | 骨架块/头像底 | `surfaceContainerHighest` | 3 |
| `greyStrong` | 边框/图标容器 | `outlineVariant` | 4 |
| `accent1` | 容器底 | `accentFill` | 部分 |
| `accent1` | 压 surface 的文字/图标 | `accentText` | 部分 |
| `accent1` | `TabBar.labelColor`（文本，4.5:1） | `accentText` | 部分 |
| `accent1` | `TabBar.indicatorColor` / `Slider` / `CircularProgressIndicator`（非文本，3:1） | `accentFill` | 部分 |
| `accent2` | 次级强调 | `secondary` | 5 |
| `accent3` | 三级强调 | `tertiary` | 2 |

`white` 的 11 处需要逐个看压的是什么底，不能机械替换 —— `video_info_view.dart:244/314/596/617` 在条件分支里，底色不固定。

---

## 6. 分阶段实施

设计原则：**让"改变像素"只发生在一个提交里**，这样 golden 只需重录一次。

| PR | 内容 | 像素变化 | 依赖 |
|---|---|---|---|
| **P1** | 死代码清理 + 字体剥离（R6/R7） | 仅测试环境，见下 | #104 ✅ 已合 |
| **P2** | 结构收敛 + 角色改名：建 `design/`、R1~R4、R2.1、`toThemeData()` **仍不接线** | 无 | P1、#104 ✅、#97 |
| **P3** | **改像素的主力**：亮色色板重取值 + `ThemeWrapper` 接线 + DynamicColor 优先 + G2 测试全绿 | **有 → golden 在此重录** | P2 |
| **P4** | custom_lint 门禁（G1） | 无 | P2 |

P2 保持 `toThemeData()` 不接线，是为了让「Material 组件首次拿到颜色」这件事单独落在 P3，golden 失效原因唯一。

### P1 的像素变化是真实的，且只在测试环境

原方案写 P1「无像素变化」，**这是错的**，P1 落地时实测推翻：把 R6 的字体族删掉后，golden 变了 —— `video_card` 1.83% 的像素、`video_feed_section` 1.63%。

二分定位：只删死代码（不动字体族）→ 与基线**逐字节一致**；只把 `fontFamily` 换成基底样式 → 出现差异。所以差异源是 R6 本身，不是死代码删除。

机理：**指定一个不存在的字体族，会把回落限制在默认字体；不指定则走引擎的完整回落链。** 两条路径只在「主字体缺该字形」时分开。golden 跑在 flutter_test 里，唯一可用字体是只含拉丁字形的 Ahem，于是中文全部落到 notdef —— 实测差异就集中在 `VideoCard` 头像那个 `Text(creatorName[0])` 上：改动前是 1em 宽的实心方块，改动后是一根窄竖条。

真实设备上两条路径都会落到平台默认字体 + 平台 CJK 回落（Noto 等），预期渲染一致；本沙箱没有 Android/iOS 渲染器，**这一点无法在此证实**，只能标注为预期。

因此 golden 基线要重录两次而不是一次：一次是 P1 让测试环境的 notdef 形状对齐（若 P1 先于 #97 合入，则由 #97 重录），一次是 P3 的真实改色。**合并顺序决定这次重录记在谁头上**，不改变总次数。

---

## 7. 已拍板事项记录

1. **亮色色板重新取值** —— 接受 `accent1` / `caption` / `accent2` / `accent3` 在亮色下变深带来的观感变化，同时放弃「亮色取值逐字节不变」这一性质。
2. **自研 widget 跟随壁纸色相** —— `AppColors` 从 ColorScheme 派生，品牌色只存在于 fallback 色板里，不在两处各维护一份色值。
3. **B 站身份色（`#00A1D6` / `#EF5350` / `#FB7299`）不是 UI token** —— 它们是服务身份而非界面角色，落在 `service_brands.dart`，参与 R1 白名单，且不参与暗色反转。
