import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';

class DefaultTargetSheet extends StatefulWidget {
  const DefaultTargetSheet({
    required this.currentTarget,
    required this.onSubmit,
    super.key,
  });

  final int currentTarget;
  final bool Function(String value) onSubmit;

  @override
  State<DefaultTargetSheet> createState() => _DefaultTargetSheetState();
}

class _DefaultTargetSheetState extends State<DefaultTargetSheet> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.currentTarget}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.onSubmit(_controller.text)) {
      Navigator.of(context).pop();
    } else {
      setState(() => _error = 'Enter a target greater than zero.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Default Target', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Target',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              child: const Text('Save Target'),
            ),
          ),
        ],
      ),
    );
  }
}

class ImportBackupSheet extends StatefulWidget {
  const ImportBackupSheet({required this.onSubmit, super.key});

  final Future<String?> Function(String value) onSubmit;

  @override
  State<ImportBackupSheet> createState() => _ImportBackupSheetState();
}

class _ImportBackupSheetState extends State<ImportBackupSheet> {
  final _controller = TextEditingController();
  String? _error;
  bool _isImporting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _isImporting = true;
    });
    final error = await widget.onSubmit(_controller.text);
    if (!mounted) {
      return;
    }
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _error = error;
      _isImporting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Import Backup', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Paste the JSON backup exported by Tasbeeh Tracker.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            minLines: 5,
            maxLines: 9,
            enabled: !_isImporting,
            decoration: InputDecoration(
              hintText: '{ "schemaVersion": 1, ... }',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isImporting ? null : _submit,
              child: _isImporting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Import Backup'),
            ),
          ),
        ],
      ),
    );
  }
}
