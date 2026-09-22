import 'package:climavent/core/widgets/phone_input.dart';
import 'package:climavent/features/auth/data/session.dart';
import 'package:climavent/features/catalog/ui/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('telefon formatlash', () {
    expect(formatUzPhone('901234567'), '90 123 45 67');
    expect(prettyPhone('+998901234567'), '+998 90 123 45 67');
    expect(isValidUzMobile('901234567'), isTrue);
    expect(isValidUzMobile('012345678'), isFalse);
  });

  test('profil javobi — ism o\'rnida telefon bo\'lsa e\'tiborsiz', () {
    final p = UserProfile.fromJson({
      'client': {'id': 5, 'name': '+998901234567', 'phone_number': '+998901234567'}
    });
    expect(p.id, '5');
    expect(p.hasName, isFalse);
    final q = UserProfile.fromJson({'id': 7, 'name': 'Aziz', 'surname': 'Karimov'});
    expect(q.initials, 'AK');
  });

  test('rasm manzili — buzuq % va kirill bilan yiqilmaydi', () {
    expect(imageUrl('https://x.uz/a%ZZb.png'), 'https://x.uz/a%ZZb.png');
    expect(imageUrl('https://x.uz/Серия.png'), 'https://x.uz/%D0%A1%D0%B5%D1%80%D0%B8%D1%8F.png');
    expect(imageUrl('https://res.cloudinary.com/x/image/upload/v1/a.png', width: 400),
        'https://res.cloudinary.com/x/image/upload/w_400,c_limit,q_auto,f_auto/v1/a.png');
  });
}
