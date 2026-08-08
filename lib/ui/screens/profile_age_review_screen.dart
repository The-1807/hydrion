import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/life_stage_policy.dart';
import '../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final age = int.tryParse(_ageController.text.trim());
    if (!HydrionLifeStagePolicy.canCreateIndependentProfile(age)) {
      setState(() => _error = l10n.ageRangeError);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final repository = context.read<UserSettingsRepository>();
    final saved = await repository.setProfile(
      nickname: repository.settings.nickname ?? 'Hydrion',
      age: age,
      sex: repository.settings.sex,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved) {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    } else {
      setState(() => _error = l10n.ageSaveFailed);
    }
  }

  Future<void> _deleteProfile() async {
    if (_saving) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: Text(l10n.deleteLocalProfileQuestion),
          content: Text(l10n.profileDeleteDeviceSummary),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.deleteLocalProfile),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    await context.read<LocalProfileResetService>().resetLocalProfile();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/onboarding', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.reviewProfileAge)),
      body: SafeArea(
        child: ListView(
          padding: HydrionViewport.scrollPadding(context),
          children: [
            Text(
              l10n.independentProfileAgeHelp,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(l10n.ageReviewExistingDataHelp),
            const SizedBox(height: 20),
            TextField(
              key: const Key('profile-age-correction'),
              controller: _ageController,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.correctAge,
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
                  : Text(l10n.saveAgeCorrection),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('delete-unsupported-profile'),
              onPressed: _saving ? null : _deleteProfile,
              child: Text(l10n.deleteLocalProfile),
            ),
          ],
        ),
      ),
    );
  }
}
