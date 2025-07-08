import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import 'euphoric_card.dart';

class SwipeableCardSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List items;
  final Widget Function(BuildContext, dynamic) itemBuilder;

  const SwipeableCardSection({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return EuphoricCardWithBorder(
      borderColor: color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title, 
                  style: GoogleFonts.nunito(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold, 
                    color: color
                  )
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: PageView.builder(
                itemCount: items.length,
                controller: PageController(viewportFraction: 0.92),
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      child: itemBuilder(context, items[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 