# Troubleshooting Guide

## Common Issues

### "Something went wrong" on Attendance History Screen

**Issue:**
The Attendance History screen displays a generic "Something went wrong" message.

**Cause:**
This error occurs when the application fails to fetch data from the server (e.g., API failure, network connectivity issues, or server implementation errors). Previously, the application used a default error widget which masked the actual error details.

**Solution:**
We have updated the screen to display the specific error message returned by the system. This allows for better diagnosis.

If you encounter this error:
1.  **Check Internet Connection:** Ensure your device is connected to the internet.
2.  **Server Status:** Verify that the backend server is running and accessible.
3.  **Error Details:** Read the specific error message displayed on the screen (e.g., "500 Internal Server Error", "Connection Timeout").
4.  **Logs:** Check the application logs or server logs for more details on the failure.

**Technical Implemetation:**
The `PagedChildBuilderDelegate` in `AttendanceHistoryScreen` was updated to include a `firstPageErrorIndicatorBuilder` and `newPageErrorIndicatorBuilder`. This ensures that any error caught by the `AttendanceHistoryStore` is properly displayed to the user using a custom error widget that matches the app's design system.

```dart
firstPageErrorIndicatorBuilder: (context) => _buildErrorState(isDark, _store.pagingController.error),
```
