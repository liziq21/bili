/// 设计系统唯一入口（`app/lib/design/`）。
///
/// 业务代码一律 `import 'package:app/design/design.dart';`，不要单独 import
/// 下面的子文件——那会让 `BrandPalette` 与 `AppColors` 的单一来源（R1/R4）
/// 在 import 层面就散开。
library;

export 'app_colors.dart';
export 'app_style.dart';
export 'app_theme.dart';
export 'brand_palette.dart';
export 'contrast.dart';
export 'service_brands.dart';
export 'theme_wrapper.dart';
