import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:model/model.dart';

/// 无参数命令的操作函数类型
typedef CommandAction0<T> = Future<Result<T>> Function();

/// 接受一个参数 [A] 的命令操作函数类型
typedef CommandAction1<T, A> = Future<Result<T>> Function(A argument);

/// 用于 ViewModel 交互的命令基类 (Command Design Pattern)
///
/// 封装异步操作，暴露 [running] 执行状态及 [error] / [completed] 状态，
/// 并且在执行期间禁止重复启动，防止UI按钮多击或并发重复请求。
///
/// - 无参数的动作请使用 [Command0]
/// - 单个参数的动作请使用 [Command1]
///
/// 动作必须返回 [Result] 对象。
abstract class Command<T>() extends ChangeNotifier {
  bool _running = false;

  /// 当命令正在异步执行时返回 true
  bool get running => _running;

  Result<T>? _result;

  /// 当命令上一次执行返回 [Error] 时返回 true
  bool get error => _result is Error;

  /// 当命令上一次执行返回 [Ok] 成功时返回 true
  bool get completed => _result is Ok;

  /// 获取上一次执行的结果 [Result]
  Result? get result => _result;

  /// 清除上一次执行的结果并通知监听器
  void clearResult() {
    _result = null;
    notifyListeners();
  }

  /// 内部逻辑执行方法，防止并发重复调用
  Future<void> _execute(CommandAction0<T> action) async {
    // 确保动作无法并发重复发起
    if (_running) return;

    // 通知监听者更新状态（例如按钮展示加载态）
    _running = true;
    _result = null;
    notifyListeners();

    try {
      _result = await action();
    } finally {
      _running = false;
      notifyListeners();
    }
  }
}

/// 无参数的命令封装，接收 [CommandAction0]
class Command0<T>(final CommandAction0<T> _action) extends Command<T> {
  /// 执行动作
  Future<void> execute() async {
    await _execute(_action);
  }
}

/// 单参数的命令封装，接收 [CommandAction1]
class Command1<T, A>(final CommandAction1<T, A> _action) extends Command<T> {
  /// 传入参数 [argument] 并执行动作
  Future<void> execute(A argument) async {
    await _execute(() => _action(argument));
  }
}
