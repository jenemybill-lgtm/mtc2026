# Fix Missing Database Information and Sync Logic

This plan addresses several issues where application data (Sketches, Documents, Bids, etc.) is either not saved to the database or excluded from Cloud Sync/Backup. It also fixes schema inconsistencies for new installations.

## User Review Required

> [!IMPORTANT]
> The database version will be incremented to **13**. Existing users will receive a migration, while new users will get the corrected schema immediately.

> [!WARNING]
> Sketch and Document files themselves are large and won't be fully converted to Base64 for the MongoDB sync to prevent payload limits. Instead, they will be properly **indexed** in the database to ensure the "metadata" (titles, dates, links) is preserved across devices.

## Proposed Changes

### Database Layer

#### [MODIFY] [database_helper.dart](file:///C:/Users/User/AndroidStudioProjects/MTC2026/lib/database/database_helper.dart)
- Update `_onCreate` to include missing `status` and `proposalValue` in `projects` table.
- Update `_onCreate` to include missing `status` and `followUpDate` in `clients` table.
- Add `_onUpgrade` migration to version 13 for new tables.
- [NEW TABLE] `project_sketches`: stores sketch metadata and JSON vector data.
- [NEW TABLE] `project_documents`: indexes file paths and metadata for documents.
- Update `backupDatabase` and `getAllDataForSync` to include `partner_bids`, `job_recipes`, `portfolio`, `project_sketches`, and `project_documents`.

### Models

#### [MODIFY] [project_models.dart](file:///C:/Users/User/AndroidStudioProjects/MTC2026/lib/models/project_models.dart)
- Add `ProjectSketch` model.
- Add `ProjectDocument` model.

### UI & UX Improvements

#### [MODIFY] [project_list_screen.dart](file:///C:/Users/User/AndroidStudioProjects/MTC2026/lib/ui/screens/project_list_screen.dart)
- Add a `TextField` for **Proposal Value** (Προϋπολογισμός) in the `ProjectEntryDialog`.

#### [MODIFY] [sketch_drawing_screen.dart](file:///C:/Users/User/AndroidStudioProjects/MTC2026/lib/ui/screens/sketch_drawing_screen.dart)
- Change `_saveSketch` to save both the PNG file and the vector data (JSON) to the database.

#### [MODIFY] [project_sketches_screen.dart](file:///C:/Users/User/AndroidStudioProjects/MTC2026/lib/ui/screens/project_sketches_screen.dart)
- Replace placeholder logic with real database fetching via the provider.

#### [MODIFY] [project_documents_screen.dart](file:///C:/Users/User/AndroidStudioProjects/MTC2026/lib/ui/screens/project_documents_screen.dart)
- Update file management to store file records in the `project_documents` table for sync capability.

## Verification Plan

### Automated Tests
- Build check to ensure no syntax errors in models or provider.
- SQL syntax validation for migration v13.

### Manual Verification
1. Create a new Project and verify "Proposal Value" is saved.
2. Create a Sketch and verify it appears in the "Project Sketches" list after reload.
3. Upload a Document and verify it's indexed.
4. Perform a Backup (JSON) and check if `partner_bids`, `job_recipes`, and `portfolio` entries are present in the output.
