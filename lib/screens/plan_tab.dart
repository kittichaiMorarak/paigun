import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:url_launcher/url_launcher.dart';
import '../models/place.dart';
import '../services/app_state.dart';
import '../services/translations.dart';
import 'place_detail_screen.dart' show durText;

class PlanTab extends StatefulWidget {
  const PlanTab({super.key});

  @override
  State<PlanTab> createState() => _PlanTabState();
}

class _PlanTabState extends State<PlanTab> {
  bool _showPackingList = false;

  Future<void> _openHotelSearch(BuildContext context, String province) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=โรงแรม+ที่พัก+ใน+$province',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการเปิดแผนที่: $e')),
        );
      }
    }
  }

  void _clearTripPlan(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(context, 'ล้างแผนเที่ยว', 'Clear Trip Plan')),
        content: Text(tr(
          context,
          'คุณต้องการล้างสถานที่ทั้งหมดในแผนเที่ยวหรือไม่?',
          'Are you sure you want to clear all places from your trip plan?',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr(context, 'ยกเลิก', 'Cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr(context, 'ล้างแผน', 'Clear All')),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      AppStateProvider.of(context).clearPlaceSelection();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, 'ล้างแผนเที่ยวเรียบร้อยแล้ว', 'Trip plan cleared')),
        ),
      );
    }
  }

  void _selectTripDates(BuildContext context) async {
    final appState = AppStateProvider.of(context);
    final initialRange = DateTimeRange(
      start: appState.tripStartDate ?? DateTime.now().add(const Duration(days: 3)),
      end: appState.tripEndDate ?? DateTime.now().add(const Duration(days: 5)),
    );

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: tr(context, 'เลือกวันเดินทางของทริปนี้', 'Select Trip Dates'),
      confirmText: tr(context, 'ตกลง', 'OK'),
      cancelText: tr(context, 'ยกเลิก', 'Cancel'),
    );

    if (picked != null) {
      appState.setTripDates(picked.start, picked.end);
    }
  }

  void _copyPlanSummary(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final places = appState.selectedPlaces;
    if (places.isEmpty) return;

    final sb = StringBuffer();
    sb.writeln('🗺 แผนเที่ยวไปกัน (${places.length} สถานที่)');
    if (appState.tripStartDate != null && appState.tripEndDate != null) {
      sb.writeln('📅 วันเดินทาง: ${_formatDate(appState.tripStartDate!)} - ${_formatDate(appState.tripEndDate!)}');
    }
    sb.writeln('----------------------------------------');
    for (var i = 0; i < places.length; i++) {
      final p = places[i];
      sb.writeln('${i + 1}. ${p.name} (${p.province}) - เที่ยว ~${durText(p.avgDurationMin)}');
      if (i < places.length - 1) {
        final dist = p.distanceKm(places[i + 1]);
        final travelMin = ((dist / 40.0) * 60).round();
        sb.writeln('   🚗 เดินทางไป ${places[i + 1].name}: ~${dist.toStringAsFixed(1)} กม. (ใช้เวลา ~${durText(travelMin)})');
      }
    }
    sb.writeln('----------------------------------------');
    sb.writeln('⏱ เวลาเที่ยวรวม: ~${durText(appState.totalVisitDurationMin)}');
    sb.writeln('🚗 เวลาเดินทางรวม: ~${durText(appState.totalTravelTimeMin)}');
    sb.writeln('💰 ค่าน้ำมันประมาณ: ~${appState.estimatedFuelCost.round()} บาท');
    sb.writeln('🎟 ค่าเข้าชมประมาณ: ~${appState.totalEstimatedEntranceFee} บาท');

    Clipboard.setData(ClipboardData(text: sb.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr(
            context,
            'คัดลอกตารางเดินทางและรายละเอียดทั้งหมดไปยัง Clipboard แล้ว!',
            'Copied trip summary to Clipboard!')),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year + 543}';
  }

  void _showAddPackingDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    String category = 'ของใช้';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(context, 'เพิ่มสิ่งของที่ต้องจัด', 'Add Packing Item')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                labelText: tr(context, 'ชื่อสิ่งของ', 'Item Name'),
                hintText: 'เช่น พาวเวอร์แบงก์, หมวกกันแดด',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: InputDecoration(
                labelText: tr(context, 'หมวดหมู่', 'Category'),
                border: const OutlineInputBorder(),
              ),
              items: ['เอกสาร', 'เสื้อผ้า', 'ไอที', 'ยา/สุขภาพ', 'ของใช้']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => category = v!,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr(context, 'ยกเลิก', 'Cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF134E3A),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (titleCtrl.text.trim().isNotEmpty) {
                AppStateProvider.of(context).addPackingItem(
                  titleCtrl.text.trim(),
                  category,
                );
                Navigator.pop(ctx);
              }
            },
            child: Text(tr(context, 'เพิ่ม', 'Add')),
          ),
        ],
      ),
    );
  }

  void _showShareDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Text('📤', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(tr(context, 'แชร์แผนของฉัน', 'Share My Plan')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tr(context, 'กรอกชื่อและรายละเอียดเพื่อแชร์แผนนี้กับเพื่อนๆ',
                  'Enter title and description to share with community')),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: tr(context, 'ชื่อแผนเที่ยว *', 'Plan Title *'),
                  hintText: 'เช่น ทริปแอ่วเหนือ 3 วัน 2 คืน',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: tr(context, 'รายละเอียดแผนเที่ยว (ตัวเลือก)',
                      'Description (Optional)'),
                  hintText: 'เช่น เน้นเที่ยววัดและธรรมชาติ',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr(context, 'ยกเลิก', 'Cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF134E3A),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(tr(context, 'กรุณากรอกชื่อแผนเที่ยว',
                          'Please enter a plan title'))),
                );
                return;
              }
              final appState = AppStateProvider.of(context);
              final ids = appState.selectedPlaceIds;

              appState.addSharedPlan(
                title: title,
                description: descController.text.trim().isNotEmpty
                    ? descController.text.trim()
                    : 'แผนเที่ยวโดย ${appState.currentUser?.name ?? "ผู้ใช้"}',
                days: [ids],
              );

              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(tr(
                      context,
                      'แชร์แผนเที่ยวเรียบร้อยแล้ว! ดูได้ในแท็บ "แผนจากเพื่อน"',
                      'Shared plan successfully! View in "Shared Plans" tab')),
                ),
              );
            },
            child: Text(tr(context, 'แชร์แผน', 'Share')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final places = appState.selectedPlaces;

    if (places.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📅', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                tr(context, 'ยังไม่ได้เลือกสถานที่', 'No places selected'),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF134E3A)),
              ),
              const SizedBox(height: 6),
              Text(
                tr(
                    context,
                    'ไปที่แท็บ "สำรวจ" แล้วกดบุ๊กมาร์ก\nเพื่อเลือกสถานที่ท่องเที่ยวในทริปของคุณ',
                    'Go to "Explore" tab and bookmark places\nto build your trip itinerary'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final totalDist = appState.totalTripDistanceKm;
    final totalVisitMin = appState.totalVisitDurationMin;
    final totalTravelMin = appState.totalTravelTimeMin;

    Place? maxLegFrom;
    Place? maxLegTo;
    double maxLegDist = 0.0;
    String? midpointProvince;

    for (var i = 0; i < places.length - 1; i++) {
      final d = places[i].distanceKm(places[i + 1]);
      if (d > maxLegDist) {
        maxLegDist = d;
        maxLegFrom = places[i];
        maxLegTo = places[i + 1];
        midpointProvince = places[i].province;
      }
    }

    final isLongDistance = maxLegDist > 220 || totalDist > 320;

    final fuelCost = appState.estimatedFuelCost.round();
    final entranceFee = appState.totalEstimatedEntranceFee;
    final totalCost = fuelCost + entranceFee;

    final daysUntil = appState.daysUntilTrip;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          // Header Banner Card
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF134E3A), Color(0xFF1E6C52)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF134E3A).withAlpha(65),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr(context, 'แผนเที่ยวของฉัน', 'My Trip Plan'),
                              style: const TextStyle(
                                color: Color(0xFFE5A93C),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${tr(context, "รวม", "Total")} ${places.length} ${tr(context, "สถานที่", "places")} (${totalDist.toStringAsFixed(1)} km)',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      // Clear Trip Plan Button 🧹
                      IconButton(
                        tooltip: tr(context, 'ล้างแผนเที่ยว', 'Clear Plan'),
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.withAlpha(80),
                            shape: BoxShape.circle,
                          ),
                          child: const Text('🗑️', style: TextStyle(fontSize: 14)),
                        ),
                        onPressed: () => _clearTripPlan(context),
                      ),
                      IconButton(
                        tooltip: tr(context, 'จัดลำดับเส้นทางอัตโนมัติ',
                            'Auto Route Sort'),
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5A93C).withAlpha(50),
                            shape: BoxShape.circle,
                          ),
                          child: const Text('🛣️', style: TextStyle(fontSize: 14)),
                        ),
                        onPressed: () {
                          appState.sortSelectedPlacesByRoute();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(tr(
                                  context,
                                  'เรียงลำดับสถานที่ตามเส้นทางเรียบร้อยแล้ว!',
                                  'Sorted places along optimal route!')),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        tooltip: tr(context, 'คัดลอกสรุปทริป', 'Copy Summary'),
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(45),
                            shape: BoxShape.circle,
                          ),
                          child: const Text('📋', style: TextStyle(fontSize: 14)),
                        ),
                        onPressed: () => _copyPlanSummary(context),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE5A93C),
                          foregroundColor: const Color(0xFF134E3A),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Text('📤', style: TextStyle(fontSize: 14)),
                        label: Text(tr(context, 'แชร์แผน', 'Share'),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () => _showShareDialog(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Trip Date Selector & Countdown Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Text('📅', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appState.tripStartDate != null &&
                                    appState.tripEndDate != null
                                ? '${tr(context, "วันเดินทาง", "Dates")}: ${_formatDate(appState.tripStartDate!)} - ${_formatDate(appState.tripEndDate!)}'
                                : tr(context, 'ยังไม่ได้กำหนดวันเดินทาง',
                                    'Dates not set'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF134E3A),
                            ),
                          ),
                          if (daysUntil != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              daysUntil > 0
                                  ? '🎉 ${tr(context, "อีก", "In")} $daysUntil ${tr(context, "วัน จะถึงวันออกเดินทาง!", "days until departure!")}'
                                  : (daysUntil == 0
                                      ? '🚀 ${tr(context, "วันนี้ออกเดินทางแล้ว!", "Departing today!")}'
                                      : tr(context, 'กำลังออกทริปท่องเที่ยว',
                                          'On trip now')),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: daysUntil >= 0
                                    ? Colors.green[800]
                                    : Colors.grey[700],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                      ),
                      onPressed: () => _selectTripDates(context),
                      child: Text(
                        appState.tripStartDate != null
                            ? tr(context, 'เปลี่ยนวัน', 'Change')
                            : tr(context, 'เลือกวัน', 'Set Dates'),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Smart Long-Distance Overnight Rest Advisor Card
          if (isLongDistance &&
              midpointProvince != null &&
              maxLegFrom != null &&
              maxLegTo != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.amber.shade400, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🏨', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          tr(context, '💡 คำแนะนำการเดินทางระยะไกล',
                              '💡 Long-Distance Travel Advice'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tr(
                          context,
                          'การเดินทางจาก "${maxLegFrom.name}" ไปยัง "${maxLegTo.name}" มีระยะทาง ~${maxLegDist.round()} กม. (ขับรถ ~${durText(((maxLegDist / 40.0) * 60).round())}) ซึ่งเป็นระยะทางที่ยาวนาน\n'
                              'แนะนำให้แวะเที่ยวจุดพัก และพักค้างคืนที่โรงแรมในจังหวัด "$midpointProvince" 1 คืน เพื่อความปลอดภัย',
                          'Long distance travel from "${maxLegFrom.name}" to "${maxLegTo.name}" (~${maxLegDist.round()} km). '
                              'Recommended to rest overnight in $midpointProvince.'),
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.brown.shade800,
                          height: 1.4),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF134E3A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Text('🛏️', style: TextStyle(fontSize: 14)),
                        label: Text(
                          '${tr(context, "🏨 ค้นหาโรงแรมแวะพักคืนที่", "🏨 Find Hotels in")} $midpointProvince',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        onPressed: () =>
                            _openHotelSearch(context, midpointProvince!),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Budget Summary Dashboard
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _budgetItem(
                    icon: '⛽',
                    label: tr(context, 'ค่าน้ำมันประมาณ', 'Fuel Est.'),
                    value: '~ $fuelCost ฿',
                  ),
                  Container(width: 1, height: 28, color: Colors.grey[300]),
                  _budgetItem(
                    icon: '🎟️',
                    label: tr(context, 'ค่าเข้าชมประมาณ', 'Fees Est.'),
                    value: '~ $entranceFee ฿',
                  ),
                  Container(width: 1, height: 28, color: Colors.grey[300]),
                  _budgetItem(
                    icon: '👛',
                    label: tr(context, 'งบรวม (~)', 'Total Est.'),
                    value: '~ $totalCost ฿',
                    isHighlight: true,
                  ),
                ],
              ),
            ),
          ),

          // Detailed Leg-by-Leg Route Breakdown Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🛣️', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          tr(context, 'รายละเอียดระยะทาง & เวลาเดินทางระหว่างจุด',
                              'Leg-by-Leg Route Breakdown'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF134E3A),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    for (var i = 0; i < places.length - 1; i++) ...[
                      () {
                        final p1 = places[i];
                        final p2 = places[i + 1];
                        final legDist = p1.distanceKm(p2);
                        final legTravelMin = ((legDist / 40.0) * 60).round();

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor:
                                    const Color(0xFF134E3A).withAlpha(20),
                                child: Text('${i + 1}',
                                    style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF134E3A))),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${p1.name} ➔ ${p2.name}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${legDist.toStringAsFixed(1)} km (🚗 ~${durText(legTravelMin)})',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        );
                      }(),
                    ],
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            '⏱️ ${tr(context, "เวลาเที่ยวรวม", "Visit Time")}: ~${durText(totalVisitMin)}',
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600)),
                        Text(
                            '🚗 ${tr(context, "เวลาเดินทางรวม", "Travel Time")}: ~${durText(totalTravelMin)}',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF134E3A))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Packing List Accordion Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ExpansionTile(
                initiallyExpanded: _showPackingList,
                onExpansionChanged: (v) =>
                    setState(() => _showPackingList = v),
                leading: const Text('🎒', style: TextStyle(fontSize: 20)),
                title: Row(
                  children: [
                    Text(
                      tr(context, 'เช็กลิสต์จัดกระเป๋าเดินทาง',
                          'Packing Checklist'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF134E3A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF134E3A).withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${appState.packingList.where((i) => i.isPacked).length}/${appState.packingList.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF134E3A),
                        ),
                      ),
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact),
                            icon: const Text('➕', style: TextStyle(fontSize: 12)),
                            label: Text(tr(context, 'เพิ่มของ', 'Add Item')),
                            onPressed: () => _showAddPackingDialog(context),
                          ),
                        ),
                        for (final item in appState.packingList)
                          CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              item.title,
                              style: TextStyle(
                                decoration: item.isPacked
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                color: item.isPacked
                                    ? Colors.grey
                                    : Colors.black87,
                              ),
                            ),
                            subtitle: Text(item.category,
                                style: const TextStyle(fontSize: 10)),
                            value: item.isPacked,
                            onChanged: (_) =>
                                appState.togglePackingItem(item.id),
                            secondary: IconButton(
                              icon: const Text('🗑️', style: TextStyle(fontSize: 16)),
                              onPressed: () =>
                                  appState.deletePackingItem(item.id),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Reorderable Trip Places Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                const Text('📋', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  tr(context, 'ลำดับสถานที่ในแผนเที่ยว', 'Itinerary Places Order'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF134E3A),
                  ),
                ),
              ],
            ),
          ),

          // Reorderable List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: places.length,
            itemBuilder: (context, index) {
              final p = places[index];
              return Card(
                key: ValueKey(p.id),
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF134E3A),
                    foregroundColor: Colors.white,
                    radius: 14,
                    child: Text('${index + 1}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(p.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF134E3A))),
                  subtitle: Text(
                      '${p.province} · ใช้เวลา ~${durText(p.avgDurationMin)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: tr(context, 'ลบออกจากแผน', 'Remove'),
                        icon: const Text('❌', style: TextStyle(fontSize: 16)),
                        onPressed: () => appState.togglePlaceSelection(p.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _budgetItem({
    required String icon,
    required String label,
    required String value,
    bool isHighlight = false,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: isHighlight ? const Color(0xFF134E3A) : Colors.black87,
          ),
        ),
      ],
    );
  }
}
