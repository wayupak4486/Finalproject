// ==============================================================================
// ส่วนที่ 1: นำเข้าไฟล์ (Import) ที่จำเป็นต้องใช้งาน
// ==============================================================================
import 'package:flutter/material.dart'; // นำเข้าเครื่องมือสร้าง UI ของ Flutter

// นำเข้าไฟล์ "หน้าจอ" ทั้งหมดที่มีในแอปพลิเคชัน (เหมือนดึงตัวนักแสดงมารอที่หลังเวที)
import '../features/history/presentation/screens/history_screen.dart'; // หน้าประวัติ
import '../features/home/presentation/screens/home_screen.dart'; // หน้าหลัก
import '../features/prices/presentation/screens/price_screen.dart'; // หน้าราคา
import '../features/scan/presentation/screens/result_screen.dart'; // หน้าผลลัพธ์ AI
import '../features/scan/presentation/screens/scan_confirm_screen.dart'; // หน้ากดยืนยันรูปสแกน
import '../features/scan/presentation/screens/scan_screen.dart'; // หน้ากล้องถ่ายรูป/เลือกรูป
import '../features/settings/presentation/screens/settings_screen.dart'; // หน้าตั้งค่า
import '../features/statistics/presentation/screens/statistics_screen.dart'; // หน้าสถิติ

// ==============================================================================
// ส่วนที่ 2: คลาส AppRoutes สำหรับจัดการเส้นทาง
// ==============================================================================
class AppRoutes {
  // ----------------------------------------------------------------------------
  // Private Constructor: ใส่เครื่องหมาย _ (ขีดล่าง) เพื่อบอกว่าเป็นของส่วนตัว (Private)
  // หน้าที่: "ล็อคกุญแจ" ป้องกันไม่ให้โปรแกรมเมอร์คนอื่นเขียนคำสั่ง AppRoutes() เพื่อจำลองคลาสนี้ซ้ำซ้อน
  // เพราะเราต้องการให้เรียกใช้งานแบบ AppRoutes.home ได้เลยตรงๆ (ประหยัดหน่วยความจำ)
  // ----------------------------------------------------------------------------
  const AppRoutes._();

  // ----------------------------------------------------------------------------
  // ส่วนที่ 3: ประกาศตัวแปร "ชื่อเส้นทาง" (Route Names)
  // ใช้ static const เพื่อให้เรียกใช้ได้ทันที และคอมพิวเตอร์จดจำไว้ตลอดไปโดยไม่กินเครื่อง
  // ----------------------------------------------------------------------------
  static const String home =
      '/'; // '/' เป็นสัญลักษณ์สากลหมายถึง "หน้าแรกสุด" ของแอป
  static const String scan = '/scan'; // ตั้งชื่อ '/scan' ให้หน้าสแกน
  static const String scanConfirm = '/scan/confirm';
  static const String result = '/result';
  static const String history = '/history';
  static const String statistics = '/statistics';
  static const String settings = '/settings';
  static const String prices = '/prices';

  // ----------------------------------------------------------------------------
  // ส่วนที่ 4: ฟังก์ชัน routes (แผนที่จับคู่หน้าจอ)
  // หน้าที่: ผูก "ชื่อเส้นทาง" (ด้านซ้าย) เข้ากับ "หน้าจอจริงๆ" (ด้านขวา)
  // คืนค่าเป็น Map (พจนานุกรม/สมุดหน้าเหลือง)
  // ----------------------------------------------------------------------------
  static Map<String, WidgetBuilder> get routes => {
    // โครงสร้างคือ:  ชื่อตัวแปรเส้นทาง : (บริบทหน้าจอ) => เปิดไฟล์หน้าจอไหน
    // เครื่องหมาย _ หมายถึง เราได้รับตัวแปร context มา แต่เรา "ไม่ได้ใช้" เลยใส่ขีดล่างไว้ (ละเว้น)
    home: (_) =>
        const HomeScreen(), // ถ้าเรียก AppRoutes.home ให้ไปเปิด HomeScreen
    scan: (_) =>
        const ScanScreen(), // ถ้าเรียก AppRoutes.scan ให้ไปเปิด ScanScreen
    scanConfirm: (_) =>
        const ScanConfirmScreen(), // ถ้าเรียก AppRoutes.scanConfirm ให้ไปเปิด ScanConfirmScreen
    result: (_) =>
        const ResultScreen(), // ถ้าเรียก AppRoutes.result ให้ไปเปิด ResultScreen
    history: (_) =>
        const HistoryScreen(), // ถ้าเรียก AppRoutes.history ให้ไปเปิด HistoryScreen
    statistics: (_) =>
        const StatisticsScreen(), // ถ้าเรียก AppRoutes.statistics ให้ไปเปิด StatisticsScreen
    settings: (_) =>
        const SettingsScreen(), // ถ้าเรียก AppRoutes.settings ให้ไปเปิด SettingsScreen
    prices: (_) =>
        const PriceScreen(), // ถ้าเรียก AppRoutes.prices ให้ไปเปิด PriceScreen
  };
}
