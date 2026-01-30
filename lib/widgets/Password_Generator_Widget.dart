import 'dart:math';

class PasswordGenerator {
  static String generate({
    int length = 16,
    bool upper = true,
    bool lower = true,
    bool numbers = true,
    bool symbols = true,
  }) {
    const upperChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lowerChars = 'abcdefghijklmnopqrstuvwxyz';
    const numbersChars = '0123456789';
    const symbolsChars = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

    String chars = '';
    if (upper) chars += upperChars;
    if (lower) chars += lowerChars;
    if (numbers) chars += numbersChars;
    if (symbols) chars += symbolsChars;

    if (chars.isEmpty) return '';

    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }
}

// استخدام في UI:
// ElevatedButton(
//   onPressed: () {
//     final pwd = PasswordGenerator.generate(length: 20, symbols: true);
//     // copy to field
//   },
//   child: Text('Generate Strong Password'),
// )