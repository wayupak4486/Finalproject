// ==============================================================================
// ส่วนที่ 1: คลาสแม่พิมพ์ HistoryRecordModel
// ==============================================================================
class HistoryRecordModel { //
  // Constructor บังคับรับค่า 12 ตัวแปรหลัก
  const HistoryRecordModel({ //
    this.id,
    required this.imagePath,
    required this.material,
    required this.category,
    required this.confidence,
    required this.weight,
    required this.pricePerKg,
    required this.estimatedPrice,
    required this.co2Saved,
    required this.co2FactorPerKg,
    required this.pointsEarned,
    required this.note,
    required this.createdAt,
  });

  // ประกาศตัวแปรทั้งหมดเป็น final ป้องกันการแก้ไขค่าโดยพลการ
  final int? id; //[cite: 20]
  final String imagePath; //[cite: 20]
  final String material; //[cite: 20]
  final String category; //[cite: 20]
  final double confidence; //[cite: 20]
  final double weight; //[cite: 20]
  final double pricePerKg; //[cite: 20]
  final double estimatedPrice; //[cite: 20]
  final double co2Saved; //[cite: 20]
  final double co2FactorPerKg; //[cite: 20]
  final int pointsEarned; //[cite: 20]
  final String? note; //[cite: 20]
  final DateTime createdAt; //[cite: 20]

  // ----------------------------------------------------------------------------
  // เช็คว่าประวัตินี้รอใส่น้ำหนักอยู่หรือไม่?
  // ----------------------------------------------------------------------------
  /// เงื่อนไข: น้ำหนัก <= 0 (ยังไม่ใส่) และ pricePerKg > 0 (เป็นขยะที่ขายได้มีราคา)
  /// ถ้าขยะชนิดนั้นรับซื้อไม่ได้ (ราคา 0) ก็ถือว่าไม่รอใส่น้ำหนัก (false)
  bool get isPendingWeight => weight <= 0 && pricePerKg > 0; //[cite: 20]

  // ----------------------------------------------------------------------------
  // ฟังก์ชัน copyWith: โคลนร่างเก่าแล้วแก้ค่าเฉพาะบางตัว
  // ----------------------------------------------------------------------------
  HistoryRecordModel copyWith({ //[cite: 20]
    double? weight,
    double? estimatedPrice,
    double? co2Saved,
    int? pointsEarned,
  }) {
    // ส่งคืนออบเจกต์ใหม่ โดยยึดข้อมูลเดิม (this.XXX) 
    // แต่ถ้ามีการส่งค่าใหม่มาให้ใช้ค่านั้นแทน (??)
    return HistoryRecordModel( //[cite: 20]
      id: id,
      imagePath: imagePath,
      material: material,
      category: category,
      confidence: confidence,
      weight: weight ?? this.weight,                 // ใช้น้ำหนักใหม่ หรือถ้าไม่มีก็ใช้ของเดิม[cite: 20]
      pricePerKg: pricePerKg,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice, // ใช้ราคารวมใหม่ หรือถ้าไม่มีใช้ของเดิม[cite: 20]
      co2Saved: co2Saved ?? this.co2Saved,           // ใช้คาร์บอนรวมใหม่ หรือถ้าไม่มีใช้ของเดิม[cite: 20]
      co2FactorPerKg: co2FactorPerKg,
      pointsEarned: pointsEarned ?? this.pointsEarned, // ใช้แต้มใหม่ หรือถ้าไม่มีใช้ของเดิม[cite: 20]
      note: note,
      createdAt: createdAt,
    );
  }

  // ----------------------------------------------------------------------------
  // ฟังก์ชัน toMap: แปลงข้อมูลจาก Dart ให้พร้อมเซฟลง Database (ฝั่ง Save)
  // ----------------------------------------------------------------------------
  Map<String, dynamic> toMap() { //[cite: 20]
    return {
      'id': id,
      'image_path': imagePath,
      'material': material,
      'category': category,
      'confidence': confidence,
      'weight': weight,
      'price_per_kg': pricePerKg,
      'estimated_price': estimatedPrice,
      'co2_saved': co2Saved,
      'co2_factor_per_kg': co2FactorPerKg,
      'points_earned': pointsEarned,
      'note': note,
      'created_at': createdAt.toIso8601String(), // วันที่ต้องเซฟเป็นข้อความเสมอ[cite: 20]
    };
  }

  // ----------------------------------------------------------------------------
  // ฟังก์ชัน fromMap: แปลงข้อมูลจาก Database กลับมาเป็นออบเจกต์ Dart (ฝั่ง Load)
  // ----------------------------------------------------------------------------
  factory HistoryRecordModel.fromMap(Map<String, dynamic> map) { //[cite: 20]
    return HistoryRecordModel( //[cite: 20]
      id: map['id'] as int?,
      imagePath: map['image_path'] as String,
      material: map['material'] as String,
      category: map['category'] as String,
      confidence: (map['confidence'] as num).toDouble(), // ดึงเป็นตัวเลข แล้วแปลงเป็นทศนิยมเพื่อความชัวร์[cite: 20]
      weight: (map['weight'] as num).toDouble(),
      pricePerKg: (map['price_per_kg'] as num).toDouble(),
      estimatedPrice: (map['estimated_price'] as num).toDouble(),
      co2Saved: (map['co2_saved'] as num).toDouble(),
      co2FactorPerKg: (map['co2_factor_per_kg'] as num?)?.toDouble() ?? 0, // ถ้าตารางเก่าไม่มีคอลัมน์นี้ ให้ใส่เป็น 0[cite: 20]
      pointsEarned: map['points_earned'] as int,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String), // แปลงข้อความกลับมาเป็นโครงสร้างเวลา[cite: 20]
    );
  }
}

// ==============================================================================
// ส่วนที่ 2: Extension (ส่วนขยายสำหรับคำนวณยอดรวมของหลายๆ ประวัติ)
// ==============================================================================
extension HistoryRecordListSummary on List<HistoryRecordModel> { //[cite: 20]
  
  // หาผลรวมราคาทั้งหมด
  double get totalEstimatedPrice => //[cite: 20]
      fold<double>(0, (sum, record) => sum + record.estimatedPrice); //[cite: 20]

  // หาผลรวมคาร์บอนที่ลดได้
  double get totalCo2Saved => //[cite: 20]
      fold<double>(0, (sum, record) => sum + record.co2Saved); //[cite: 20]

  // หาผลรวมแต้ม
  int get totalPointsEarned => //[cite: 20]
      fold<int>(0, (sum, record) => sum + record.pointsEarned); //[cite: 20]
}