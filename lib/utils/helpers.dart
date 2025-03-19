class Helpers {
  static bool isValidPhoneNumber(String phone) {
    final RegExp phoneRegExp = RegExp(r'^\d{10}$');
    return phoneRegExp.hasMatch(phone);
  }

  static String trimText(String text) {
    return text.trim();
  }
}