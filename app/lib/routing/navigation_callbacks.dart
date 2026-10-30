// Copyright 2024 The bili Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// 导航回调类型定义
///
/// 设计原则：
/// - 页面只声明「发生了什么」，不决定「怎么跳转」
/// - 回调可为 null 表示无实现（no-op）
/// - 路由层提供默认实现，source 隐式从 ServiceSourceProviders 读取

/// 视频导航回调
typedef VideoNavCallback = void Function(String videoId);

/// 直播导航回调
typedef LiveNavCallback = void Function(String roomId);

/// 空间导航回调
typedef SpaceNavCallback = void Function(String mid);

/// 搜索导航回调
typedef SearchNavCallback = void Function(String query);

/// 创作者导航回调（媒体库专用，需显式 sourceId）
typedef CreatorNavCallback = void Function(String sourceId, String creatorId);

/// 视频导航回调（媒体库专用，需显式 sourceId）
typedef MediaLibraryVideoNavCallback = void Function(
  String sourceId,
  String videoId,
);
