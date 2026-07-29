import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/life_stage_policy.dart';
import '../../repositories/settings_repository.dart';
import '../../services/local_profile_reset_service.dart';
import '../components/hydrion_viewport.dart';

class ProfileAgeReviewScreen extends StatefulWidget {
  const ProfileAgeReviewScreen({super.key});

  @override
  State<ProfileAgeReviewScreen> createState() => _ProfileAgeReviewScreenState();
}

class _ProfileAgeReviewScreenState extends State<ProfileAgeReviewScreen> {
  final _ageController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _correctAge() async {
    if (_saving) return;
    final age = int.tryParse(_ageController.text.trim());
    if (!HydrionLifeStagePolicy.canCreateIndependentProfile(age)) {
      setState(() => _error = 'Enter an age from 13 to 120.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final repository = context.read<UserSettingsRepository>();
    final saved = await repository.setProfile(
      nickname: repository.settings.nickname ?? 'Hydrion user',
      age: age,
      sex: repository.settings.sex,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved) {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    } else {
      setState(() => _error = 'The age could not be saved. Try again.');
    }
  }

  Future<void> _deleteProfile() async {
    if (_saving) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete local profile?'),
        content: const Text(
          'This removes local Hydrion profile, hydration, reminder, and challenge data from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete local profile'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    await context.read<LocalProfileResetService>().resetLocalProfile();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/onboarding', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review profile age')),
      body: SafeArea(
        child: ListView(
          padding: HydrionViewport.scrollPadding(context),
          children: [
            Text(
              'Hydrion independent profiles support ages 13 and older.',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              'Your existing local data is still here. If the saved age was entered incorrectly, correct it once below. Otherwise, delete the local profile and restart.',
            ),
            const SizedBox(height: 20),
            TextField(
              key: const Key('profile-age-correction'),
              controller: _ageController,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Correct age',
                errorText: _error,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('save-profile-age-correction'),
              onPressed: _saving ? null : _correctAge,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save age correction'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('delete-unsupported-profile'),
              onPressed: _saving ? null : _deleteProfile,
              child: const Text('Delete local profile'),
            ),
          ],
        ),
      ),
    );
  }
}
