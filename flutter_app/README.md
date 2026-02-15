# Cooking Swipe

A Tinder-style recipe discovery app built with Flutter. Swipe through your personal recipe collection, build a weekly menu, and generate a shopping list — all offline.

## Quick Start

```bash
cd flutter_app
flutter pub get
flutter run
```

**Prerequisites:** Flutter SDK 3.0+, Android Studio or VS Code, Android/iOS emulator or physical device.

The app comes pre-loaded with 23 recipes on first launch. No setup needed.

## Features

### Swipe to Choose
- Swipe right to pick a recipe, left to skip
- Red/green edge indicators show swipe direction as you drag
- Tap the progress counter ("2/5") to preview your chosen recipes
- Undo button to go back, filter by calories or cooking time

### Edit Your Selection
- After reaching your target, choose "Edit Selection" to swap recipes
- Remove recipes from the shopping list screen and go back to pick replacements
- Preview chosen recipes at any time during swiping

### Shopping List
- Ingredients auto-aggregated from all selected recipes
- Add, edit, check off, or delete items
- Copy to clipboard or share via any app (Telegram, WhatsApp, etc.)

### Session History
- Past sessions saved with recipes and shopping lists
- Share any saved session as formatted text
- Up to 4 sessions retained

### Settings
- Adjustable target dish count (1-20)
- Import additional recipes via JSON
- Manual recipe entry
- View/manage recipe database

## File Structure

```
flutter_app/
├── lib/
│   ├── main.dart                          # Entry point
│   ├── models/
│   │   ├── recipe.dart                    # Recipe data model
│   │   └── session.dart                   # Session data model
│   ├── services/
│   │   ├── app_state.dart                 # Global state (Provider)
│   │   ├── database_service.dart          # SQLite persistence
│   │   └── import_service.dart            # JSON import/export
│   ├── screens/
│   │   ├── swipe_screen.dart              # Main swiping interface
│   │   ├── shopping_list_screen.dart      # Shopping list + sharing
│   │   ├── settings_screen.dart           # Settings + import
│   │   └── sessions_history_screen.dart   # Past sessions + sharing
│   ├── widgets/
│   │   ├── recipe_card.dart               # Swipeable card with indicators
│   │   ├── flip_recipe_card.dart          # Flippable card (history view)
│   │   ├── filter_modal.dart              # Filter dialog
│   │   └── ingredient_list_item.dart      # Shopping list item
│   ├── theme/
│   │   └── theme.dart                     # Dark theme + pastel accents
│   └── utils/
│       ├── constants.dart                 # App constants
│       └── extensions.dart                # String/list helpers
├── assets/
│   ├── app_icon.png                       # App icon source (1024x1024)
│   ├── dishes_json.json                   # Bundled recipe data
│   ├── images/placeholder.png             # Fallback image
│   └── recipe_images/                     # Recipe photos (24 images)
└── pubspec.yaml
```

## Adding Recipes

### Bundled recipes
The app auto-loads `assets/dishes_json.json` on first launch when the database is empty.

### Import more recipes
Go to Settings > Import JSON and paste a JSON string following this format:

```json
{
  "recipes": [
    {
      "id": "tomato_soup",
      "dish_name": "Tomato Soup",
      "cooking_time": { "prep_time": 15, "cook_time": 30, "total_time": 45 },
      "nutrition": { "kcal": 400, "protein_g": 8, "highlights": "Rich in Vitamin A" },
      "ingredients": "1. Tomatoes 1 kg\n2. Capsicum 1\n3. Onion 2",
      "instructions": "1. Dice onion\n2. Heat oil\n3. Add tomatoes",
      "image_description": "Bowl of tomato soup",
      "image_filename": "tomato_soup.jpg"
    }
  ]
}
```

Place matching images in `assets/recipe_images/` and add them to the assets section in `pubspec.yaml`.

## App Icon

The app icon is generated from `assets/app_icon.png` using `flutter_launcher_icons`. To update:

1. Replace `assets/app_icon.png` with a 1024x1024 PNG
2. Run: `dart run flutter_launcher_icons`

## Building

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle

# iOS
flutter build ios --release
```

## Tech Stack

- **Framework:** Flutter 3.0+ with Material 3
- **State:** Provider (ChangeNotifier)
- **Database:** SQLite via sqflite
- **Sharing:** share_plus
- **Icons:** flutter_launcher_icons
- **UI:** Custom dark theme with pastel accents
