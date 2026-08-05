import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lastboss/core/constants/material_catalog.dart';
import 'package:lastboss/services/ml/classifier_service.dart';

void main() {
  test('labels ของโมเดลทั้ง 7 รายการมีข้อมูลอ้างอิงในแอป', () async {
    final rawLabels = await File('assets/models/labels.txt').readAsString();
    final labels = ClassifierService.parseLabels(rawLabels);

    expect(labels, hasLength(7));
    expect(labels, orderedEquals(MaterialCatalog.byLabel.keys));
    expect(labels, everyElement(isNotEmpty));
  });
}
