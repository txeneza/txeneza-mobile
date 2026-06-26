Future<List<bool>> requestWebPermissions() async {
  // Mobile platform fallback: default to granted (native permission_handler will be used instead)
  return [true, true];
}
