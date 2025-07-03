# Logger Utility Documentation

This document explains how to use the `LoggerUtil` class for logging in the Assets Tracker Mobile application.

## Overview

The `LoggerUtil` class provides a standardized way to log messages throughout the application. It uses the [logger](https://pub.dev/packages/logger) package to provide pretty-printed, structured logs with different severity levels.

## How to Use

### Import the LoggerUtil

```dart
import 'package:flutter_assets_monitoring/utils/logger_util.dart';
```

### Log Levels

The `LoggerUtil` class provides several methods for different logging levels:

1. **Verbose** - For detailed information (lowest level)
   ```dart
   LoggerUtil.v('This is a verbose message');
   ```

2. **Debug** - For debugging information
   ```dart
   LoggerUtil.d('This is a debug message');
   ```

3. **Info** - For informational messages
   ```dart
   LoggerUtil.i('This is an info message');
   ```

4. **Warning** - For warnings
   ```dart
   LoggerUtil.w('This is a warning message');
   ```

5. **Error** - For errors
   ```dart
   LoggerUtil.e('This is an error message', error, stackTrace);
   ```

6. **WTF (What a Terrible Failure)** - For critical errors
   ```dart
   LoggerUtil.wtf('This is a critical error message', error, stackTrace);
   ```

### API Logging

The `LoggerUtil` class also provides methods for logging API requests and responses:

```dart
// Log API request
LoggerUtil.logApiRequest('GET', '/api/endpoint', body: requestBody);

// Log API response
LoggerUtil.logApiResponse('GET', '/api/endpoint', 200, responseBody);
```

## Best Practices

1. **Use appropriate log levels** - Use the appropriate log level for different types of messages. For example, use `LoggerUtil.d()` for debugging information and `LoggerUtil.e()` for errors.

2. **Include context** - When logging, include enough context to understand what's happening. For example, include the class name or method name where the log is coming from.

3. **Log errors with stack traces** - When logging errors, always include the error object and stack trace to help with debugging.

4. **Be concise** - Keep log messages concise and to the point.

## Example

```dart
// In a method
Future<void> fetchData() async {
  try {
    LoggerUtil.d('Fetching data from API');
    final response = await apiClient.get('/api/data');
    LoggerUtil.i('Data fetched successfully: ${response.length} items');
    return response;
  } catch (e, stackTrace) {
    LoggerUtil.e('Error fetching data', e, stackTrace);
    rethrow;
  }
}
```

## Configuration

The `LoggerUtil` class is configured to use different log levels in debug and release modes:

- In debug mode, all log levels are enabled.
- In release mode, only warning and above log levels are enabled.

This configuration can be modified in the `LoggerUtil` class in `lib/utils/logger_util.dart`. 