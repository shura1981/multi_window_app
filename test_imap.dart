import 'package:enough_mail/enough_mail.dart';

void main() {
  final client = ImapClient(isLogEnabled: false);
  final b = SearchQueryBuilder.unseen();
  print(b);
}
