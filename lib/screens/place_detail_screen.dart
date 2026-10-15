import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/place.dart';
import '../services/app_state.dart';

String durText(int m) {
  final h = m ~/ 60;
  final r = m % 60;
  if (h == 0) return '$r นาที';
  return r == 0 ? '$h ชม.' : '$h ชม. $r นาที';
}

String categoryToThai(String cat) {
  switch (cat) {
    case 'temple':
      return 'วัด/ศาสนสถาน';
    case 'nature':
      return 'ธรรมชาติ';
    case 'beach':
      return 'ทะเล/หาด';
    case 'history':
      return 'ประวัติศาสตร์';
    case 'market':
      return 'ตลาด/ช้อปปิ้ง';
    case 'cafe':
      return 'คาเฟ่';
    default:
      return cat;
  }
}

class PlaceDetailScreen extends StatelessWidget {
  final Place place;

  const PlaceDetailScreen({super.key, required this.place});

  Future<void> _openMaps(BuildContext context, {String? queryOverride}) async {
    final query = queryOverride ?? '${place.lat},${place.lng}';
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่สามารถเปิด Google Maps ได้')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการเปิดแผนที่: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = AppStateProvider.of(context);
    final isSelected = appState.selectedPlaceIds.contains(place.id);
    final isFavorite = appState.favoritePlaceIds.contains(place.id);

    final openHoursText = (place.open != null &&
            place.open!.isNotEmpty &&
            place.close != null &&
            place.close!.isNotEmpty)
        ? '${place.open} - ${place.close} น.'
        : 'ยังไม่มีข้อมูล';

    final feeText = (place.fee != null && place.fee!.isNotEmpty)
        ? place.fee!
        : 'ยังไม่มีข้อมูล';

    return Scaffold(
      appBar: AppBar(
        title: Text(place.name),
        actions: [
          IconButton(
            tooltip: isFavorite ? 'เอาออกจากรายการโปรด' : 'เพิ่มในรายการโปรด',
            icon: Icon(
              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFavorite ? Colors.redAccent : Colors.white,
            ),
            onPressed: () {
              appState.toggleFavorite(place.id);
            },
          ),
          IconButton(
            tooltip: isSelected ? 'เอาออกจากแผน' : 'เพิ่มลงแผน',
            icon: Icon(
              isSelected ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: isSelected ? const Color(0xFFE5A93C) : Colors.white,
            ),
            onPressed: () {
              appState.togglePlaceSelection(place.id);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image Header
            Stack(
              children: [
                Image.network(
                  place.effectiveImageUrl,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 220,
                    color: const Color(0xFF134E3A).withAlpha(40),
                    child: const Center(
                      child: Icon(Icons.photo, size: 64, color: Colors.grey),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(180),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${place.rating.toStringAsFixed(1)} (${place.reviewCount} รีวิว)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Location
                  Text(
                    place.name,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF134E3A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${place.province} · ภาค${place.region}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Chips: Category & Verification
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.category, size: 18),
                        label: Text(categoryToThai(place.category)),
                        backgroundColor: const Color(0xFF134E3A).withAlpha(20),
                        side: BorderSide.none,
                      ),
                      if (!place.verified)
                        const Chip(
                          avatar: Icon(Icons.warning_amber_rounded,
                              size: 18, color: Colors.amber),
                          label: Text('ข้อมูลยังไม่ได้ตรวจสอบ'),
                          backgroundColor: Color(0xFFFFF8E1),
                          side: BorderSide(color: Colors.amber),
                        )
                      else
                        const Chip(
                          avatar:
                              Icon(Icons.verified, size: 18, color: Colors.green),
                          label: Text('ข้อมูลผ่านการตรวจสอบ'),
                          backgroundColor: Color(0xFFE8F5E9),
                          side: BorderSide(color: Colors.green),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Description Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'รายละเอียด',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF134E3A),
                            ),
                          ),
                          const Divider(height: 16),
                          Text(
                            place.description,
                            style:
                                theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Information Grid / Cards
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _infoRow(
                            icon: Icons.access_time,
                            label: 'เวลาเปิด-ปิด',
                            value: openHoursText,
                          ),
                          const Divider(),
                          _infoRow(
                            icon: Icons.payments_outlined,
                            label: 'ค่าเข้าชม',
                            value: feeText,
                          ),
                          const Divider(),
                          _infoRow(
                            icon: Icons.timer_outlined,
                            label: 'เวลาที่ควรใช้',
                            value: '~${durText(place.avgDurationMin)}',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nearby Hotels & Restaurants Recommendation Card
                  Card(
                    color: const Color(0xFFFFFDF6),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.restaurant_rounded,
                                  color: Color(0xFF134E3A)),
                              SizedBox(width: 8),
                              Text(
                                'แนะนำที่พัก & ร้านอาหารใกล้เคียง',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF134E3A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ค้นหาร้านเด็ดและโรงแรมบรรยากาศดีบริเวณใกล้ ${place.name}',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    side: const BorderSide(
                                        color: Color(0xFF134E3A)),
                                  ),
                                  icon: const Icon(Icons.restaurant, size: 16),
                                  label: const Text('ร้านอาหารใกล้เคียง',
                                      style: TextStyle(fontSize: 12)),
                                  onPressed: () => _openMaps(
                                    context,
                                    queryOverride:
                                        'ร้านอาหาร คาเฟ่ ใกล้ ${place.name}',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    side: const BorderSide(
                                        color: Color(0xFF134E3A)),
                                  ),
                                  icon: const Icon(Icons.hotel, size: 16),
                                  label: const Text('ที่พักใกล้เคียง',
                                      style: TextStyle(fontSize: 12)),
                                  onPressed: () => _openMaps(
                                    context,
                                    queryOverride:
                                        'โรงแรม ที่พัก ใกล้ ${place.name}',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Google Maps Navigation Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(
                            color: Color(0xFF134E3A), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.navigation_outlined,
                          color: Color(0xFF134E3A)),
                      label: const Text(
                        'เปิดนำทางใน Google Maps',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF134E3A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => _openMaps(context),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Add / Remove from plan action button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected
                            ? Colors.red[700]
                            : const Color(0xFF134E3A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(
                        isSelected
                            ? Icons.remove_circle_outline
                            : Icons.add_circle_outline,
                      ),
                      label: Text(
                        isSelected ? 'เอาออกจากแผนเที่ยว' : 'เพิ่มลงแผนเที่ยว',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        appState.togglePlaceSelection(place.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isSelected
                                  ? 'เอา ${place.name} ออกจากแผนเที่ยวแล้ว'
                                  : 'เพิ่ม ${place.name} ลงในแผนเที่ยวแล้ว',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF134E3A)),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const Spacer(),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 15,
                color: value == 'ยังไม่มีข้อมูล'
                    ? Colors.grey[600]
                    : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
