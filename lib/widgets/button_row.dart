import 'package:flutter/material.dart';

class ButtonRow extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onGetImage;
  final VoidCallback onSelectFromList;

  const ButtonRow({
    super.key,
    required this.isLoading,
    required this.onGetImage,
    required this.onSelectFromList,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: isLoading ? null : onGetImage,
          child: const Text('Tag billede'),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: isLoading ? null : onSelectFromList,
          child: const Text('Vælg fra liste'),
        ),
      ],
    );
  }
}