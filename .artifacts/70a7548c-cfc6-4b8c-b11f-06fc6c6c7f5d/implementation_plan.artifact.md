# Implementation Plan - Expense Management Enhancements

This plan addresses several requests related to expense management, including editing, allocation limits, date selection, and a new entry point for company operating expenses.

## User Review Required

> [!IMPORTANT]
> The "Company Operating Expenses" link will be added to the `ProjectListScreen` under the summary card. Please confirm if this is the preferred location.

## Proposed Changes

### [Component] UI Screens - Project Economics

#### [MODIFY] [project_economics_screen.dart](file:///C:/Users/User/AndroidStudioProjects/MTC2026/lib/ui/screens/project_economics_screen.dart)
- Add `onLongPress` to `_ExpenseItemCardPremium` and `_IncomeItemCardPremium` calling their respective edit dialogs.
- Add a date picker button to `_AddEditExpenseDialog` to allow setting the expense date.
- Add a date picker button to `_AddEditIncomeDialog` to allow setting the income/invoice date.

### [Component] UI Screens - Company Expenses

#### [MODIFY] [company_expenses_screen.dart](file:///C:/Users/User/AndroidStudioProjects/MTC2026/lib/ui/screens/company_expenses_screen.dart)
- Update `CompanyExpensesScreen` to accept an optional `initialTabIndex`.
- Update `_showAddExpenseDialog`:
    - Add a date picker button.
    - Implement validation to ensure the sum of project allocations does not exceed the total expense amount.
    - Add a "Remaining amount" indicator when allocating.
- Update `_GeneralExpensesList`:
    - Add `onLongPress` to the `ListTile` to open an "Edit" dialog (will refactor `_showAddExpenseDialog` to support editing).

### [Component] UI Screens - Project List

#### [MODIFY] [project_list_screen.dart](file:///C:/Users/User/AndroidStudioProjects/MTC2026/lib/ui/screens/project_list_screen.dart)
- Add a new "Λειτουργικά Έξοδα Εταιρείας" card under the "ΣΥΝΟΛΙΚΗ ΕΙΚΟΝΑ" card that navigates to `CompanyExpensesScreen` (Operations tab).

## Verification Plan

### Manual Verification
- **Edit Expenses**: Long press on an expense in both Project Economics and Company Expenses screens to verify the edit dialog opens with correct data.
- **Date Selection**: Open add/edit dialogs for expenses and incomes, change the date, and verify it persists after saving.
- **Allocation Limit**: In the Company Expenses "Add" dialog, try to allocate more than the total amount to projects and verify the error message/prevention logic.
- **New Page Access**: Go to "ΔΙΑΧΕΙΡΙΣΗ ΕΡΓΩΝ" (Project List) and verify the new button/card for company operating expenses works and opens the correct tab.
