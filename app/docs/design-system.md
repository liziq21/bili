# bili 设计系统规范 v0.2

> 状态：**已定稿**。v0.2 于 2026-09-27 修订，记录 18 项修订，逐条见 §8。
> 对比度均为 WCAG 2.1 相对亮度公式实算，测量条件见各表脚注，非估计。
> **两套基线不要混用**：§1 是 #104 之前的历史快照，§5 的映射表在 #104 之后的真实基线上重算。

---

## 0. 已拍板的七条

| # | 决策 |
|---|---|
| 1 | `toThemeData()` **接进生产**，设计系统拥有 ColorScheme。DynamicColor 保留并作为**首选**，当前品牌色作不支持动态色设备上的 fallback |
| 2 | 色 token 换成**角色命名**。v0.1 写的「111 个调用点」是 #104 之前的基线且把 `toThemeData` 这个定义算作调用点，真实调用点见 §5 |
| 3 | 硬编码色用 **custom_lint** 规则治（`plugins:` 块要重新加回 `analysis_options.yaml`） |
| 4 | 字体六族**删除配置**，退回系统字体 |
| 5 | 亮色色板**重新取值**，接受亮色观感变化 |
| 6 | DynamicColor 开启时，**自研 widget 也跟随壁纸色相**。同屏出现两种以上不受壁纸色相约束的强调色相属缺陷，见 R8 |
| 7 | **服务源无关性** —— app 的界面与设计系统不得按服务源分支，服务身份色不进设计系统。见 R8 |

---

## 1. 历史基线快照（#104 之前，`f7a2b97`）

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

**import 面**：直接 import `styles/` 的共 **4 个文件**，其中 2 个是测试（`app/test/styles_test.dart`、`app/test/styles_dark_test.dart`），生产代码只有 2 个（`app/lib/app_scaffold.dart`、`app/lib/main.dart`）。v0.1 此处写「只有 3 个文件」是错的。`packages/components` 不依赖 `app`，**无跨包约束**，可以自由搬。

### 1.2 色 token 表面：10 个，全按外观命名

| token | 调用点 | token | 调用点 |
|---|---|---|---|
| `accent1` | 28 | `greyStrong` | 7 |
| `caption` | 16 | `body` | 5 |
| `black` | 15 | `accent2` | 5 |
| `white` | 11 | `accent3` | 2 |
| `greyMedium` | 11 | `toThemeData` | 1 |
| `offWhite` | 10 | **合计** | **111** |

合计 111 里含 `toThemeData` 这个**定义**（不是调用点），实际调用点 **110**。

**零个角色语义**。`black` 一个 token 同时承担前景文字与容器背景 —— 两种语义在暗色下方向相反，这是 #104 那个 bug 的机制。

### 1.3 亮色色板从未做过对比度检查

| 组合 | 实算比值 | 门槛 | 判定 |
|---|---|---|---|
| `accent1` 亮 压 `surface` | **2.10** | 4.5 | **FAIL** |
| `accent2` 亮 压 `surface` | **1.90** | 3.0 | **FAIL** |
| `accent3` 亮 压 `surface` | **3.01** | 4.5 | **FAIL** |
| `caption` 亮 压 `surface` | **3.77** | 4.5 | **FAIL**（16 处） |
| `greyMedium` 亮 alpha.2 压 `surface` | **2.44** | 3.0 | **FAIL**（分隔线/骨架） |
| `white` 压 `accent1`（onPrimary） | **2.43** | 4.5 | **FAIL**（#104 已修 → 7.04） |
| `body` 亮 压 `surface` | 7.04 | 4.5 | PASS |
| `accent1` 暗 压 `surface` 暗 | 8.68 | 4.5 | PASS |
| `caption` 暗 压 `surface` 暗 | 6.79 | 4.5 | PASS |
| `white` 压 `scrim` | 17.1 / 18.7 | 4.5 | PASS |

**必须推翻的一条既有说法**：#104 把「亮色取值逐字节不变」当作暗色 PR 的**优点**，理由是保证零回归。实算说明它恰恰是**亮色模式至今不可访问的原因**——暗色色板逐个算过，亮色色板从 Wonderous 原样搬来、从未校验。

### 1.4 已经漏出去的硬编码色

在 `app/lib/` 内、`styles/colors.dart` 之外实测（排除注释行与 `Colors.transparent`）：**10 处**。v0.1 写「9 处」是错的，且行号 `video_player_placeholder.dart:191` 应为 **195**。

| 位置 | 值 | v0.2 去向 |
|---|---|---|
| `filter_bar.dart:81` | `Colors.grey[300]` | → `outline`（P4 前迁） |
| `video_card.dart:143` | `Colors.grey` | → `outline`（P4 前迁） |
| `video_card.dart:238` | `Colors.black` alpha .75 | → `scrim` 带 alpha（P4 前迁） |
| `video_card.dart:248` | `Colors.white` | → `onScrim`（P4 前迁） |
| `creator_profile_item.dart:68` | `Colors.grey` | → `outline`（P4 前迁） |
| `creator_profile_item.dart:74` | `Colors.grey` | → `outline`（P4 前迁） |
| `video_player_placeholder.dart:195` | `Colors.black` alpha 0.6 | → `scrim` 带 alpha（P4 前迁） |
| `video_info_view.dart:30/40/50` | `#00A1D6` `#EF5350` `#FB7299` | **已随 v0.2 删除**，见 R8 |

**这 7 处在 v0.1 里没有任何一期负责迁移**，而 G1 上线即会报出它们 —— 见 C1 的修订。

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

### R1 —— 色值只有一个合法来源，且白名单同时约束路径与内容

整个 `app/lib/` 里，字面量颜色只允许出现在**一个**文件：

- `app/lib/design/brand_palette.dart` —— 品牌 fallback 色板（亮/暗两套）+ `ColorScheme` 构造

其余一切颜色从 `ColorScheme` 派生。G1 门禁强制。

**v0.1 的漏洞**：allow-list 按**文件路径**授权、不约束**内容**，等于给两个文件开了「不限内容」的后门 —— 任何服务源都能来这里加条目（实际已发生，见 R8）。v0.2 追加内容约束：

1. 白名单从两个文件**收缩为一个**（`service_brands.dart` 取消，依据见 R8）。
2. 白名单文件内**不得出现按外部实体命名的条目** —— 实体指服务源、页面、功能模块、品牌方。允许的只有：色值常量、`ColorScheme` 构造、`isDark` 分支取值。
3. 增删色值只能改 `brand_palette.dart`；任何「这里需要一个新颜色」的需求，先问它属不属于**界面角色**（R2），不属于就不该进这个文件。

### R2 —— token 按角色命名，外观名一律禁止

不存在 `black` / `white` / `offWhite` / `greyMedium` / `accent1` 这类名字。

| 类别 | token | 来源 |
|---|---|---|
| 表面 | `surface` / `surfaceVariant` / `surfaceContainerHighest` | ColorScheme |
| 前景（三档） | `onSurfaceStrong`（主前景，原 `black`） / `onSurface`（正文，原 `body`） / `onSurfaceVariant`（弱化，原 `caption`） | ColorScheme + 派生 |
| 图形 | `outline` | ColorScheme |
| 恒定承载面 | `scrim`（恒深） / `onScrim`（恒浅） | `AppColors` 自有，ColorScheme 无此角色 |
| 强调 | `accentFill`（容器底/图形 3:1） / `accentText`（**直接压 surface**，≥4.5:1） | ColorScheme + 派生 |
| 次/三级强调 | `secondary` / `tertiary` | ColorScheme |

**前景为什么是三档**：v0.1 的 §5 把 `black`(9 处) 与 `body`(5 处) 同映射 `onSurface`，但两者亮色取值不同（`#1E1B18` vs `#514F4D`）。合并会改像素，与 §6 的 P2「无像素变化」直接冲突。实测三种用途确实分三档，故增设 `onSurfaceStrong`。三档对应关系：

| 档 | 原 token | 亮色取值 | 用途 |
|---|---|---|---|
| `onSurfaceStrong` | `black` | `#1E1B18` | 主标题、时长标签等主前景 |
| `onSurface` | `body` | `#514F4D` | 正文 |
| `onSurfaceVariant` | `caption` | `#7D7873` | 弱化文字（16 处） |

**`outlineVariant` 不暴露**：v0.1 的 §5 预测 `greyStrong` 有 4 处边框用途，实测 7 处全是容器底（头像底、缩略图占位、弱化背景），`outlineVariant` 零调用。按 R7 不暴露零调用的 getter。

**R2.1** `accent` 一个色相必须拆成 **Fill** 和 **Text** 两个角色，门槛按**用途**分：

| 用途 | 门槛 | token |
|---|---|---|
| 文本（`Text`、`TabBar.labelColor`、按钮文字） | **4.5:1** | `accentText` |
| 非文本指示器与图形对象（`Slider.activeTrackColor`/`thumbColor`、`CircularProgressIndicator`、Tab 指示条本身） | 3:1 | `accentFill` |

`TabBar.labelColor` 是**文本**，归 4.5:1 一档；3:1 只留给非文本指示器（WCAG 2.1 Understanding §1.4.3：普通字号文本一律 4.5:1）。

> **R2.1 的 4.5:1 是 P3 条件成立的门槛。** `accentText` 亮色当前 2.10:1，`onSurfaceVariant` 亮色 3.77:1，两者都不达标；提值属 §6 的 P3。在 P3 落地前，任何声称「已满足 R2.1」的说法都是错的。

**R2.2 语义不能混用**：`scrim` 与 `onSurface` 在暗色下方向相反，禁止共用常量 —— 这条已由 #104 的注释确立，保留。

### R3 —— 亮度单源

`isDark` 只有一个来源：`Theme.of(context).brightness`，由 `AppScaffold` 注入 `AppStyle`。**禁止任何位置硬编码 `isDark = false`**。

### R4 —— ColorScheme 是唯一真值

Material 组件读 `ColorScheme`；`$styles.colors.*` 从**同一个** `ColorScheme` 派生。禁止两套独立色板并存 —— 现状正是如此，所以 `filter_bar.dart:113` 的 `FilledButton` 会算出 2.43:1。

**签名修正**：v0.1 写 `AppColors(ColorScheme scheme)` 且「构造后不再持有任何硬编码色值」，**这条不可实现** —— `scrim` / `onScrim` / `onSurfaceStrong` 三个角色在 `ColorScheme` 里没有对应字段。实际签名是：

```dart
class const AppColors(final BrandPalette _palette)   // 色板同时携带 ColorScheme 与这三个自有角色
```

约束不变的部分：这三个自有角色**只在 `brand_palette.dart` 取值**，其余全部从 `palette.scheme` 派生，单一来源不破。

### R5 —— DynamicColor 优先，品牌色 fallback

```
DynamicColorBuilder 拿到壁纸色  →  ThemeData.copyWith(colorScheme: dynamic)
拿不到（桌面/旧设备）         →  brand_palette 构造的 fallback ColorScheme
```

### R6 —— 字体配置删除

`styles.dart` 里 6 个字体族（Tenor / B612Mono / Cinzel / MaShanZheng / Yeseva / Raleway）× 3 张 Map = 15 条 `TextStyle`，仓库 0 个 `.ttf`/`.otf`，全部静默回落系统字体。删除配置，文字走 Material `textTheme`（由 `Material` 内部那层 `AnimatedDefaultTextStyle(theme.textTheme.bodyMedium)` 送达，见 `material.dart:476`；**不是**经 `AppScaffold` 的 `DefaultTextStyle`，那层在 `Material` 之上、够不到普通 `Text`）。`$styles.text` 保留，但只管字号/行高/字重，不再指定 `fontFamily`。

**`kern` 必须留下。** Raleway 那条 `TextStyle` 上挂着 `fontFeatures: [FontFeature.enable('kern')]`：实测用 SDK 自带 Roboto 经 `FontLoader` 装载后逐字形比对 caret 位置，开启 `kern` 会让 23 个字形里的 **22 个**发生位移，`fontSize 40` 时最大差约 **15px**。R6 只删 `fontFamily`。`h3` / `title2` 原先走 Tenor、本就没有这个特性，保留两个基底样式而不是统一 —— 统一任一方向都会改变真实设备的渲染结果。

### R7 —— 死代码清理

删除 §1.5 全部条目。**推论**：零调用的 token getter 一律不暴露（`outlineVariant` 即依此处理，见 R2）。

### R8 —— 服务源无关性（v0.2 新增）

**app 的界面与设计系统不得按服务源分支。**

判定标准：一个构造的名字里如果出现服务方（bilibili / youtube / peertube / piped），它就属于服务源，而不是界面角色。

**为什么**：设计系统是 app 自身的语言。一旦它按服务源开条目，新增服务就要改设计系统 —— 依赖方向反了，且 app 的视觉一致性交给了外部实体决定。

**具体禁止**：

1. 设计系统内不得有按服务源命名的常量、类或文件。v0.1 的 `service_brands.dart` 违反此条，已删除。
2. 同一屏内不得出现两种以上不受壁纸色相约束的强调色相（与决策 6 同源）。三张来源卡片曾同时渲染 `#00A1D6` / `#EF5350` / `#FB7299`，违反此条。
3. 界面文案、默认输入、交互行为不得由服务源身份决定。

**服务身份的正确承载方式**，若产品确需展示：

- 品牌色属**数据层**（服务描述符）的属性，随内容一起进入，不进设计系统；
- 渲染成**标识图形**（logo / 图标），不是彩色文字 —— 一个服务的品牌色不是为压在别人家表面上当正文设计的。实测这三个色值作 9px 文字色，亮色 `#F8ECE5` 背景下为 **2.56 / 3.01 / 2.27 : 1**，全部低于 4.5:1；
- 设计系统只定义**使用规则**（对比度下限、只许在徽章上、永不作正文色），**永不按服务开条目**；
- 来源身份优先由**文字本身**承载（本例中「BILIBILI」已在，无需额外颜色）。

**服务清单的正确落点**：`app/lib/providers/media_sources_provider.dart` 的 `defaultMediaSources` —— app 决定支持哪些服务，这是配置，不是设计系统。`service_source_providers.dart` 里按服务名 switch 构造实例，同属数据/DI 层，位置正确；已知缺陷是 `_ => null` 对未知服务源静默失败，另有待办。

---

## 3. 目录结构

```
app/lib/design/
  brand_palette.dart     # R1 唯一白名单：品牌 fallback 色板 + ColorScheme 构造 + 三个自有角色取值
  app_colors.dart        # 从 ColorScheme 派生的角色访问器，零硬编码色值
  app_theme.dart         # 构造 ThemeData（原 toThemeData 的归宿）
  app_style.dart         # 原 styles.dart：scale / corners / insets / times / text
  contrast.dart          # WCAG 相对亮度与对比度计算（供测试与调色用）
  design.dart            # 唯一入口，re-export 以上全部
```

`app/lib/theme_wrapper.dart` 与 `app/lib/feature/theme/` 并入本目录。`app/lib/styles/` 整体删除。

v0.1 此处列了 `service_brands.dart`，依据 R8 取消。

---

## 4. 门禁

### G1 —— custom_lint：禁止硬编码色

- 新增 workspace 包 `packages/design_lints/`，依赖 `custom_lint` + `custom_lint_builder`
- 一条规则 `no_hardcoded_color`：报**所有**直接构造颜色的形式 —— `Color(0x…)`、`Color.fromARGB`、`Color.fromRGBO`、`Color.from`、以及任何 `Colors.xxx` 常量引用。`Colors.transparent` 豁免（无语义，不构成硬编码色）。
- **allow-list 与 R1 逐字一致：只有 `app/lib/design/brand_palette.dart` 一个文件。** 特别地**不豁免 `.g.dart`** —— 实测仓库生成文件的颜色字面量命中数为 0，豁免它只会留下一条没人用的旁路。
- **上线前置**：§1.4 剩的 7 处必须在 G1 上线前迁完，否则门禁一次报出 7 处。迁移归属 P4，同 PR 内完成（见 §6）。
- `analysis_options.yaml` 重新加回 `plugins:` 块
- 选 `custom_lint` 自写规则而非第三方 rule set 的原因：语义要精确到「白名单只有一个文件且内容受限」，`altive_lints`（2022 年）和 `clean_code_lints`（0.1.0，带 20+ 条主观规则）都不匹配。规则必须覆盖完整的构造器集合——漏掉 `Color.fromRGBO` 之类就等于门禁形同虚设。

### G2 —— 对比度测试

`app/test/design/contrast_test.dart` 枚举 §1.3 的**受支持组合清单**（不做笛卡尔积），在亮/暗两种亮度下各断言一次。

这条测试如果早存在，会当场抓住：#104 的 onPrimary 2.43:1、offWhite-on-scrim 隐形、亮色 `accent1` 2.10:1。**三次事故都是本可自动拦截的。**

**G2 必须先于 G1 满额通过**：G1 会让 §1.4 的 7 处无处可去（先迁完），但真正的门禁价值在 G2 —— 它拦住的是「改了色板但没算对比度」。反序上线会出现「门禁绿了但界面仍不可访问」。

**golden 覆盖声明**（v0.2 新增）：仓库现有 golden 只有两张 —— `video_card.png`、`video_feed_section.png`，**且只录亮色**。因此：

- 「零像素变化」这类结论的验证范围**仅限这两张图覆盖的 widget 与亮色**；
- `video_info_view.dart`（来源徽章、时长标签、日志面板）、`video_player_placeholder.dart`、`filter_bar.dart`、`creator_profile_item.dart`、以及**全部暗色渲染**都不在 golden 覆盖内，这些区域的改动必须靠实跑 + G2 断言证明，不能靠「golden 没动」推断。

---

## 5. 调用点角色映射

**基线：`b22c614`（#104 合入后，v0.1 写「111 个调用点」是 #104 之前的数）。**

§1.2 的 111 含 `toThemeData` 这个定义，实际调用点 110；#104 把 6 处 `black` 改为 `scrim`、4 处 `offWhite` 改为 `onScrim`（现名 `white`），故真实基线为 **104**，逐 token 实测如下。

| 原 token | 处数 | 角色判定 | 新 token |
|---|---|---|---|
| `black` | 9 | 主前景 | `onSurfaceStrong` |
| `offWhite` | 6 | 页面/面板背景 | `surface` |
| `white` | 15 | scrim 上前景 | `onScrim` |
| `caption` | 16 | 弱化文字 | `onSurfaceVariant` |
| `body` | 5 | 正文 | `onSurface` |
| `greyMedium`（带 alpha） | 11 | 分隔线/弱图形 | `outline` |
| `greyStrong` | 7 | **全部是容器底**（头像底、缩略图占位、弱化背景） | `surfaceContainerHighest` |
| `accent2` | 5 | 次级强调 | `secondary` |
| `accent3` | 2 | 三级强调 | `tertiary` |
| `accent1` | 28 | 其中 9 处文本 | `accentText` |
| `accent1` | （同上 28） | 其中 19 处指示器/图标/容器底 | `accentFill` |
| **合计** | **104** | | |

**v0.1 此表的三处错误**（均已按实况修正）：

1. `black` 与 `body` 同映射 `onSurface` —— 两者亮色取值不同，见 R2 的三档表；
2. `greyStrong` 预测「3 底 + 4 边框」—— 实测 7 处全是容器底，`outlineVariant` 零调用；
3. `white` 一行写「待逐个判定」就定稿了 —— 实测 15 处全为 scrim 上前景；`offWhite` 两行相加 9 与 §1.2 的 10 对不上。

`accent1` 的 9/19 分档是**按用途**判定的（文本 vs 图形），两档当前**共用同一个取值** —— 真正的分档提值属 P3。

---

## 6. 分阶段实施

设计原则：**让「改变像素」只发生在一个提交里**，这样 golden 只需重录一次。

| PR | 内容 | 像素变化 | 依赖 |
|---|---|---|---|
| **P1** | 死代码清理 + 字体剥离（R6/R7） | 仅测试环境，见下 | #104 ✅ 已合 |
| **P2** | 结构收敛 + 角色改名：建 `design/`、R1~R4、R8、`toThemeData()` **仍不接线** | 亮色无；含两处缺陷修复，见下 | P1、#104 ✅、#97 |
| **P3** | **改像素的主力**：亮色色板重取值（含 R2.1 提值）+ `ThemeWrapper` 接线 + DynamicColor 优先 | **有 → golden 在此重录** | P2 |
| **P4** | §1.4 剩 7 处迁移 + custom_lint 门禁（G1） | 无 | P2、G2 满额通过 |

P2 保持 `toThemeData()` 不接线，是为了让「Material 组件首次拿到颜色」这件事单独落在 P3，golden 失效原因唯一。

**v0.1 把 R2.1 完整列在 P2 是错的**：R2.1 要求 `accentText ≥4.5:1`，而提值在 P3。照 v0.1 执行，P2 会交付一个违反自己 R2.1 的系统。v0.2 把 R2.1 标为 P3 条件成立（见 R2.1 脚注），P2 只做**角色拆分**，不做提值。

### P2 的两处缺陷修复（超出「亮色零像素」，已拍板）

「P2 不改像素」约束的是**不主动改**，不覆盖缺陷修复：

1. `video_info_view.dart` 时长标签底色原为 `onSurfaceStrong.withValues(alpha: 0.7)` —— 前景 token 当背景用，暗色下浅奶油底 + 白字约 1.2:1 不可读。改 `scrim`。亮色下两者同值 `#1E1B18`，golden 不受影响。
2. 来源徽章的品牌色删除（依据 R8）—— 3 个色相 → 1 组 app 角色（chip 底 `onSurfaceVariant` 0.15 alpha，文字 `onSurface`），**这是 P2 内的像素变化**。理由是 `service_brands.dart` 这个结构本身就是 P2 造错的，不应带进 P3。该区域不在 golden 覆盖内（见 G2 覆盖声明），实测确认两张 golden 未变。

   文字取 `onSurface` 而非 `onSurfaceVariant` 的实测依据：chip 底是 `onSurfaceVariant` 的 0.15 alpha 合成，文字若同用 `onSurfaceVariant`，亮色实测 **3.21:1**（暗色 5.25:1），低于 9px 文字的 4.5:1 门槛；改 `onSurface` 后亮色 **6.00:1**、暗色 **10.12:1**。测量条件为 WCAG 2.1 相对亮度公式，chip 底按 `0.15*onSurfaceVariant + 0.85*surface` 合成。去掉 chip 反而退回 3.77:1（与相邻 `time` 文本同一欠账），故保留 chip。

### P1 的像素变化是真实的，且只在测试环境

原方案写 P1「无像素变化」，**这是错的**，P1 落地时实测推翻：把 R6 的字体族删掉后，golden 变了 —— `video_card` 1.83% 的像素、`video_feed_section` 1.63%。

二分定位：只删死代码（不动字体族）→ 与基线**逐字节一致**；只把 `fontFamily` 换成基底样式 → 出现差异。所以差异源是 R6 本身，不是死代码删除。

机理：**指定一个不存在的字体族，会把回落限制在默认字体；不指定则走引擎的完整回落链。** 两条路径只在「主字体缺该字形」时分开。golden 跑在 flutter_test 里，唯一可用字体是只含拉丁字形的 Ahem，于是中文全部落到 notdef —— 实测差异就集中在 `VideoCard` 头像那个 `Text(creatorName[0])` 上：改动前是 1em 宽的实心方块，改动后是一根窄竖条。

真实设备上两条路径都会落到平台默认字体 + 平台 CJK 回落（Noto 等），**这是预期，本沙箱没有 Android/iOS 渲染器，无法证实**。

---

## 7. 已拍板事项记录

1. **亮色色板重新取值** —— 接受 `accent1` / `caption` / `accent2` / `accent3` 在亮色下变深带来的观感变化，同时放弃「亮色取值逐字节不变」这一性质。
2. **自研 widget 跟随壁纸色相** —— `AppColors` 从 ColorScheme 派生，品牌色只存在于 fallback 色板里。
3. **服务身份色不进设计系统**（v0.2 取代 v0.1 第 3 条）—— v0.1 写「B 站身份色不是 UI token，落在 `service_brands.dart`」，该处置**已被推翻**：它使设计系统成为服务源注册表。正确处置见 R8。三个色值的服务对象是 `onTap: null` 的 `static const` 演示卡片，`source` 字段背后无数据模型。
4. **新增第三档前景 `onSurfaceStrong`** —— v0.1 把 `black` 与 `body` 同映射 `onSurface`，两者亮色取值不同，合并即改像素。见 R2。

---

## 8. v0.2 修订记录

2026-09-27 审查，共 18 条。前 3 条是架构性的，第 4 条是缺失的原则，中间 10 条是与实况不符，最后 4 条涉及门禁与分阶段。

**架构性**

1. **A1** G1 allow-list 按文件路径授权、不约束内容 —— 收缩为单文件并追加内容约束（R1）。
2. **A2** §7.3 / §3 / §1.4 / R1 四处共同确立「服务身份色进设计系统」，依赖方向反了 —— 全面撤销（R1、R8、§3、§7）。
3. **A3** 与决策 6 自相矛盾：service_brands 的色相既不跟随壁纸也不参与暗色反转 —— 已随 A2 消除，并写进 R8 第 2 条。

**缺失的原则**

4. **D** 规范从未写过「界面与设计系统不得按服务源分支」，所以设计系统里的 `service_brands.dart` 和界面里的 `home_screen.dart` 服务源分支都能畅通无阻 —— 新增 R8。

**与实况不符（均已实测）**

5. **B1** §0 标题「已拍板的四条」，表格 7 行。
6. **B2** §5「111 个调用点」是 #104 之前的基线且把定义算作调用点 —— 改为 104 并给出逐 token 实测（§5）。
7. **B3** §1.1「只有 3 个文件 import `styles/`」实为 4 个，其中 2 个是测试。
8. **B4** §5 把 `black` 与 `body` 同映射 `onSurface`，两者亮色取值不同 —— 增设第三档 `onSurfaceStrong`（R2、§7.4）。
9. **B5** §5 `greyStrong`「3 底 + 4 边框」实为 7 处全容器底 —— 全映射 `surfaceContainerHighest`，`outlineVariant` 零调用不暴露（R2）。
10. **B6** §5 `white`「待逐个判定」即定稿 —— 实测 15 处全为 scrim 上前景。
11. **B7** R4 的 `AppColors(ColorScheme)` 不可实现（三个自有角色 ColorScheme 无字段）—— 改为 `AppColors(BrandPalette)`。
12. **B8** §2 的 R2 角色表既无 `secondary`/`tertiary` 也无 `onSurfaceStrong`，与 §5 不一致 —— 补齐（R2）。
13. **B9** §5 表格自身相加与 §1.2 对不上（`offWhite` 9 vs 10），且 `accent1` 四行只写「部分」—— 已填实数（§5）。
14. **B10** §1.4 写「9 处」实为 10 处，`video_player_placeholder` 行号 191 应为 195 —— 已修正（§1.4）。

**门禁与分阶段**

15. **C1** §1.4 的硬编码色不在 §5 映射表内、被给了错误去向，且**没有任何一期负责迁移** —— 去向逐条改正，归属 P4（§1.4、§6）。
16. **C2** §6 把 R2.1 完整列在 P2，与其 4.5:1 要求和 P3 的提值时点冲突 —— 标为 P3 条件成立（R2.1 脚注、§6）。
17. **C3** §6 的设计原则建立在 golden 覆盖率上，但规范从未声明覆盖范围 —— 新增覆盖声明：两张图、仅亮色，并列出不在覆盖内的区域（G2）。
18. **C4** G1/G2 上线顺序未写 —— 明确 G2 须先于 G1 满额通过（G2）。

---

## 9. 待办（不属于本规范条款）

- `home_screen.dart:120,168,171,173,174` —— `activeSource.id == 'bilibili'` 分支决定 tooltip、标题、提示文案，并预填具体 UP主 ID `defaultId: '188339'`。违反 R8 第 3 条，代码另开 PR 修。
- `service_source_providers.dart:32-34` —— `_ => null` 对未知服务源静默失败。
- 硬编码服务名 UI 文案 3 处：`video_screen.dart:150/153`、`video_player_placeholder.dart:26`、`video_info_view.dart:535`，均未本地化。
- `home_state.dart:32` `sourceId = 'bilibili'` 硬编码默认态。
- `app_aggregate_search_repository.dart:4/11` 注释掉的死代码。
- `packages/bilibili/lib/src/constonts/` 目录与类名拼写错误（`Constonts` → `Constants`），类为孤儿。
