import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_expense_tracker/core/widgets/custom_button.dart';
import 'package:personal_expense_tracker/core/widgets/empty_state_view.dart';

void main() {
  group('CustomButton Widget Tests', () {
    testWidgets('renders button text and triggers onPressed callback', (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Save Transaction',
              onPressed: () {
                pressed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Save Transaction'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      await tester.tap(find.text('Save Transaction'));
      await tester.pump();

      expect(pressed, true);
    });

    testWidgets('shows loading indicator and disables tap when isLoading is true', (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Submit',
              isLoading: true,
              onPressed: () {
                pressed = true;
              },
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit'), findsNothing);

      await tester.tap(find.byType(CustomButton));
      await tester.pump();

      expect(pressed, false);
    });
  });

  group('EmptyStateView Widget Tests', () {
    testWidgets('renders title, description, and action button', (WidgetTester tester) async {
      bool actionPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateView(
              icon: Icons.receipt_long,
              title: 'No Transactions Found',
              description: 'Add your first transaction to get started',
              actionText: 'Add Expense',
              onAction: () {
                actionPressed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('No Transactions Found'), findsOneWidget);
      expect(find.text('Add your first transaction to get started'), findsOneWidget);
      expect(find.text('Add Expense'), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long), findsOneWidget);

      await tester.tap(find.text('Add Expense'));
      await tester.pump();

      expect(actionPressed, true);
    });
  });
}
