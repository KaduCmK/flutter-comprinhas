import 'package:flutter/material.dart';

class SplitButton extends StatelessWidget {
  final int itemCount;
  final VoidCallback onPrimaryAction;
  final VoidCallback onSecondaryAction;

  final double edgeBorderRadiusAmount = 32;
  final double centerBorderRadiusAmount = 4;

  const SplitButton({
    super.key,
    required this.itemCount,
    required this.onPrimaryAction,
    required this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Row(
        spacing: 4,
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: onPrimaryAction,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 48,
                vertical: 16,
              ),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(edgeBorderRadiusAmount),
                  right: Radius.circular(centerBorderRadiusAmount),
                ),
              ),
              elevation: 0,
            ),
            child: Row(
              spacing: 8,
              children: [
                Icon(
                  Icons.shopping_cart,
                  color: colorScheme.onPrimary,
                  size: 32,
                ),
                Text(
                  itemCount.toString(),
                  style: textTheme.titleLarge!.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        
          ElevatedButton(
            onPressed: onSecondaryAction,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(centerBorderRadiusAmount),
                  right: Radius.circular(edgeBorderRadiusAmount),
                ),
              ),
              elevation: 0,
            ),
            child: Icon(
              Icons.shopping_cart_checkout,
              color: colorScheme.onPrimary,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}
