# bili 设计系统规范

本文只写**规则**：任何时间点读它，条文都应成立。取值依据、实施历史、待办清单不在本文，也不在仓库内 —— 见 git 历史与建立各条规则的提交。

`R*` / `G*` 编号被代码注释引用，**只增不改** —— 条文作废时保留编号并标注作废，替代条文另起新号。本文不出现 commit sha、文件行号、调用点计数与版本修订记录。

## 1. 决策

| # | 决策 |
|---|---|
| D1 | `toThemeData()` **接进生产**，设计系统拥有 ColorScheme。DynamicColor 保留并作为**首选**，当前品牌色作不支持动态色设备的 fallback |
| D2 | 色 token 一律**角色命名**，外观名（black / white / offWhite / greyMedium / accent1 等）禁止出现 |
| D3 | 硬编码色用 **custom_lint** 规则治（`analysis_options.yaml` 的 `plugins:` 块保留） |
| D4 | 字体六族**不配置**，文字退回系统字体 |
| D5 | 亮色色板**重新取值**，接受亮色观感变化；放弃「亮色取值逐字节不变」这一性质 |
| D6 | DynamicColor 开启时自研 widget 跟随壁纸色相；**同屏出现两种以上不受壁纸色相约束的强调色相属缺陷** |
| D7 | **服务源无关性** —— 界面与设计系统不得按服务源分支，服务身份色不进设计系统 |

## 2. 条款

### R1 —— 色值单一来源，白名单同时约束路径与内容

`app/lib/` 内允许出现颜色字面量的文件**只有一个**：`app/lib/design/brand_palette.dart`。其余一切颜色从 `ColorScheme` 派生。G1 门禁强制。

白名单按**路径 + 内容**双重授权。只按路径授权等于开了「不限内容」的后门 —— 任何外部实体都能来这里加条目。文件内只允许：色值常量、`ColorScheme` 构造、`isDark` 分支取值。

增删色值只能改该文件。产生「这里需要一个新颜色」的需求时，先判定它是否属于**界面角色**（R2）；不属于则不得进该文件。

### R2 —— token 按角色命名

角色与 `app/lib/design/app_colors.dart` 的访问器一一对应：

| 类别 | 角色 |
|---|---|
| 表面 | `surface` / `surfaceContainerHighest` |
| 前景 | `onSurfaceStrong`（主）/ `onSurface`（正文）/ `onSurfaceVariant`（弱化） |
| 恒定承载面 | `scrim`（恒深）/ `onScrim`（恒浅） |
| 强调 | `accentFill` / `accentText` / `onAccentFill` |
| 次 / 三级强调 | `secondary` / `tertiary` |
| 图形 | `outline` |

**前景必须分三档。** `onSurfaceStrong` / `onSurface` / `onSurfaceVariant` 在亮暗两套下取值互不相同，合并任意两档即改变像素。这三档不是可选的语义细分，是像素事实。

**R2.1** 单一强调色相按**用途**拆档，门槛取 `contrast.dart` 的 `aaText` / `aaNonText`，不在本文复述数值：

| 用途 | 门槛 | 角色 |
|---|---|---|
| 文本（`Text`、`TabBar.labelColor`、按钮文字） | `aaText` | `accentText` |
| 非文本指示器与图形对象（`Slider.activeTrackColor` / `thumbColor`、`CircularProgressIndicator`、Tab 指示条本身） | `aaNonText` | `accentFill` |

`TabBar.labelColor` 是文本，归 `aaText` 一档；`aaNonText` 只留给非文本指示器（WCAG 2.1 Understanding §1.4.3：普通字号文本一律 `aaText`）。

`accentFill` 与 `accentText` 允许同值起步，但 R2.1 是**终态要求**：G2 断言未达标即缺陷，不得以「当前同值」为由长期豁免。

**R2.2** 语义不得混用：`scrim` / `onScrim` 与 `onSurface` 系在暗色下方向相反，禁止共用常量，禁止前景 token 当背景用。

### R3 —— 亮度单源

`isDark` 只有一个来源：`Theme.of(context).brightness`，由 `AppScaffold` 注入 `AppStyle`。**禁止任何位置硬编码 `isDark = false`。**

### R4 —— ColorScheme 是唯一真值

Material 组件与 `$styles.colors.*` 读**同一个** `ColorScheme`，禁止两套独立色板并存 —— 两套并存时 Material 组件会算出与自研 widget 不同的对比度。

`AppColors` 构造后不持有任何颜色字面量。`scrim` / `onScrim` / `onSurfaceStrong` 三个角色在 `ColorScheme` 里没有对应字段，由色板携带，且**只在 `brand_palette.dart` 取值**；其余角色一律从 `palette.scheme` 派生。

### R5 —— DynamicColor 优先，品牌色 fallback

```
DynamicColorBuilder 拿到壁纸色  →  ThemeData.copyWith(colorScheme: dynamic)
拿不到（桌面 / 旧设备）         →  brand_palette 构造的 fallback ColorScheme
```

### R6 —— 字体

不配置任何字体族，文字走 Material `textTheme`（由 `Material` 内部的 `AnimatedDefaultTextStyle` 送达；不经 `AppScaffold` 的 `DefaultTextStyle` —— 那层在 `Material` 之上，够不到普通 `Text`）。`$styles.text` 保留，只管字号 / 行高 / 字重。

**`kern` 不得删除。** `fontFeatures: [FontFeature.enable('kern')]` 改变字形间距，属渲染配置而非死配置（实测依据见 decisions）。有 kern 与无 kern 的两个基底样式并存，**不统一** —— 统一任一方向都会改变真实设备渲染结果。

### R7 —— 死代码不保留

零调用点的 token getter 一律不暴露；零调用点的定义应当删除，不以「以备后用」为由留存。

### R8 —— 服务源无关性

**界面与设计系统不得按服务源分支。**

判定标准：一个构造的名字里如果出现服务方（bilibili / youtube / peertube / piped），它就属于服务源，而不是界面角色。

1. 设计系统内不得有按服务源命名的常量、类或文件。
2. 同一屏内不得出现两种以上不受壁纸色相约束的强调色相（与 D6 同源）。
3. 界面文案、默认输入、交互行为不得由服务源身份决定。

**服务身份的正确承载方式**，若产品确需展示：

- 品牌色属**数据层**（服务描述符）的属性，随内容一起进入，**不进设计系统**；
- 渲染成**标识图形**（logo / 图标），不是彩色文字 —— 一个服务的品牌色不是为压在别人家表面上当正文设计的；
- 设计系统只定义**使用规则**（对比度下限、只许在徽章上、永不作正文色），**永不按服务开条目**；
- 来源身份优先由**文字本身**承载。

**服务清单的正确落点**是数据 / DI 层：应用配置决定支持哪些服务，这是配置，不是设计系统。按服务名 switch 构造实例同属该层，位置正确。

## 3. 目录结构

```
app/lib/design/
  brand_palette.dart     # R1 唯一白名单：品牌 fallback 色板 + ColorScheme 构造 + 自有角色取值
  app_colors.dart        # 从 ColorScheme 派生的角色访问器，零硬编码色值
  app_theme.dart         # 构造 ThemeData
  app_style.dart         # scale / corners / insets / times / text
  contrast.dart          # WCAG 相对亮度、对比度与门槛常量（供测试与调色用）
  design.dart            # 唯一入口，re-export 以上全部
```

`app/lib/theme_wrapper.dart` 与 `app/lib/feature/theme/` 并入本目录。`app/lib/styles/` 不保留。

## 4. 门禁

### G1 —— custom_lint：禁止硬编码色

- 规则 `no_hardcoded_color` 报**所有**直接构造颜色的形式：`Color(0x…)`、`Color.fromARGB`、`Color.fromRGBO`、`Color.from`、以及任何 `Colors.xxx` 常量引用。`Colors.transparent` 豁免（无语义，不构成硬编码色）。
- **allow-list 与 R1 逐字一致：只有 `app/lib/design/brand_palette.dart`。** 不豁免生成文件 —— 豁免生成文件等于留下一条与 R1 无关的旁路。
- **上线前置**：仓库现存硬编码色必须先迁完，否则门禁一次报出全部历史遗留。迁移与门禁在同一 PR 内完成。
- 规则必须覆盖**完整的构造器集合**；漏掉 `Color.fromRGBO` 之类即形同虚设。
- 自写 `custom_lint` 规则而非采用第三方 rule set：语义需精确到「白名单单文件且内容受限」，通用 rule set 无法表达。

### G2 —— 对比度测试

`app/test/design/contrast_test.dart` 枚举**受支持的**前景/背景组合（不做笛卡尔积），在亮 / 暗两种亮度下各断言一次，门槛取 `contrast.dart` 的 `aaText` / `aaNonText`。

**G2 必须先于 G1 满额通过。** G1 拦住的是「新增硬编码色」，G2 拦住的是「改了色板但没算对比度」。反序上线会出现门禁全绿而界面仍不可访问。

### 验证范围声明

任何「像素未变」「零回归」结论的效力，**仅及于 golden 实际覆盖的 widget 与亮度**。未覆盖区域（含全部暗色渲染、以文本色作背景的徽章类元素）必须以实跑加 G2 断言证明，不得由「golden 没动」推断。现有 golden 的具体张数与覆盖范围属快照，记在 decisions。
