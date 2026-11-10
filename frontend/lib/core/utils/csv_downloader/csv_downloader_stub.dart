import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> platformExportCsv({
  required String csvContent,
  required String fileName,
  String? subject,
}) async {
  final tempDir = await getTemporaryDirectory();
  final cleanFileName = fileName.endsWith('.csv') ? fileName : '$fileName.csv';
  final file = File('${tempDir.path}/$cleanFileName');

  await file.writeAsString(csvContent);

  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'text/csv', name: cleanFileName)],
      subject: subject ?? 'Personal Expense Tracker Export',
      text: subject ?? 'Exported transaction history',
    ),
  );
}

