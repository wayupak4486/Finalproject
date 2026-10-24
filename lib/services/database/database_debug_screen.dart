import 'package:flutter/material.dart'; // นำเข้าเครื่องมือวาดหน้าจอ

import 'app_database.dart'; // นำเข้าท่อเชื่อมต่อ Database (Singleton)
import 'database_debug_tool.dart'; // นำเข้าเครื่องมือเขียนคำสั่ง SQL ดิบๆ สำหรับ Debug

/// หน้าจอสำหรับนักพัฒนา (Debug-only) เอาไว้ลิสต์ตารางทั้งหมดใน SQLite
/// และเจาะลึกดูข้อมูลรายบรรทัดได้
class DatabaseDebugScreen extends StatefulWidget {
  const DatabaseDebugScreen({super.key});

  @override
  State<DatabaseDebugScreen> createState() => _DatabaseDebugScreenState();
}

class _DatabaseDebugScreenState extends State<DatabaseDebugScreen> {
  // 💡 ตัวแปร Future คือ "คำสัญญา" ว่าอนาคตจะมีข้อมูลวิ่งมาให้
  // late หมายถึง จะกำหนดค่าให้ในฟังก์ชัน initState ด้านล่างแน่นอน
  late Future<List<String>> _tablesFuture;

  @override
  void initState() {
    super.initState();
    // เมื่อเปิดหน้าจอ ให้เริ่มทำงานฟังก์ชัน _loadTables ทันที แล้วเอาคำสัญญามาเก็บไว้
    _tablesFuture = _loadTables();
  }

  // ฟังก์ชันคุยกับ DB เพื่อดึง "ชื่อตารางทั้งหมด" กลับมา
  Future<List<String>> _loadTables() async {
    final db = await AppDatabase.instance.database; // ขอเชื่อม DB
    return DatabaseDebugTool.listTables(db); // ไปค้นหาชื่อตาราง
  }

  // ฟังก์ชันโหลดข้อมูลใหม่ (ทำงานตอนกดปุ่มรีเฟรชมุมขวาบน)
  void _reload() {
    setState(() {
      _tablesFuture =
          _loadTables(); // สั่งไปดึงข้อมูลมาทับของเดิม หน้าจอจะรีเฟรช
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Debug Viewer'),
        actions: [
          IconButton(
            // ปุ่มรีเฟรช
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      // 💡 FutureBuilder: วิดเจ็ตเทพ! มันจะรับ _tablesFuture เข้าไป แล้วตัดสินใจเองว่า
      // ตอนนี้ควรโชว์ตัวหมุนโหลด, โชว์ Error, หรือโชว์หน้าจอที่มีข้อมูล
      body: FutureBuilder<List<String>>(
        future: _tablesFuture, // เอาตั๋วรอคิวเสียบเข้าไป
        builder: (context, snapshot) {
          // snapshot คือ "ซองจดหมาย" ที่คอยอัปเดตสถานะของข้อมูล

          // 1. ถ้าการเชื่อมต่อยังไม่เสร็จ (กำลังโหลด)
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            ); // โชว์วงกลมหมุนๆ
          }

          // 2. ถ้าโหลดเสร็จแล้ว แต่พัง (มี Error)
          if (snapshot.hasError) {
            return Center(child: Text('โหลดตารางไม่สำเร็จ: ${snapshot.error}'));
          }

          // 3. ถ้าสำเร็จ ดึงข้อมูลออกมา (ถ้าเป็น null ให้ใส่ลิสต์ว่าง [] กันแอปพัง)
          final tables = snapshot.data ?? [];
          if (tables.isEmpty) {
            return const Center(
              child: Text('ไม่พบตารางในฐานข้อมูล'),
            ); // โชว์กรณีไม่มีตารางเลย
          }

          // 4. กรณีข้อมูลพร้อมใช้งาน: สร้างลิสต์ (ListView) โชว์ชื่อตาราง
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: tables.length, // จำนวนรายการเท่ากับจำนวนชื่อตาราง
            separatorBuilder: (_, _) =>
                const SizedBox(height: 8), // ตัวคั่นระหว่างบรรทัด
            itemBuilder: (context, index) {
              // โยนชื่อตารางแต่ละชื่อ ไปให้ชิ้นส่วน _TableSection จัดการวาดตัวเอง
              return _TableSection(tableName: tables[index]);
            },
          );
        },
      ),
    );
  }
}

// ===========================================================================
// วิดเจ็ตย่อย: แสดงลิสต์ 1 บรรทัด (สำหรับ 1 ตาราง) แบบที่กดลูกศรกางลงมาดูข้อมูลได้
// ===========================================================================
class _TableSection extends StatefulWidget {
  // รอรับชื่อตารางมาจากตัวแม่ตอนสร้างวิดเจ็ต
  const _TableSection({required this.tableName});

  final String tableName; // เก็บชื่อตาราง เช่น 'history'

  @override
  State<_TableSection> createState() => _TableSectionState();
}

class _TableSectionState extends State<_TableSection> {
  // ตั๋วรอคิวนับจำนวนแถว
  late final Future<int> _countFuture;

  // 💡 ตั๋วรอคิวดูดข้อมูลแถว (เป็น nullable: ?) เพราะเริ่มแรกเรายังไม่โหลด เพื่อประหยัดเมม
  Future<List<Map<String, Object?>>>? _rowsFuture;

  @override
  void initState() {
    super.initState();
    // โหลดแค่นับจำนวนแถวไปก่อน
    _countFuture = _loadCount();
  }

  // ไปถาม DB ว่าตารางชื่อนี้ มีกี่แถว
  Future<int> _loadCount() async {
    final db = await AppDatabase.instance.database;
    return DatabaseDebugTool.countRows(
      db,
      widget.tableName,
    ); // เข้าถึงตัวแปรของคลาสแม่ด้วย widget.
  }

  // ไปถาม DB ให้ดึงข้อมูลทุกแถว ทุกคอลัมน์ ออกมา
  Future<List<Map<String, Object?>>> _loadRows() async {
    final db = await AppDatabase.instance.database;
    return DatabaseDebugTool.fetchRows(db, widget.tableName);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias, // ตัดขอบลูกๆ ให้ไม่ทะลุการ์ดออกมา
      // 💡 ExpansionTile: วิดเจ็ตแบบมีหัวข้อ และกดให้ "กางออก" เป็นเนื้อหาด้านล่างได้
      child: ExpansionTile(
        title: Text(widget.tableName), // หัวข้อคือชื่อตาราง
        // คำอธิบายตัวเล็กๆ ด้านล่าง (ใช้ FutureBuilder เพราะมันต้องรอผลการนับเลข)
        subtitle: FutureBuilder<int>(
          future: _countFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Text('กำลังนับแถว...');
            return Text('${snapshot.data} แถว'); // โชว์ว่ามีกี่แถว
          },
        ),

        // 💡 เมื่อผู้ใช้กดคลิกที่ตัวลิสต์ (เพื่อกางออก หรือ หดเข้า)
        onExpansionChanged: (expanded) {
          // ถ้ากดกางออก (expanded == true) และยังไม่เคยโหลดข้อมูลมาก่อน (_rowsFuture == null)
          if (expanded && _rowsFuture == null) {
            setState(() {
              // เพิ่งจะมาสั่งโหลดข้อมูลจริงๆ ก็ตอนกดคลิกนี่แหละ (Lazy Loading)
              _rowsFuture = _loadRows();
            });
          }
        },

        // เนื้อหาข้างในที่ซ่อนอยู่ (จะโชว์ตอนกางออก)
        children: [
          // เช็คว่าถ้าตัวแปรมีค่า (คือเคยกดโหลดแล้ว) ค่อยวาด FutureBuilder
          if (_rowsFuture != null)
            FutureBuilder<List<Map<String, Object?>>>(
              future: _rowsFuture,
              builder: (context, snapshot) {
                // 1. กำลังโหลดข้อมูล
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                // 2. โหลดพัง
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('โหลดข้อมูลไม่สำเร็จ: ${snapshot.error}'),
                  );
                }

                final rows = snapshot.data ?? [];
                // 3. ตารางว่าง ไม่มีข้อมูล
                if (rows.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('ตารางว่าง'),
                  );
                }

                // 4. ได้ข้อมูลมาแล้ว:
                // ดึงรายชื่อคอลัมน์ทั้งหมด (keys) จากแถวแรกสุด (rows.first) มาเก็บไว้
                final columns = rows.first.keys.toList();

                // 💡 SingleChildScrollView (แนวนอน)
                // ตารางอาจจะมีคอลัมน์เยอะจนล้นขอบจอมือถือ จึงต้องหุ้มด้วยวิดเจ็ตให้มันใช้นิ้วไถซ้าย-ขวาได้
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),

                  // 💡 DataTable: วิดเจ็ตสร้างตารางข้อมูล
                  child: DataTable(
                    // ส่วนหัวคอลัมน์
                    columns: [
                      // วนลูปสร้างคอลัมน์ตามรายชื่อที่ดึงมาได้
                      for (final column in columns)
                        DataColumn(label: Text(column)),
                    ],
                    // ส่วนข้อมูลแต่ละแถว
                    rows: [
                      // วนลูปหยิบข้อมูลทีละบรรทัดมา
                      for (final row in rows)
                        DataRow(
                          cells: [
                            // วนลูปยัดข้อมูลลงไปทีละช่อง ตามชื่อคอลัมน์
                            for (final column in columns)
                              DataCell(Text('${row[column]}')),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
