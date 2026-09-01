void initDatabaseForPlatform() {
  // Στο Web δεν κάνουμε τίποτα, αφήνουμε τη βάση άδεια για να μην κρασάρει.
  print("Web platform detected: skipping SQL FFI initialization.");
}
