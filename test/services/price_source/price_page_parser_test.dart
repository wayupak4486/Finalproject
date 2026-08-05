import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:lastboss/services/price_source/price_page_parser.dart';
import 'package:lastboss/services/price_source/wongpanit_price_service.dart';

class _FakeClient extends http.BaseClient {
  _FakeClient(this.response);

  final http.Response response;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  }
}

void main() {
  test('parser อ่านตารางราคา fixture และเลือกเฉพาะวัสดุที่รองรับ', () async {
    final fixture = await File(
      'test/fixtures/wongpanit_price.html',
    ).readAsString();

    expect(const PricePageParser().parsePrices(fixture), {
      'pet_plastic_bottle': 8.5,
      'hdpe_plastic': 7.25,
      'paper_cardboard': 3.0,
      'aluminum_can': 35.0,
      'glass': 1.0,
      'steel_scrap': 6.0,
    });
  });

  test('service แจ้งข้อผิดพลาดเมื่อเว็บตอบสถานะผิดพลาด', () async {
    final service = WongpanitPriceService(
      client: _FakeClient(http.Response('unavailable', 503)),
    );

    await expectLater(
      service.fetchPrices(),
      throwsA(isA<PriceFetchException>()),
    );
  });
}
