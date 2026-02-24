# Asset & Inventory Module Skill

This skill documents how the app tracks company property assigned to employees.

## 💻 Asset Tracking

### 1. Store
- **Store**: `AssetStore`.
- **Logic**: Handles synchronization between the local Hive cache and the backend database.

### 2. Asset Lifecycle
- **Assigned Assets**: Fetched via `AssetStore.fetchMyAssets()`.
- **Details**: Includes Manufacturer, Serial Number, Image, and "Assigned At" date.
- **Documents**: Assets can have associated PDFs (Manuals, Insurance). Fetch via `AssetDocumentModel`.

### 3. History
- Tracks the history of assignments and returns (`AssetAssignmentModel`).
- Uses `DateParser.parseDate` to calculate the duration of possession.

## 📦 Local Sync Implementation
1. On app start, `AssetStore` clears the old Hive box and fetches fresh data.
2. If offline, the UI reads exclusively from the Hive box.
3. Every asset image is cached using `cached_network_image`.

## 🚀 Pro-Tip: "QR for Assets"
If implementing a check-in feature for assets using QR codes, refer to the `qr_scanner_screen.dart` to reuse the `MobileScanner` controller.
