import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../screens/transactions/log_expense_screen.dart';
import '../../screens/transactions/log_income_screen.dart';
import '../../screens/transactions/transfer_dialog.dart';
import '../../providers/budget_provider.dart';

class FabSpeedDial extends ConsumerStatefulWidget {
  /// Whether the FAB is positioned on the left half of the screen.
  /// Sub-FABs will appear to the right when true, left when false.
  final bool isOnLeftSide;

  /// Called when expanded/collapsed so parent can show dismiss overlay.
  final ValueChanged<bool>? onExpandedChanged;

  const FabSpeedDial({
    super.key,
    this.isOnLeftSide = false,
    this.onExpandedChanged,
  });

  @override
  ConsumerState<FabSpeedDial> createState() => FabSpeedDialState();
}

class FabSpeedDialState extends ConsumerState<FabSpeedDial>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _controller;
  late Animation<double> _rotate;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _rotate = Tween<double>(
      begin: 0,
      end: 0.125,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      _expanded ? _controller.forward() : _controller.reverse();
      widget.onExpandedChanged?.call(_expanded);
    });
  }

  /// Allow parent to collapse the FAB (e.g. when tapping outside).
  void collapse() {
    if (_expanded) {
      setState(() {
        _expanded = false;
        _controller.reverse();
        widget.onExpandedChanged?.call(false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // When FAB is on the left side of screen → sub-FABs go right (start alignment)
    // When FAB is on the right side of screen → sub-FABs go left (end alignment)
    final alignment =
        widget.isOnLeftSide ? CrossAxisAlignment.start : CrossAxisAlignment.end;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: [
        if (_expanded) ...[
          _MiniFAB(
            icon: Icons.edit_note_rounded,
            label: 'Log expense',
            onTap: () {
              _toggle();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LogExpenseScreen()),
              );
            },
          ),
          const SizedBox(height: 6),
          _MiniFAB(
            icon: Icons.add_rounded,
            label: 'Add income',
            onTap: () {
              _toggle();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LogIncomeScreen()),
              );
            },
          ),
          const SizedBox(height: 6),
          _MiniFAB(
            icon: Icons.swap_horiz_rounded,
            label: 'Transfer',
            onTap: () {
              _toggle();
              final budgetAsync = ref.read(budgetStateProvider);
              final categories = budgetAsync.when(
                data: (budget) =>
                    budget.expectedExpenses.map((e) => e.name).toList(),
                loading: () => <String>[],
                error: (_, __) => <String>[],
              );
              if (categories.isNotEmpty) {
                showDialog(
                  context: context,
                  builder: (ctx) => TransferDialog(categories: categories),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('No categories available for transfer')),
                );
              }
            },
          ),
          const SizedBox(height: 10),
        ],
        GestureDetector(
          onTap: _toggle,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Transform.rotate(
              angle: _rotate.value * 2 * 3.141592,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _expanded ? Icons.close : Icons.add,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniFAB extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MiniFAB(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
