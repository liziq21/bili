import 'package:logger/logger.dart';
import 'package:flutter_debug_overlay/flutter_debug_overlay.dart';
    
final appLogger = Logger(
  printer: HybridPrinter(
    PrettyPrinter(
      methodCount: 0,    
      errorMethodCount: 5,    
      lineLength: 50,
      colors: true,    
      printEmojis: true,    
      printTime: true,    
    ),
    debugOverlay: LogConsolePrinter(),    
  ),
  level: Level.verbose,
);