# Hive Persistence Skill

This skill documents the local database management using Hive in the Open Core HR app.

## 📦 Setting Up a New Model

To persist a model, it must be annotated for `hive_generator`.

### 1. Annotate the Class
```dart
import 'package:hive/hive.dart';

part 'my_model.g.dart';

@HiveType(typeId: 99) // Ensure typeId is UNIQUE
class MyModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
}
```

### 2. Register and Open
In `lib/main.dart`, within the `main()` function:
```dart
// Register
Hive.registerAdapter(MyModelAdapter());

// Open (usually inside a store or main if global)
await Hive.openBox<MyModel>('myModelBox');
```

## 🔐 TypeID Management
**CRITICAL**: Every persisted class must have a unique `typeId`. 
Check `lib/main.dart` for the current registry.
- 0-4: Base Models
- 5-13: Asset Management
- ... (Check the file for latest)

## 🔄 CRUD Operations

### Save / Update
```dart
var box = Hive.box<MyModel>('myModelBox');
box.put('key', myInstance); // Or box.add(myInstance) for auto-increment keys
```

### Read
```dart
var data = box.get('key');
List<MyModel> list = box.values.toList();
```

### Delete
```dart
box.delete('key');
box.clear(); // Wipe entire box
```

## 🌐 Offline Synchronization
The app uses Hive to store data when the network is unavailable.
1. Save locally to a "pending" box.
2. Monitor network status.
3. When online, iterate through the pending box and hit the API.
4. On success, delete from Hive.

## 🚯 Best Practices
- **Lazy Boxes**: Use `Hive.openLazyBox` for very large datasets to save memory.
- **Compaction**: Hive handles compaction, but avoid excessive writes in a single frame.
- **Data Types**: Stick to primitives or classes with registered Adapters.
