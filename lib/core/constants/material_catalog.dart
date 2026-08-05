class MaterialInfo {
  const MaterialInfo({
    required this.displayName,
    required this.category,
    required this.pricePerKg,
    required this.co2FactorPerKg,
    this.isSellable = true,
    required this.tips,
  });

  final String displayName;
  final String category;
  final double pricePerKg;
  final double co2FactorPerKg;
  final bool isSellable;
  final List<String> tips;
}

/// Reference data keyed by the raw label emitted by [AssetPaths.labels].
///
/// Price (THB/kg) and CO2 factors are indicative junk-shop estimates, not
/// live market data — adjust freely to match local pricing.
class MaterialCatalog {
  const MaterialCatalog._();

  static const Map<String, MaterialInfo> byLabel = {
    'aluminum_can': MaterialInfo(
      displayName: 'อะลูมิเนียม',
      category: 'โลหะ',
      pricePerKg: 35.0,
      co2FactorPerKg: 9.0,
      tips: [
        'เทของเหลวออกและล้างกระป๋องให้สะอาด',
        'บีบกระป๋องให้แบนเพื่อประหยัดพื้นที่',
        'แกะฉลากพลาสติกออก',
      ],
    ),
    'general_waste': MaterialInfo(
      displayName: 'ขยะทั่วไป',
      category: 'รีไซเคิลไม่ได้',
      pricePerKg: 0,
      co2FactorPerKg: 0,
      isSellable: false,
      tips: ['วัสดุนี้ไม่รับซื้อ', 'ทิ้งลงถังขยะที่เหมาะสม'],
    ),
    'glass': MaterialInfo(
      displayName: 'แก้ว',
      category: 'แก้ว',
      pricePerKg: 1.0,
      co2FactorPerKg: 0.3,
      tips: [
        'ล้างคราบที่เหลืออยู่ออก',
        'ถอดฝาและจุกออก',
        'จับอย่างระมัดระวังเพื่อไม่ให้แตก',
      ],
    ),
    'hdpe_plastic': MaterialInfo(
      displayName: 'พลาสติก HDPE',
      category: 'พลาสติก',
      pricePerKg: 8.0,
      co2FactorPerKg: 1.5,
      tips: [
        'เทของเหลวที่เหลือออก',
        'ล้างภาชนะให้สะอาด',
        'บีบอัดเพื่อประหยัดพื้นที่',
      ],
    ),
    'paper_cardboard': MaterialInfo(
      displayName: 'กระดาษ/กระดาษลัง',
      category: 'กระดาษ',
      pricePerKg: 3.0,
      co2FactorPerKg: 1.0,
      tips: [
        'เก็บให้แห้งและเรียบ',
        'แกะเทปและลวดเย็บกระดาษออก',
        'พับกล่องให้แบนเพื่อประหยัดพื้นที่',
      ],
    ),
    'pet_plastic_bottle': MaterialInfo(
      displayName: 'ขวดพลาสติก PET',
      category: 'พลาสติก',
      pricePerKg: 8.5,
      co2FactorPerKg: 1.5,
      tips: [
        'เทของเหลวที่เหลือออก',
        'ล้างขวดให้สะอาด',
        'แยกฝาออก',
        'บีบขวดให้แบน',
      ],
    ),
    'steel_scrap': MaterialInfo(
      displayName: 'เศษเหล็ก',
      category: 'โลหะ',
      pricePerKg: 6.0,
      co2FactorPerKg: 1.8,
      tips: [
        'แยกออกจากโลหะชนิดอื่นถ้าเป็นไปได้',
        'ถอดชิ้นส่วนที่ไม่ใช่โลหะออก',
      ],
    ),
  };

  static MaterialInfo lookup(String label) {
    return byLabel[label] ??
        const MaterialInfo(
          displayName: 'ไม่ทราบชนิดวัสดุ',
          category: 'ไม่รองรับ',
          pricePerKg: 0,
          co2FactorPerKg: 0,
          tips: ['ไม่สามารถระบุชนิดวัสดุนี้ได้อย่างมั่นใจ'],
        );
  }
}
