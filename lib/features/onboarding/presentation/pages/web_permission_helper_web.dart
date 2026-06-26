/// On Web, the browser handles permission dialogs natively when
/// camera/geolocation APIs are actually invoked. We grant by default here
/// so the onboarding flow proceeds, and the real browser prompt appears
/// the first time the user taps "Denunciar" or the map requests GPS.
Future<List<bool>> requestWebPermissions() async {
  // Browser will show its own permission popup when the APIs are used.
  return [true, true]; // [camera, location]
}
