// ==============================================================================
// ส่วนที่ 1: คลาส MaterialInfo (พิมพ์เขียวโครงสร้างข้อมูลวัสดุ 1 ชนิด)
// ==============================================================================
class MaterialInfo {
  // Constructor: รับค่าต่างๆ เข้ามาตอนสร้างข้อมูลวัสดุ
  // คำว่า 'required' หมายถึง "บังคับต้องใส่ข้อมูลนี้ ห้ามเว้นว่างเด็ดขาด"
  const MaterialInfo({
    required this.displayName, // ชื่อที่ใช้แสดงบนหน้าจอ
    required this.category, // หมวดหมู่
    required this.pricePerKg, // ราคาประเมินต่อ 1 กิโลกรัม
    required this.co2FactorPerKg, // ค่าสัมประสิทธิ์การลดก๊าซคาร์บอน (CO2e)
    this.isSellable =
        true, // เป็นขยะที่ขายได้หรือไม่ (ตั้งค่าเริ่มต้นเป็น true คือขายได้)
    required this.tips, // รายการคำแนะนำในการจัดการขยะ (List ของข้อความ)
  });

  // ประกาศตัวแปร (Field) ทั้งหมดของคลาส (ใช้ final เพราะข้อมูลพวกนี้สร้างแล้วไม่ควรโดนแก้กลางทาง)
  final String displayName;
  final String category;
  final double pricePerKg;
  final double co2FactorPerKg;
  final bool isSellable;
  final List<String> tips;
}

// ==============================================================================
// ส่วนที่ 2: คลาส MaterialCatalog (ฐานข้อมูลอ้างอิงวัสดุทั้งหมด)
// ==============================================================================
/// คำอธิบายในโค้ด: เป็นข้อมูลอ้างอิงที่ใช้ "Key" ตรงกับชื่อ Label ที่มาจากไฟล์ AI (labels.txt)
/// ส่วนข้อมูล ราคา และ ค่า CO2 เป็นเพียงการประมาณการล่วงหน้า (ยังไม่ใช่ราคาแบบ Live)
class MaterialCatalog {
  // ล็อคไม่ให้สร้าง Object (เหมือนไฟล์ก่อนๆ)
  const MaterialCatalog._();

  // ----------------------------------------------------------------------------
  // ตัวแปร byLabel (พจนานุกรมข้อมูล หรือ Map)
  // โครงสร้าง Map <String (Key จาก AI), MaterialInfo (ข้อมูลฉบับเต็ม)>
  // ----------------------------------------------------------------------------
  static const Map<String, MaterialInfo> byLabel = {
    // Key ของ AI คือ 'aluminum_can' จะคู่กับข้อมูลกระป๋องอะลูมิเนียม
    'aluminum_can': MaterialInfo(
      displayName: 'อะลูมิเนียม',
      category: 'โลหะ',
      pricePerKg: 35.0, // ราคาประเมิน 35 บาท/กก.
      co2FactorPerKg: 9.0, // ลดคาร์บอน 9 หน่วย/กก.
      tips: [
        'เทของเหลวออกและล้างกระป๋องให้สะอาด',
        'บีบกระป๋องให้แบนเพื่อประหยัดพื้นที่',
        'แกะฉลากพลาสติกออก',
      ],
    ),

    // ขยะประเภทที่ 2: ขยะทั่วไป (สังเกตว่า isSellable ถูดตั้งเป็น false คือขายไม่ได้)
    'general_waste': MaterialInfo(
      displayName: 'ขยะทั่วไป',
      category: 'รีไซเคิลไม่ได้',
      pricePerKg: 0,
      co2FactorPerKg: 0,
      isSellable: false,
      tips: ['วัสดุนี้ไม่รับซื้อ', 'ทิ้งลงถังขยะที่เหมาะสม'],
    ),

    // ... (ส่วนตรงนี้คือข้อมูล แก้ว, พลาสติก HDPE, กระดาษ, PET, เศษเหล็ก โครงสร้างเหมือนกันครับ)
    'glass': MaterialInfo(
      /* ... */ displayName: 'แก้ว',
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
      /* ... */ displayName: 'พลาสติก HDPE',
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
      /* ... */ displayName: 'กระดาษ/กระดาษลัง',
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
      /* ... */ displayName: 'ขวดพลาสติก PET',
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
      /* ... */ displayName: 'เศษเหล็ก',
      category: 'โลหะ',
      pricePerKg: 6.0,
      co2FactorPerKg: 1.8,
      tips: [
        'แยกออกจากโลหะชนิดอื่นถ้าเป็นไปได้',
        'ถอดชิ้นส่วนที่ไม่ใช่โลหะออก',
      ],
    ),
  };

  // ----------------------------------------------------------------------------
  // ฟังก์ชัน lookup: ใช้ค้นหาข้อมูลวัสดุจากชื่อภาษาอังกฤษ
  // ----------------------------------------------------------------------------
  static MaterialInfo lookup(String label) {
    // โค้ดนี้ใช้เครื่องหมาย ?? (Null coalescing operator)
    // ความหมายคือ: เอา label ไปหาใน Map byLabel ก่อน
    // ถ้าหาเจอ (ไม่เป็น null) ก็ส่งค่า MaterialInfo นั้นกลับไป
    // แต่ถ้าหา "ไม่เจอ" (เป็น null) ให้ส่งค่าเริ่มต้นด้านหลัง ?? กลับไปแทน (Fall-back)
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
