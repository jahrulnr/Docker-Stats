import 'package:logging/logging.dart';

class AppLogger {
  static final Logger _logger = Logger('DockerStats');

  static void init() {
    Logger.root.level = Level.INFO;
    Logger.root.onRecord.listen((record) {
      // In production, you might want to send logs to a service
      // For now, we'll just print to console in debug mode
      // ignore: avoid_print
      print('${record.level.name}: ${record.time}: ${record.message}');
    });
  }

  static Logger get logger => _logger;

  static void info(String message) {
    _logger.info(message);
  }

  static void warning(String message) {
    _logger.warning(message);
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.severe(message, error, stackTrace);
  }

  static void debug(String message) {
    _logger.fine(message);
  }
}