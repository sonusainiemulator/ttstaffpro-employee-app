# Dynamic Form Builder Skill

This skill documents how to use the app's dynamic form system for surveys, data collection, and requests.

## 🏗️ System Overview

The `FormBuilderStore` (`lib/store/form_builder_store.dart`) handles the generation of fields dynamically from backend JSON.

### JSON Field Structure:
```json
{
  "id": 1,
  "label": "Employee Feedback",
  "type": "text", // text, dropdown, date, file
  "required": true,
  "options": [] // For dropdowns
}
```

## 📄 Implementation Workflow

### 1. Fetch Form Config
```dart
await formBuilderStore.fetchFormConfig(formId);
```

### 2. Render the Form
The UI should loop through `formBuilderStore.formFields` and render the appropriate input widget.
```dart
Observer(
  builder: (_) => Column(
    children: formBuilderStore.fields.map((field) {
      if (field.type == 'text') return DynamicTextField(field: field);
      if (field.type == 'dropdown') return DynamicDropdown(field: field);
      return Container();
    }).toList(),
  ),
)
```

### 3. Submission
Collect values from the store and submit via `ApiService.submitForm`.

## 🛠️ Best Practices
1. **Validation**: Use the `required` flag to trigger internal validation logic before allowing submission.
2. **Persistence**: If a form is partially filled, cache the values in Hive using the `hive_persistence` skill.
3. **File Handling**: For `type: "file"`, use the `image_picker` or `file_picker` integration already present in the app.

## 🚀 Pro-Tip: "Smart Conditions"
If a form needs conditional logic (e.g., "Show field B if option A is selected"), implement this logic inside the `FormBuilderStore` as a `@computed` observable to keep the UI clean.
