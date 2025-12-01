class Validators {
  /// Basic email format validation.
  /// Accepts strings like demo@gmail.com, a@b.co, user.name+tag@domain.io.
  static bool isValidEmail(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;

    // No whitespace, must have exactly one '@' and one '.'
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(trimmed);
  }

  /// Password must be at least 3 characters.
  static bool isValidPassword(String value) {
    return value.trim().length >= 3;
  }

  /// DOB must match yyyy-mm-dd and be parsable to DateTime.
  static bool isValidDob(String value) {
    final trimmed = value.trim();
    final dobRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!dobRegex.hasMatch(trimmed)) return false;

    final parsed = DateTime.tryParse(trimmed);
    return parsed != null;
  }
}