import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lastboss/services/ml/classifier_service.dart';

void main() {
  test('ไฟล์ภาพที่อ่านไม่ได้ส่งข้อผิดพลาดก่อนเปิดโมเดล', () async {
    final directory = await Directory.systemTemp.createTemp('godscan_test_');
    final file = File('${directory.path}${Platform.pathSeparator}invalid.jpg');
    await file.writeAsString('not an image');

    addTearDown(() => directory.delete(recursive: true));

    await expectLater(
      ClassifierService.instance.classify(file.path),
      throwsA(isA<StateError>()),
    );
  });
}
