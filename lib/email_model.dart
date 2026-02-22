import 'package:enough_mail/enough_mail.dart';

class EmailModel {
  final int id;
  final String sender;
  final String subject;
  final DateTime date;
  final List<String> attachmentNames;
  final MimeMessage originalMessage;

  EmailModel({
    required this.id,
    required this.sender,
    required this.subject,
    required this.date,
    required this.attachmentNames,
    required this.originalMessage,
  });

  bool get hasAttachments => attachmentNames.isNotEmpty;
}
