import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class HomeShimmer extends StatelessWidget {
  const HomeShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Carrinho button simulation
                  Container(
                    width: 120,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Total simulation
                  Container(
                    width: 150,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Items count simulation
                  Container(
                    width: 100,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 12),
            sliver: SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 150,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              crossAxisCount: 2,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 80,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
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
}
