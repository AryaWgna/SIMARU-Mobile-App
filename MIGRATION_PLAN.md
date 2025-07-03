# Logger Migration Plan

This document outlines the plan for migrating from `print` statements and `dart:developer` logs to the new `LoggerUtil` class throughout the Assets Tracker Mobile application.

## Migration Steps

### Phase 1: Core Files (Completed)
- [x] Create `LoggerUtil` class
- [x] Update `main.dart`
- [x] Update `login.dart`
- [x] Update `recent_activity_controller.dart`
- [x] Update `history_screen.dart`
- [x] Update `today_activities_widget.dart`

### Phase 2: Controllers
- [x] Update `auth_controller.dart`
- [x] Update `asset_details_controller.dart`
- [x] Update `asset_document_controller.dart`
- [x] Update `asset_history_controller.dart`
- [x] Update `asset_mutation_controller.dart`
- [x] Update `asset_complaint_controller.dart`
- [x] Update `complaint_controller.dart`
- [x] Update `dashboard_controller.dart`
- [x] Update `notification_controller.dart`
- [x] Update `profile_controller.dart`
- [x] Update `qr_scanner_controller.dart`
- [x] Update `scan_result_controller.dart`
- [x] Update `stockopname_controller.dart`
- [x] Update `asset_checkin_controller.dart`
- [x] Update `asset_checkout_controller.dart`
- [x] Update `asset_lost_controller.dart`
- [x] Update `net_asset_value_controller.dart`
- [x] Update `total_asset_controller.dart`
- [x] Update `asset_under_repair_controller.dart`
- [x] Update `notification_badge_controller.dart`
- [ ] Update remaining controller files

### Phase 3: Services
- [x] Update `firebase_messaging_impl.dart`
- [x] Update `firebase_messaging_service.dart`
- [x] Update `socket_service.dart`
- [x] Update `notification_service.dart`
- [x] Update `auth_controller.dart` (in services folder)
- [ ] Update remaining service files

### Phase 4: Views
- [ ] Update dashboard views
  - [x] Update `dashboard.dart`
  - [x] Update `home_screen.dart`
  - [ ] Update remaining dashboard views
- [ ] Update asset views
  - [x] Update `asset_document.dart`
  - [ ] Update remaining asset views
- [ ] Update profile views
  - [x] Update `profile.dart`
  - [ ] Update remaining profile views
- [x] Update notification views
  - [x] Update `notification_screen.dart`
  - [x] Update `notification_detail_screen.dart`
- [ ] Update stockopname views
  - [x] Update `stockopname_mobile_scanner.dart`
  - [x] Update `stockopname_scanner_stub.dart`
  - [ ] Update remaining stockopname views
- [ ] Update complaint views
- [ ] Update remaining view files

### Phase 5: Widgets
- [ ] Update `app_drawer.dart`
- [ ] Update `custom_app_bar.dart`
- [ ] Update remaining widget files

## Migration Guidelines

When migrating each file, follow these guidelines:

1. **Import LoggerUtil**:
   ```dart
   import '../utils/logger_util.dart';
   ```

2. **Replace print statements**:
   - Replace `print("message")` with `LoggerUtil.d("message")`
   - For error messages: `LoggerUtil.e("message", error, StackTrace.current)`

3. **Replace dart:developer logs**:
   - Replace `developer.log('message', name: 'TAG')` with `LoggerUtil.d('message')`
   - For error logs: `LoggerUtil.e('message', error, stackTrace)`

4. **Use appropriate log levels**:
   - Debug information: `LoggerUtil.d()`
   - Informational messages: `LoggerUtil.i()`
   - Warnings: `LoggerUtil.w()`
   - Errors: `LoggerUtil.e()`
   - Critical errors: `LoggerUtil.wtf()`

5. **Add context to logs**:
   - Include class name or method name in log messages
   - For API logs, use the specialized methods:
     ```dart
     LoggerUtil.logApiRequest('GET', '/api/endpoint', body: requestBody);
     LoggerUtil.logApiResponse('GET', '/api/endpoint', 200, responseBody);
     ```

## Testing

After migrating each file or group of files:

1. Run the app in debug mode to ensure logs are displayed correctly
2. Check that all log levels are working as expected
3. Verify that error logs include proper error objects and stack traces

## Completion Criteria

The migration will be considered complete when:

1. All `print` statements have been replaced with appropriate `LoggerUtil` methods
2. All `dart:developer` logs have been replaced with appropriate `LoggerUtil` methods
3. The app runs without any logging-related errors
4. Logs are properly categorized by level and provide useful information for debugging 