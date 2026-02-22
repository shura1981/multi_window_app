import 'package:flutter/material.dart';
import 'email_model.dart';
import 'email_service.dart';
import 'email_detail_view.dart';

class EmailView extends StatefulWidget {
  final EmailService emailService;

  const EmailView({super.key, required this.emailService});

  @override
  State<EmailView> createState() => _EmailViewState();
}

class _EmailViewState extends State<EmailView> {
  late Future<List<EmailModel>> _emailsFuture;
  EmailModel? _selectedEmail;

  @override
  void initState() {
    super.initState();
    _loadEmails();
  }

  void _loadEmails() {
    setState(() {
      _selectedEmail = null;
      _emailsFuture = widget.emailService.getUnreadEmails();
    });
  }

  void _handleRowTap(EmailModel email) {
    setState(() {
      _selectedEmail = email;
    });
  }
  @override
  Widget build(BuildContext context) {
    if (_selectedEmail != null) {
      return EmailDetailView(
        email: _selectedEmail!,
        emailService: widget.emailService,
        onBack: () => setState(() => _selectedEmail = null),
      );
    }

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
