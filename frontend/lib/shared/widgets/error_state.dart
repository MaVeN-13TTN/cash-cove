import 'package:flutter/material.dart';

class ErrorState extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback? onRetry;

  const ErrorState({
    Key? key,
    required this.title,
    required this.description,
    this.onRetry,
  }) : super(key: key);

  factory ErrorState.fromMessage({
    Key? key,
    required String message,
    VoidCallback? onRetry,
  }) {
    return ErrorState(
      key: key,
      title: 'Error Occurred',
      description: message,
      onRetry: onRetry,
    );
  }

  const ErrorState.message({
    Key? key,
    required String message,
    VoidCallback? onRetry,
  }) : this(
    key: key,
    title: 'Error Occurred',
    description: message,
    onRetry: onRetry,
  );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}
