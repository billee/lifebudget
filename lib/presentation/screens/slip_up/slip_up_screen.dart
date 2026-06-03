import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/slip_up_model.dart';
import '../../providers/slip_up_provider.dart';

class SlipUpScreen extends ConsumerStatefulWidget {
  const SlipUpScreen({super.key});

  @override
  ConsumerState<SlipUpScreen> createState() => _SlipUpScreenState();
}

class _SlipUpScreenState extends ConsumerState<SlipUpScreen> {
  final _amountController = TextEditingController();
  String _mood = 'okay';
  final _noteController = TextEditingController();
  bool _submitted = false;
  String _responseMessage = '';

  final Map<String, String> _moodEmojis = {
    'stressed': '😰',
    'guilty': '😞',
    'okay': '😐',
    'hopeful': '🙂',
  };

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);

    final slipUp = SlipUp(
      date: DateTime.now(),
      amount: amount,
      mood: _mood,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    final repo = ref.read(slipUpRepositoryProvider);
    await repo.insert(slipUp);
    ref.invalidate(recentSlipUpsProvider);
    ref.invalidate(daysSinceLastSlipUpProvider);

    // Generate compassionate response
    String response;
    if (amount != null && amount > 0) {
      response =
          "That's okay. ₱${amount.toStringAsFixed(0)} over plan isn't the end. "
          "Tomorrow is a fresh page. Want to try a no-spend morning?";
    } else {
      response =
          "We all have rough days. The fact that you're here shows you care. "
          "Let's just focus on the next right step.";
    }

    if (_mood == 'stressed' || _mood == 'guilty') {
      response +=
          "\n\nYou're not alone in this. One slip doesn't undo your progress.";
    }

    setState(() {
      _submitted = true;
      _responseMessage = response;
    });
  }

  void _reset() {
    setState(() {
      _submitted = false;
      _responseMessage = '';
    });
    _amountController.clear();
    _noteController.clear();
    setState(() => _mood = 'okay');
  }

  @override
  Widget build(BuildContext context) {
    final slipUpsAsync = ref.watch(recentSlipUpsProvider);

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('I Slipped Up', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _submitted ? _buildResponse(slipUpsAsync) : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("It happens. No judgment here.",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text("Tell us what happened, if you want.",
            style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 24),

        // Amount (optional)
        const Text("How much went off plan? (optional)"),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '0',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 24),

        // Mood
        const Text("How are you feeling?"),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: _moodEmojis.entries.map((entry) {
            return ChoiceChip(
              label: Text('${entry.value} ${entry.key}'),
              selected: _mood == entry.key,
              onSelected: (selected) {
                setState(() => _mood = entry.key);
              },
              selectedColor: AppColors.primary.withOpacity(0.2),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Note
        TextField(
          controller: _noteController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'What happened? (optional)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('I slipped up — I want to move forward',
                style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildResponse(AsyncValue<List<SlipUp>> slipUpsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.heart_broken, size: 64, color: AppColors.primary),
        const SizedBox(height: 24),
        Text(
          _responseMessage,
          style: const TextStyle(fontSize: 18, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextButton(
          onPressed: _reset,
          child: const Text('Log another slip-up?'),
        ),
        const SizedBox(height: 40),
        const Divider(),
        const SizedBox(height: 16),
        const Text(
          'Your past slip-ups',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        slipUpsAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (err, stack) => Text('Could not load history'),
          data: (slipUps) {
            if (slipUps.isEmpty) {
              return const Text('None yet — this is your first one.',
                  style: TextStyle(color: AppColors.textSecondary));
            }
            return Column(
              children: slipUps.map((s) {
                final emoji = _moodEmojis[s.mood] ?? '😶';
                final dateStr =
                    '${s.date.month}/${s.date.day} ${s.date.hour}:${s.date.minute.toString().padLeft(2, '0')}';
                final amountStr = s.amount != null
                    ? ' - ₱${s.amount!.toStringAsFixed(0)}'
                    : '';
                return ListTile(
                  leading: Text(emoji, style: const TextStyle(fontSize: 24)),
                  title: Text('$dateStr$amountStr'),
                  subtitle: s.note != null ? Text(s.note!) : null,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
