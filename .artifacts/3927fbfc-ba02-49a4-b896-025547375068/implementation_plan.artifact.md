# Fix Pixel Overflow in Quote Categories Screen

The user reported a "pixel notification" (likely a RenderFlex overflow warning) on mobile devices in the "Offer" (Προσφορά) section, specifically within the categories grid where the "ACTIVE" (ΕΝΕΡΓΟ) badge is displayed.

## User Review Required

> [!IMPORTANT]
> The fix involves adjusting the aspect ratio of the category cards on mobile to ensure they have enough vertical space for all content, including the "ACTIVE" badge. This will make the cards slightly taller on mobile screens.

## Proposed Changes

### UI Components

#### [MODIFY] [quote_categories_screen.dart](file:///C:/Users/User/AndroidStudioProjects/MTC2026/lib/ui/screens/quote_categories_screen.dart)
- Adjust `childAspectRatio` in `GridView.builder` for mobile devices.
- Wrap the `Column` in `_CategoryCard` with a `FittedBox` or use `MainAxisSize.min` combined with a more flexible layout to prevent overflows on very small screens.
- Specifically, I will change the mobile `childAspectRatio` from `1.4` to `1.2` (or `1.1` like in other screens) to provide more vertical space.

## Verification Plan

### Manual Verification
- Since I cannot run the app on a device, I will verify the code changes by:
    - Calculating the required space for the card content.
    - Ensuring the new aspect ratio provides sufficient height for the fixed content (Icon, Spacing, Label, and Badge).
    - Checking for consistency with other hub screens in the app that already use a smaller aspect ratio on mobile.
