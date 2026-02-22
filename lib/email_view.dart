import 'package:flutter/material.dart';
import 'package:enough_mail/enough_mail.dart';
import 'email_model.dart';
import 'email_service.dart';

class EmailView extends StatefulWidget {
  final EmailService emailService;

  const EmailView({super.key, required this.emailService});

  @override
  State<EmailView> createState() => _EmailViewState();
}

class _EmailViewState extends State<EmailView> {
  late Future<List<EmailModel>> _emailsFuture;

  @override
  void initState() {
    super.initState();
    _loadEmails();
  }

  void _loadEmails() {
    setState(() {
      _emailsFuture = widget.emailService.getUnreadEmails();
    });
  }

  void _handleRowTap(EmailModel email) async {
    if (email.hasAttachments) {
      try {
        final paths = await widget.emailService.downloadAttachments(email.originalMessage);
        if (paths.isNotEmpty) {
           print('=================================');
           print('Attachments downloaded for "${email.subject}":');
           for (var path in paths) {
             print(' -> $path');
           }
           print('=================================');
           
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Descargados ${paths.length} adjuntos en SavedAttachments')),
             );
           }
        } else {
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('No se encontraron PDFs ni Imágenes válidas')),
             );
           }
        }
      } catch (e) {
         if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Error al descargar: $e'), backgroundColor: Colors.red),
             );
         }
      }
    } else {
      print('El correo "${email.subject}" no tiene archivos adjuntos.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.all(8),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Text('Unread Emails (cPanel IMAP)', style: theme.textTheme.titleMedium),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
                onPressed: _loadEmails,
              ),
            ],
          ),
        ),
        
        // Data Table
        Expanded(
          child: FutureBuilder<List<EmailModel>>(
            future: _emailsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error connecting to IMAP server:\n${snapshot.error}',
                    style: TextStyle(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              final emails = snapshot.data ?? [];

              if (emails.isEmpty) {
                return const Center(child: Text('No unread emails found.'));
              }

              return SingleChildScrollView(
                child: SizedBox(
                   width: double.infinity,
                   child: DataTable(
                     showCheckboxColumn: false,
                     columns: const [
                       DataColumn(label: Text('Remitente')),
                       DataColumn(label: Text('Asunto')),
                       DataColumn(label: Text('Fecha')),
                       DataColumn(label: Text('Adjuntos')),
                     ],
                     rows: emails.map((email) {
                       return DataRow(
                         onSelectChanged: (_) => _handleRowTap(email),
                         cells: [
                           DataCell(Text(email.sender)),
                           DataCell(Text(email.subject, overflow: TextOverflow.ellipsis)),
                           DataCell(Text(
                             "${email.date.year}-${email.date.month.toString().padLeft(2, '0')}-${email.date.day.toString().padLeft(2, '0')} ${email.date.hour.toString().padLeft(2, '0')}:${email.date.minute.toString().padLeft(2, '0')}"
                           )),
                           DataCell(
                             email.hasAttachments 
                               ? Tooltip(
                                   message: email.attachmentNames.join(', '), 
                                   child: Icon(Icons.attachment, color: theme.colorScheme.primary)
                                 )
                               : const SizedBox(),
                           ),
                         ],
                       );
                     }).toList(),
                   ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
