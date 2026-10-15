import 'package:flutter/material.dart';
import '../services/app_state.dart';
import 'shared_plan_detail_screen.dart';

class SharedPlansScreen extends StatelessWidget {
  const SharedPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final plans = appState.sharedPlans;
    final placesMap = {for (final p in appState.places) p.id: p};

    if (plans.isEmpty) {
      return const Center(child: Text('ยังไม่มีแผนจากเพื่อน'));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      itemCount: plans.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final plan = plans[index];

        final allIds = plan.days.expand((d) => d).toList();
        final provinces = <String>{};
        for (final id in allIds) {
          final p = placesMap[id];
          if (p != null) {
            provinces.add(p.province);
          }
        }
        final provinceStr = provinces.join(', ');

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SharedPlanDetailScreen(plan: plan),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          plan.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF134E3A),
                          ),
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => appState.toggleLikeSharedPlan(plan.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.favorite_rounded,
                                size: 16,
                                color: Colors.redAccent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${plan.likes}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor:
                            const Color(0xFF134E3A).withAlpha(38),
                        child: const Icon(Icons.person,
                            size: 12, color: Color(0xFF134E3A)),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        plan.authorName,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (plan.description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      plan.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey[800], height: 1.3),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Chip(
                        avatar:
                            const Icon(Icons.calendar_today_rounded, size: 13),
                        label: Text('${plan.days.length} วัน'),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Colors.grey[100],
                        side: BorderSide.none,
                      ),
                      Chip(
                        avatar: const Icon(Icons.place_rounded, size: 13),
                        label: Text('${allIds.length} สถานที่'),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Colors.grey[100],
                        side: BorderSide.none,
                      ),
                      if (provinceStr.isNotEmpty)
                        Chip(
                          avatar: const Icon(Icons.map_rounded, size: 13),
                          label: Text(provinceStr),
                          visualDensity: VisualDensity.compact,
                          backgroundColor:
                              const Color(0xFF134E3A).withAlpha(30),
                          side: BorderSide.none,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
