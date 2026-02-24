# MobX State Management Skill

This skill provides the standards and patterns for managing state in the Open Core HR app using MobX.

## 🧱 Store Structure

Every major feature should have its own store in `lib/store/`. A standard store consists of two files:
1. `feature_store.dart`: The logic and state.
2. `feature_store.g.dart`: Generated code (DO NOT EDIT).

### Template for a New Store:
```dart
import 'package:mobx/mobx.dart';

part 'feature_store.g.dart';

class FeatureStore = _FeatureStore with _$FeatureStore;

abstract class _FeatureStore with Store {
  @observable
  bool isLoading = false;

  @observable
  ObservableList<DataModel> items = ObservableList<DataModel>();

  @action
  Future<void> fetchData() async {
    isLoading = true;
    try {
      // API call logic here
    } finally {
      isLoading = false;
    }
  }
}
```

## 🚀 Key Concepts

### 1. Observables (@observable)
Values that the UI "listens" to. When an observable changes, any `Observer` widget using it will rebuild. Use `ObservableList` and `ObservableMap` for collections.

### 2. Actions (@action)
Methods that modify observables. **Crucial**: All state mutations MUST happen inside an action. This ensures that the state changes are tracked correctly.

### 3. Computeds (@computed)
Derived state. Use these for filtering lists, calculating totals, or formatting data for the UI. They are cached and only re-calculate if the underlying observables change.
```dart
@computed
int get totalItems => items.length;
```

## ⚛️ UI Integration

Always wrap the widgets that depend on store data with an `Observer`.

```dart
Observer(
  builder: (_) {
    if (store.isLoading) return CircularProgressIndicator();
    return ListView.builder(
      itemCount: store.items.length,
      itemBuilder: (_, index) => Text(store.items[index].name),
    );
  },
)
```

## 🛠️ Build Runner
After adding or modifying store properties/actions, run the build runner to generate the `.g.dart` files:
`dart run build_runner build --delete-conflicting-outputs`

## 🚯 Best Practices
- **Granular Updates**: Only wrap the smallest necessary widget with `Observer` to optimize performance.
- **Global vs Local**: Global stores (like `AppStore`) are initialized in `main.dart`. Local stores should be managed within the screen's `State` or provided via `Provider`.
- **Async Actions**: Use `Future` and `try-finally` blocks to manage loading states reliably.
