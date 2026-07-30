import 'package:flutter/material.dart';

class CustomTargetDialog extends StatefulWidget {
  const CustomTargetDialog({
    required this.currentTarget,
    required this.onSubmit,
    super.key,
  });

  final int currentTarget;
  final bool Function(String value) onSubmit;

  @override
  State<CustomTargetDialog> createState() => _CustomTargetDialogState();
}

class _CustomTargetDialogState extends State<CustomTargetDialog> {
  late final TextEditingController _controller;
  String? _errorText;

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
      return;
    }

    setState(() {
      _errorText = 'Enter a target greater than zero.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set custom target'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(labelText: 'Target', errorText: _errorText),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
