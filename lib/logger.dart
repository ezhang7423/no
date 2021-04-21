import 'dart:developer' as developer;
import 'package:logger/logger.dart';
import 'package:logger_flutter/logger_flutter.dart';
// // import 'package:new_version/new_version.dart'

/// A custom printer modeled after PrettyPrinter. Gives a very slim log with
/// level, log, filename, and line number.
/// E.g. DEBUG: lorem ipsum (package:lol/lola.dart:8:2000)
/// The final words in parentheses will be prettyprinted by VS Code, and the developer
/// is able to jump directly to the package by clicking on it.
class DeveloperLogPrinter extends PrettyPrinter {
  static final withinParentheses = RegExp(r'\(([^\)]+)\)');

  List<String> regularLog(LogEvent event) {
    String stackTraceStr;
    var messageStr = stringifyMessage(event.message);

    stackTraceStr = formatStackTrace(StackTrace.current, 3);
    // extract just the line number that called log
    stackTraceStr = stackTraceStr.split('\n')[2];
    stackTraceStr = withinParentheses.stringMatch(stackTraceStr);

    return ['$messageStr $stackTraceStr'];
  }

  List<String> errorLog(LogEvent event) {
    var messageStr = '${event.error}: ${stringifyMessage(event.message)}';
    String stackTraceStr = formatStackTrace(event.stackTrace, errorMethodCount);
    List<String> res = [messageStr];
    res += stackTraceStr.split('\n');
    return res;
  }

  @override
  List<String> log(LogEvent event) {
    // if this is an error
    if (event.level == Level.error || event.level == Level.wtf) {
      return errorLog(event);
    } else {
      return regularLog(event);
    }
  }
}

class DeveloperOutput extends LogOutput {
  static final levelPrefixes = {
    Level.verbose: 'VERBOSE',
    Level.debug: 'DEBUG',
    Level.info: 'INFO',
    Level.warning: 'WARNING',
    Level.error: 'ERROR',
    Level.wtf: 'WTF',
  };

  @override
  void output(OutputEvent event) {
    developer.log(event.lines.join('\n'), name: levelPrefixes[event.level]);
    // print(event.lines.join('\n'));
    OutputEvent consoleEvent = OutputEvent(
        event.level,
        ['\n  ${prettyTime()}:'] +
            event.lines.map((val) => '  $val').toList() +
            ['\n']);

    LogConsole.add(consoleEvent);
  }

  String prettyTime() {
    String _threeDigits(int n) {
      if (n >= 100) return '$n';
      if (n >= 10) return '0$n';
      return '00$n';
    }

    String _twoDigits(int n) {
      if (n >= 10) return '$n';
      return '0$n';
    }

    var now = DateTime.now();
    var h = _twoDigits(now.hour);
    var min = _twoDigits(now.minute);
    var sec = _twoDigits(now.second);
    var ms = _threeDigits(now.millisecond);
    return '$h:$min:$sec.$ms';
  }
}

Logger getLogger() {
  return Logger(printer: DeveloperLogPrinter(), output: DeveloperOutput());
}
