import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

/// Ouvre un PDF localement ou propose le partage natif si aucun lecteur n'est disponible.
Future<void> openOrSharePdf(
  String path, {
  String subject = 'Relevé mensuel FONACO',
}) async {
  final result = await OpenFile.open(path);
  if (result.type != ResultType.done) {
    await Share.shareXFiles(
      [XFile(path)],
      subject: subject,
      text: subject,
    );
  }
}
