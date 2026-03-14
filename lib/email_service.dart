import 'dart:io';
import 'package:enough_mail/enough_mail.dart';
import 'package:path_provider/path_provider.dart';
import 'email_model.dart';
import 'package:path/path.dart' as p;

class EmailService {
  final String host;
  final int port;
  final String username;
  final String password;
  final bool secure;

  EmailService({
    required this.host,
    this.port = 993,
    required this.username,
    required this.password,
    this.secure = true,
  });

  /// Connects to the IMAP server and fetches UNSEEN emails.
  Future<List<EmailModel>> getUnreadEmails() async {
    final client = ImapClient(isLogEnabled: false);
    
    try {
      await client.connectToServer(host, port, isSecure: secure);
      await client.login(username, password);

      await client.selectInbox();
      
      // Fetch unseen messages' IDs via SEARCH
      final searchResult = await client.searchMessages(searchCriteria: 'UNSEEN');
      
      final List<EmailModel> emails = [];
      if (searchResult.matchingSequence != null) {
        // Fetch up to 50 recent unseen messages from the matched sequence
        final sequence = searchResult.matchingSequence!;
        
        final fetchResult = await client.fetchMessages(
          sequence,
          '(FLAGS ENVELOPE BODY.PEEK[])'
        );

        int currentId = 1;
        for (final message in fetchResult.messages) {
          // Collect attachment names
          List<String> attachmentNames = [];
          if (message.hasAttachments()) {
            for (final part in message.parts!) {
              final fileName = part.decodeFileName();
              if (fileName != null) {
                attachmentNames.add(fileName);
              }
            }
          }

          emails.add(EmailModel(
            id: currentId++,
            sender: message.fromEmail ?? message.from?.first.email ?? 'Unknown',
            subject: message.decodeSubject() ?? 'No Subject',
            date: message.decodeDate() ?? DateTime.now(),
            attachmentNames: attachmentNames,
            originalMessage: message,
          ));
        }
      }

      await client.logout();
      return emails.reversed.toList(); // most recent first

    } on ImapException catch (e) {
      print('IMAP Error: $e');
      rethrow;
    } catch (e) {
      print('Error connecting/fetching emails: $e');
      rethrow;
    } finally {
      if (client.isLoggedIn) {
         try {
           await client.logout();
         } catch (_) {}
      }
    }
  }

  /// Downloads PDF and Image (.pdf, .jpg, .png) attachments from a given message
  Future<List<String>> downloadAttachments(MimeMessage message) async {
    if (!message.hasAttachments() || message.parts == null) return [];

    final Directory docDir = await getApplicationDocumentsDirectory();
    final String baseEmailDir = p.join(docDir.path, 'SavedAttachments', message.decodeSubject()?.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_') ?? 'Email_${DateTime.now().millisecondsSinceEpoch}');
    
    final dir = Directory(baseEmailDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    List<String> savedPaths = [];

    for (final part in message.parts!) {
      final fileNameDecoded = part.decodeFileName();
      if (fileNameDecoded != null) {
        String fileName = fileNameDecoded.toLowerCase();
        
        // Filter by PDF or Image
        if (fileName.endsWith('.pdf') || fileName.endsWith('.jpg') || fileName.endsWith('.jpeg') || fileName.endsWith('.png')) {
          final fileData = part.decodeContentBinary();
          if (fileData != null) {
            final File file = File(p.join(dir.path, fileNameDecoded));
            await file.writeAsBytes(fileData);
            savedPaths.add(file.path);
          }
        }
      }
    }

    return savedPaths;
  }
}
