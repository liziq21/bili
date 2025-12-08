import 'package:logger/logger.dart';
import 'package:flutter_debug_overlay/flutter_debug_overlay.dart';    
    
final LogHistory debugOverlayLogHistory = LogHistory();

final appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,    
    errorMethodCount: 5,    
    lineLength: 80,
    colors: true,    
    printEmojis: true,
    printTime: true,
  ),
  level: Level.verbose,
  output: DebugOverlayLogOutput(debugOverlayLogHistory),
);