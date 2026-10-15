import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../services/translations.dart';
import 'add_place_dialog.dart';
import 'place_detail_screen.dart';

const regions = ['ทั้งหมด', 'เหนือ', 'กลาง', 'ตะวันออก', 'ตะวันตก', 'อีสาน', 'ใต้'];

const categories = [
  {'key': 'ทั้งหมด', 'label': 'ทุกหมวดหมู่', 'labelEn': 'All Categories'},
  {'key': 'temple', 'label': 'วัด/ศาสนสถาน', 'labelEn': 'Temple/Shrine'},
  {'key': 'nature', 'label': 'ธรรมชาติ', 'labelEn': 'Nature/Park'},
  {'key': 'beach', 'label': 'ทะเล/หาด', 'labelEn': 'Beach/Island'},
  {'key': 'history', 'label': 'ประวัติศาสตร์', 'labelEn': 'History/Heritage'},
  {'key': 'market', 'label': 'ตลาด/ช้อปปิ้ง', 'labelEn': 'Market/Shopping'},
  {'key': 'cafe', 'label': 'คาเฟ่', 'labelEn': 'Cafe/Bakery'},
];

class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  String _region = 'ทั้งหมด';
  String _category = 'ทั้งหมด';
  String _query = '';
  bool _showFavoritesOnly = false;
  bool _freeOnly = false;
  String _sortBy = 'rating';

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final places = appState.places;
    final selected = appState.selectedPlaceIds;
    final favorites = appState.favoritePlaceIds;
    final recentSearches = appState.recentSearches;

    if (appState.isLoading && places.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final shown = places.where((p) {
      final okRegion = _region == 'ทั้งหมด' || p.region == _region;
      final okCategory = _category == 'ทั้งหมด' || p.category == _category;
      final okQuery = _query.isEmpty ||
          p.name.toLowerCase().contains(_query.toLowerCase()) ||
          p.province.toLowerCase().contains(_query.toLowerCase());
      final okFav = !_showFavoritesOnly || favorites.contains(p.id);
      final okFree = !_freeOnly ||
          (p.fee == null || p.fee!.isEmpty || p.fee!.contains('ฟรี'));
      return okRegion && okCategory && okQuery && okFav && okFree;
    }).toList();

    shown.sort((a, b) {
      switch (_sortBy) {
        case 'rating':
          return b.rating.compareTo(a.rating);
        case 'name':
          return a.name.compareTo(b.name);
        case 'duration':
          return a.avgDurationMin.compareTo(b.avgDurationMin);
        case 'reviews':
          return b.reviewCount.compareTo(a.reviewCount);
        default:
          return 0;
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF134E3A),
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Text('📍', style: TextStyle(fontSize: 16)),
        label: Text(
          tr(context, 'เพิ่มสถานที่', 'Add Place'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () => AddPlaceDialog.show(context),
      ),
      body: Column(
        children: [
          // Banner Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF134E3A).withAlpha(20),
              border: Border(
                bottom: BorderSide(
                    color: const Color(0xFF134E3A).withAlpha(25)),
              ),
            ),
            child: Row(
              children: [
                const Text('✅', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                Text(
                  '${tr(context, "เลือกแล้ว", "Selected")}: ${selected.length} ${tr(context, "แห่ง", "places")}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF134E3A),
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                FilterChip(
                  avatar: const Text('❤️', style: TextStyle(fontSize: 12)),
                  label: Text(
                      '${tr(context, "รายการโปรด", "Wishlist")} (${favorites.length})'),
                  selected: _showFavoritesOnly,
                  selectedColor: Colors.red.shade100,
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                  onSelected: (val) =>
                      setState(() => _showFavoritesOnly = val),
                ),
              ],
            ),
          ),

          // Search Field & Sort Dropdown
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('🔍', style: TextStyle(fontSize: 16)),
                      ),
                      hintText: tr(context, 'ค้นหาสถานที่ หรือจังหวัด...',
                          'Search places or provinces...'),
                      hintStyle:
                          TextStyle(color: Colors.grey[500], fontSize: 13),
                      isDense: true,
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              tooltip: tr(context, 'ล้างคำค้นหา', 'Clear Search'),
                              icon: const Text('❌', style: TextStyle(fontSize: 14)),
                              onPressed: () => setState(() => _query = ''),
                            )
                          : null,
                    ),
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        appState.addRecentSearch(val.trim());
                      }
                    },
                    onChanged: (v) => setState(() => _query = v.trim()),
                  ),
                ),
                const SizedBox(width: 8),

                // Sort Dropdown Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortBy,
                      icon: const Text('↕️', style: TextStyle(fontSize: 14)),
                      items: [
                        DropdownMenuItem(
                            value: 'rating',
                            child: Text(tr(
                                context, 'คะแนนสูงสุด', 'Highest Rating'))),
                        DropdownMenuItem(
                            value: 'name',
                            child: Text(
                                tr(context, 'ตามชื่อ (A-Z)', 'Name (A-Z)'))),
                        DropdownMenuItem(
                            value: 'duration',
                            child: Text(
                                tr(context, 'เวลาเที่ยวเร็วสุด', 'Shortest Visit'))),
                        DropdownMenuItem(
                            value: 'reviews',
                            child: Text(tr(
                                context, 'รีวิวมากสุด', 'Most Reviews'))),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _sortBy = v);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Recent Search History Chips
          if (_query.isEmpty && recentSearches.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: Row(
                children: [
                  Text(tr(context, 'ค้นหาล่าสุด:', 'Recent:'),
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey)),
                  const SizedBox(width: 6),
                  for (final item in recentSearches.take(5))
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        label: Text(item, style: const TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          setState(() => _query = item);
                        },
                      ),
                    ),
                ],
              ),
            ),

          // Region Chips & Free Toggle
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
            child: Row(
              children: [
                FilterChip(
                  avatar: const Text('🎟️', style: TextStyle(fontSize: 12)),
                  label: Text(tr(context, 'เข้าชมฟรี', 'Free Entrance')),
                  selected: _freeOnly,
                  selectedColor: Colors.green.shade100,
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                  onSelected: (val) => setState(() => _freeOnly = val),
                ),
                const SizedBox(width: 8),
                Text(tr(context, 'ภาค:', 'Region:'),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 6),
                for (final r in regions)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(r),
                      selected: _region == r,
                      selectedColor: const Color(0xFFE5A93C),
                      labelStyle: TextStyle(
                        fontWeight:
                            _region == r ? FontWeight.bold : FontWeight.normal,
                        color: _region == r
                            ? const Color(0xFF134E3A)
                            : Colors.black87,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setState(() => _region = r),
                    ),
                  ),
              ],
            ),
          ),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: Row(
              children: [
                Text(tr(context, 'หมวด:', 'Category:'),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 8),
                for (final c in categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(appState.isEnglish ? c['labelEn']! : c['label']!),
                      selected: _category == c['key'],
                      selectedColor: const Color(0xFF134E3A),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: _category == c['key']
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _category == c['key']
                            ? Colors.white
                            : Colors.black87,
                      ),
                      onSelected: (_) =>
                          setState(() => _category = c['key']!),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 10, thickness: 0.8),

          // Places List
          Expanded(
            child: shown.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔍', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 8),
                        Text(
                            tr(context, 'ไม่พบสถานที่ที่ค้นหา',
                                'No places found'),
                            style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    itemCount: shown.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final p = shown[i];
                      final on = selected.contains(p.id);
                      final isFav = favorites.contains(p.id);

                      return Card(
                        elevation: 2,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PlaceDetailScreen(place: p),
                              ),
                            );
                          },
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Thumbnail Image
                                Stack(
                                  children: [
                                    SizedBox(
                                      width: 115,
                                      height: double.infinity,
                                      child: Image.network(
                                        p.effectiveImageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Container(
                                          color: Colors.grey[200],
                                          child: const Text('📷', style: TextStyle(fontSize: 24)),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 6,
                                      left: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withAlpha(165),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          children: [
                                            const Text('⭐', style: TextStyle(fontSize: 10)),
                                            const SizedBox(width: 2),
                                            Text(
                                              p.rating.toStringAsFixed(1),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Content Details
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                p.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: Color(0xFF134E3A),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (!p.verified)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber.shade100,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  tr(context, 'ยังไม่ตรวจสอบ',
                                                      'Unverified'),
                                                  style: const TextStyle(
                                                    fontSize: 9,
                                                    color: Colors.brown,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${p.province} · ${tr(context, "ภาค", "Region")}${p.region}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          p.description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[800],
                                            height: 1.3,
                                          ),
                                        ),
                                        const Spacer(),
                                        Row(
                                          children: [
                                            const Text('⏱️', style: TextStyle(fontSize: 12)),
                                            const SizedBox(width: 4),
                                            Text(
                                              '~${durText(p.avgDurationMin)}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF134E3A),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Action Buttons
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 8),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        tooltip: isFav
                                            ? tr(context, 'เอาออกจากรายการโปรด',
                                                'Remove Wishlist')
                                            : tr(context, 'เพิ่มในรายการโปรด',
                                                'Add Wishlist'),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: Text(
                                          isFav ? '❤️' : '🤍',
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                        onPressed: () =>
                                            appState.toggleFavorite(p.id),
                                      ),
                                      IconButton(
                                        tooltip: on
                                            ? tr(context, 'เอาออกจากแผน',
                                                'Remove Plan')
                                            : tr(context, 'เพิ่มลงแผน',
                                                'Add Plan'),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: Text(
                                          on ? '🔖' : '🏷️',
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                        onPressed: () =>
                                            appState.togglePlaceSelection(p.id),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
