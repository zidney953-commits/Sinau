import 'package:flutter_test/flutter_test.dart';
import 'package:sinau/screens/user/lesson_screen.dart';
import 'package:sinau/widgets/common.dart';

void main() {
  test('passMin: lulus minimal 2 dari 3 soal', () {
    expect(passMin(1), 1);
    expect(passMin(2), 2);
    expect(passMin(3), 2);
    expect(passMin(6), 4);
  });

  test('initials dari nama', () {
    expect(initials('Zidney'), 'Z');
    expect(initials('Kais Al Akmal'), 'KA');
  });
}
