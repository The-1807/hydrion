import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

enum HydrationReportExportResult { completed, dismissed, unavailable }

abstract class HydrationReportExporter {
  Future<HydrationReportExportResult> export(Uint8List bytes);
}

class PlatformHydrationReportExporter implements HydrationReportExporter {
  const PlatformHydrationReportExporter();

  @override
  Future<HydrationReportExportResult> export(Uint8List bytes) async {
    final result = await Share.shareXFiles(
      [
        XFile.fromData(bytes,
            mimeType: 'application/pdf', name: 'hydrion-report.pdf')
      ],
      subject: 'Hydrion hydration report',
    );
    return switch (result.status) {
      ShareResultStatus.success => HydrationReportExportResult.completed,
      ShareResultStatus.dismissed => HydrationReportExportResult.dismissed,
      ShareResultStatus.unavailable => HydrationReportExportResult.unavailable,
    };
  }
}
