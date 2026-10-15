import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import '../models/place.dart';
import '../models/shared_plan.dart';
import '../services/app_state.dart';
import 'place_detail_screen.dart' show durText, PlaceDetailScreen;

class SharedPlanDetailScreen extends StatelessWidget {
  final SharedPlan plan;

  const SharedPlanDetailScreen({super.key, required this.plan});

  String _formatTime(int minutesFromMidnight) {
    final h = (minutesFromMidnight ~/ 60) % 24;
    final m = minutesFromMidnight % 60;
    final hStr = h.toString().padLeft(2, '0');
    final mStr = m.toString().padLeft(2, '0');
    return '$hStr:$mStr';
  }

  void _copyPlanSummary(BuildContext context, Map<int, Place> placesMap) {
    final sb = StringBuffer();
    sb.writeln('🗺 แผนเที่ยว: ${plan.title} (โดย ${plan.authorName})');
    sb.writeln('----------------------------------------');
    for (var dayIdx = 0; dayIdx < plan.days.length; dayIdx++) {
      sb.writeln('📅 วันที่ ${dayIdx + 1}');
      for (final id in plan.days[dayIdx]) {
        final p = placesMap[id];
        if (p != null) {
          sb.writeln('  - ${p.name} (${p.province})');
        }
      }
    }
    sb.writeln('----------------------------------------');
    sb.writeln('จากแอปไปกัน เที่ยวไทย ในแบบของคุณ');

    Clipboard.setData(ClipboardData(text: sb.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('คัดลอกสรุปแผนเที่ยวไปยัง Clipboard เรียบร้อยแล้ว!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = AppStateProvider.of(context);
    final placesMap = {for (final p in appState.places) p.id: p};

    final allPlaceIds = <int>[];
    for (final dayPlaces in plan.days) {
      allPlaceIds.addAll(dayPlaces);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(plan.title),
        actions: [
          IconButton(
            tooltip: 'คัดลอกสรุปทริป',
            icon: const Icon(Icons.copy_rounded),
            onPressed: () => _copyPlanSummary(context, placesMap),
          ),
          IconButton(
            tooltip: 'ถูกใจแผนนี้',
            icon: const Icon(Icons.favorite_border_rounded),
            onPressed: () {
              appState.toggleLikeSharedPlan(plan.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ส่งกำลังใจให้ผู้เขียนเรียบร้อยแล้ว!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF134E3A), Color(0xFF1E6C52)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF134E3A).withAlpha(75),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFFE5A93C),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded,
                          size: 16, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        'โดย ${plan.authorName}',
                        style:
                            const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const Spacer(),
                      const Icon(Icons.favorite_rounded,
                          size: 16, color: Colors.redAccent),
                      const SizedBox(width: 4),
                      Text(
                        '${plan.likes} ไลก์',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (plan.description.isNotEmpty) ...[
                    const Divider(color: Colors.white24, height: 20),
                    Text(
                      plan.description,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14, height: 1.4),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Use this plan button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF134E3A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.file_download_outlined),
                label: const Text(
                  'ใช้แผนนี้เป็นทริปของฉัน',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  appState.setPlaceSelection(allPlaceIds);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'คัดลอก ${allPlaceIds.length} สถานที่เข้าสู่แผนเที่ยวของคุณแล้ว'),
                      action: SnackBarAction(
                        label: 'ดูแผนเที่ยว',
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'ตารางการเดินทาง',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF134E3A),
              ),
            ),
            const SizedBox(height: 12),

            // Timeline per day
            for (var dayIdx = 0; dayIdx < plan.days.length; dayIdx++) ...[
              _buildDayTimeline(
                context,
                dayNumber: dayIdx + 1,
                placeIds: plan.days[dayIdx],
                placesMap: placesMap,
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDayTimeline(
    BuildContext context, {
    required int dayNumber,
    required List<int> placeIds,
    required Map<int, Place> placesMap,
  }) {
    var currentTimeMinutes = 8 * 60; // Start at 08:00 AM

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF134E3A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'วันที่ $dayNumber',
                    style: const TextStyle(
                      color: Color(0xFFE5A93C),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${placeIds.length} สถานที่)',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ],
            ),
            const Divider(height: 20),

            for (var i = 0; i < placeIds.length; i++) ...[
              () {
                final place = placesMap[placeIds[i]];
                if (place == null) {
                  return const Text('ไม่พบข้อมูลสถานที่');
                }

                final startTimeStr = _formatTime(currentTimeMinutes);
                currentTimeMinutes += place.avgDurationMin;
                final endTimeStr = _formatTime(currentTimeMinutes);

                Place? nextPlace;
                int travelMinutes = 0;
                double distKm = 0.0;

                if (i < placeIds.length - 1) {
                  nextPlace = placesMap[placeIds[i + 1]];
                  if (nextPlace != null) {
                    distKm = place.distanceKm(nextPlace);
                    travelMinutes = ((distKm / 40.0) * 60).round();
                    if (travelMinutes < 5) travelMinutes = 5;
                  }
                }

                final item = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlaceDetailScreen(place: place),
                          ),
                        );
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Place Image Thumbnail
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 54,
                              height: 54,
                              child: Image.network(
                                place.effectiveImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.photo,
                                      size: 20, color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF134E3A)
                                            .withAlpha(25),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '$startTimeStr - $endTimeStr',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          color: Color(0xFF134E3A),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '⭐ ${place.rating.toStringAsFixed(1)}',
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.amber),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  place.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF134E3A),
                                  ),
                                ),
                                Text(
                                  '${place.province} · เที่ยว ~${durText(place.avgDurationMin)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: Colors.grey),
                        ],
                      ),
                    ),
                    if (i < placeIds.length - 1) ...[
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 66, top: 6, bottom: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.directions_car_outlined,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              'เดินทาง ~${durText(travelMinutes)} (${distKm.toStringAsFixed(1)} กม.)',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      () {
                        currentTimeMinutes += travelMinutes;
                        return const SizedBox.shrink();
                      }(),
                    ],
                  ],
                );
                return item;
              }(),
            ],
          ],
        ),
      ),
    );
  }
}
