import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n.dart';
import '../../../state/providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../identity_service.dart';
import '../pairing_request.dart';

enum _Step { review, pin, done }

/// The approval card shown on the device that receives a pairing request.
/// Approval always requires the local PIN; the PIN is never transmitted.
class PairingApprovalDialog extends ConsumerStatefulWidget {
  const PairingApprovalDialog({super.key, required this.request});

  final PairingRequest request;

  @override
  ConsumerState<PairingApprovalDialog> createState() => _PairingApprovalDialogState();
}

class _PairingApprovalDialogState extends ConsumerState<PairingApprovalDialog> {
  final _pin = TextEditingController();
  _Step _step = _Step.review;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _approve() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(syncServiceProvider).approvePairingRequest(widget.request.id, _pin.text.trim());
      if (!mounted) return;
      setState(() {
        _step = _Step.done;
        _busy = false;
      });
    } on IdentityException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.message;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '$error';
      });
    }
  }

  void _reject() {
    ref.read(syncServiceProvider).rejectPairingRequest(widget.request.id);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mc;
    final request = widget.request;
    if (_step == _Step.done) {
      return AlertDialog(
        icon: Icon(Icons.check_circle_outline, color: c.success, size: 40),
        title: Text(l10n.pairingApproved),
        content: Text(l10n.pairingApprovedHint(request.deviceName)),
        actions: [FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.close))],
      );
    }

    return AlertDialog(
      icon: Icon(Icons.link, color: c.accent, size: 36),
      title: Text(l10n.pairingRequestTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.pairingRequestBody(request.deviceName, request.username)),
            const SizedBox(height: 14),
            Text(l10n.pairingRequestCode, style: SundialType.label(11, color: c.textTertiary)),
            const SizedBox(height: 4),
            Text(request.displayCode, style: SundialType.title(30, color: c.text).copyWith(letterSpacing: 4)),
            const SizedBox(height: 4),
            Text(l10n.pairingRequestCodeHint, style: SundialType.body(12, color: c.textSecondary)),
            const SizedBox(height: 12),
            Text(
              '${l10n.pairingRequestFingerprint}: ${shortFingerprint(request.certificateFingerprint)}',
              style: SundialType.body(11.5, color: c.textSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              request.datasetMatches ? l10n.pairingPlanSame : l10n.pairingPlanDifferent,
              style: SundialType.body(11.5, color: request.datasetMatches ? c.textSecondary : c.warning),
            ),
            if (_step == _Step.pin) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _pin,
                autofocus: true,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.pin, helperText: l10n.pairingApprovePinHint),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _busy ? null : _approve(),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: SundialType.body(12, color: c.danger)),
            ],
          ],
        ),
      ),
      actions: _step == _Step.review
          ? [
              TextButton(onPressed: _busy ? null : _reject, child: Text(l10n.reject)),
              FilledButton(
                onPressed: _busy ? null : () => setState(() => _step = _Step.pin),
                child: Text(l10n.approve),
              ),
            ]
          : [
              TextButton(
                onPressed: _busy ? null : () => setState(() => _step = _Step.review),
                child: Text(l10n.back),
              ),
              FilledButton(
                onPressed: _busy || _pin.text.trim().length < 4 ? null : _approve,
                child: _busy
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l10n.approve),
              ),
            ],
    );
  }
}
