# Import/Export Feature for OTPAnd

## Overview

The import/export feature allows users to backup and restore all their OTPAnd data including:
- Application settings and preferences
- Travel profiles
- Favorite locations
- Search history

## Features

### Export Data
- Exports all user data to a JSON file
- Includes timestamp and version information
- Uses file picker for saving to desired location
- Generates human-readable JSON format

### Import Data
- Imports data from previously exported JSON files
- Shows confirmation dialog with import details
- Validates export version compatibility
- Replaces all current data with imported data

## How to Use

### Exporting Data
1. Open Settings page
2. Scroll to "Data Management" section
3. Tap "Export Settings & Data"
4. Choose save location using file picker
5. File will be saved with timestamp: `otpand_export_[timestamp].json`

### Importing Data
1. Open Settings page
2. Scroll to "Data Management" section
3. Tap "Import Settings & Data"
4. Select the JSON export file
5. Review the import details in confirmation dialog
6. Confirm to proceed with import

## Data Structure

The export file contains:
```json
{
  "version": "1.0.0",
  "exportedAt": "2024-01-01T12:00:00.000Z",
  "settings": { ... },
  "profiles": [ ... ],
  "favourites": [ ... ],
  "searchHistory": [ ... ]
}
```

## Important Notes

- **Import replaces all current data** - Make sure to export current data before importing
- **Version compatibility** - Only files exported with the same version can be imported
- **Temporary profile edits** - Any temporary profile modifications are not included in exports
- **File format** - Only JSON files with `.json` extension are supported

## Dependencies

- `file_picker: ^8.0.0+1` - For file selection and saving
- Standard Flutter dependencies for database and shared preferences

## Implementation Files

- `lib/utils/import_export_service.dart` - Core import/export logic
- `lib/pages/settings.dart` - UI integration
- `pubspec.yaml` - Added file_picker dependency

## Error Handling

The feature includes comprehensive error handling for:
- File access errors
- JSON parsing errors
- Version compatibility issues
- Database operation failures
- Permission issues

## Security Considerations

- Export files contain all user data in plain text JSON
- Users should treat export files as sensitive data
- No encryption is applied to export files
- Users are responsible for secure storage of export files

