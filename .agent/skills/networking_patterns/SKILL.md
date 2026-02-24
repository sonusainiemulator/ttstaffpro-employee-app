# Networking & API Protocol Skill

This skill provides the standard operating procedure for extending the Open Core HR API layer.

## 📄 Extension Workflow

### 1. Define the Route
Add the new endpoint to `lib/api/api_routes.dart`.
```dart
static const String myNewFeature = 'my-feature/endpoint';
```

### 2. Implement the Service Method
Add the logic to `lib/api/api_service.dart`.
- Use `handleResponse` for error handling.
- Use `checkSuccessCase` for validation.
- Return structured data or a `List`.

```dart
Future<List<MyModel>> getMyData() async {
  var response = await handleResponse(await getRequest(APIRoutes.myNewFeature));
  if (!checkSuccessCase(response)) return [];
  
  Iterable list = response?.data;
  return list.map((m) => MyModel.fromJson(m)).toList();
}
```

## 🛠️ Request Types

- **GET**: `await getRequest(route)`
- **POST**: `await postRequest(route, payload)`
- **GET with Query**: `await getRequestWithQuery(route, queryUri)`
- **Multipart (File Upload)**: `await multipartRequest(route, filePath)`

## 🛡️ Best Practices
1. **Model Everything**: Don't use `Map<String, dynamic>` in the UI. Always map API data to a formal model in `lib/models`.
2. **Handle Nulls**: Use `response?.data` and provide default values (e.g., `[]` or `null`).
3. **Show Errors**: Set `showError: true` in `checkSuccessCase` for user-facing actions (like "Submit").
4. **Offline Awareness**: If the feature needs offline support, use the `hive_persistence` skill to cache the result.

## 🚀 Pro-Tip: Sequential De-serialization
For large lists, use `compute` (Isolates) if the parsing takes more than 16ms to avoid frame drops, though for most HR data, standard mapping is fine.
