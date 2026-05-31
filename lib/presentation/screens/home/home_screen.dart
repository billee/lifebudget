import 'package:flutter/material.dart';
import 'health_ring_widget.dart';
import 'jar_row_widget.dart';
import 'focus_card_widget.dart';
import 'home_header.dart';
import 'daily_allowance_card.dart'; // <-- NEW import

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            // Pulse Bar
            HomeHeader(),
            SizedBox(height: 24),

            // Health Ring
            HealthRingWidget(),
            SizedBox(height: 16),

            // Daily "safe to spend" card
            DailyAllowanceCard(
              dailyAllowance: 4200 / 14, // mock: remaining ÷ days left
              daysLeft: 14,
            ),
            SizedBox(height: 16),

            // Jars Row
            JarRowWidget(),
            SizedBox(height: 24),

            // Focus Card
            FocusCardWidget(),
            SizedBox(height: 100), // space for FAB and bottom nav
          ],
        ),
      ),
    );
  }
}
