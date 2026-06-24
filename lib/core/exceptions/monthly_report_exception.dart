/// Exception levée lors d'un échec de téléchargement du relevé mensuel.
class MonthlyReportException implements Exception {
  final String message;

  MonthlyReportException(this.message);

  @override
  String toString() => message;
}
