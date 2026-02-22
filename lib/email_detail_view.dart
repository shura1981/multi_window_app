import 'package:flutter/material.dart';
import 'email_model.dart';
import 'email_service.dart';

class EmailDetailView extends StatefulWidget {
  final EmailModel email;
  final EmailService emailService;
  final VoidCallback onBack;

  const EmailDetailView({
    super.key,
    required this.email,
    required this.emailService,
    required this.onBack,
  });

  @override
  State<EmailDetailView> createState() => _EmailDetailViewState();
}

class _EmailDetailViewState extends State<EmailDetailView> {
  bool _isDownloading = false;

  void _downloadAttachments() async {
    if (!widget.email.hasAttachments) return;

    setState(() => _isDownloading = true);

    try {
      final paths = await widget.emailService.downloadAttachments(widget.email.originalMessage);
      
      if (!mounted) return;
      
      if (paths.isNotEmpty) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Descarga Exitosa'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Se han guardado los siguientes archivos en Documentos/SavedAttachments:'),
                const SizedBox(height: 8),
                ...paths.map((p) => Text('• ${p.split('/').last}', style: const TextStyle(fontSize: 12))),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Aceptar'),
              )
            ],
          )
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontraron archivos PDF o Imágenes válidas para guardar.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al descargar: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = widget.email.originalMessage;
    
    // Attempt to extract text content
    String bodyText = message.decodeTextPlainPart() ?? '';
    if (bodyText.isEmpty) {
      bodyText = message.decodeTextHtmlPart() ?? 'El correo no contiene texto plano visible.';
      // We strip basic HTML tags if it's fallback HTML
      bodyText = bodyText.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ').trim();
    }

    // Extract image parts
    List<Widget> bodyWidgets = [];
    
    bodyWidgets.add(
      SelectableText(
        bodyText,
        style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
      ),
    );

    if (message.parts != null) {
      for (final part in message.parts!) {
        final contentType = part.mediaType;
        if (contentType.isImage) {
          final imageData = part.decodeContentBinary();
          if (imageData != null) {
            bodyWidgets.add(const SizedBox(height: 16));
            bodyWidgets.add(
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    imageData,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            );
          }
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.all(8),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Regresar a la bandeja',
                onPressed: widget.onBack,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.email.subject,
                  style: theme.textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.email.hasAttachments)
                ElevatedButton.icon(
                  icon: _isDownloading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.download, size: 18),
                  label: const Text('Guardar PDF/Imagen'),
                  onPressed: _isDownloading ? null : _downloadAttachments,
                ),
            ],
          ),
        ),
        
        // Metadata header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('De: ${widget.email.sender}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Fecha: ${widget.email.date.toString()}'),
              if (widget.email.hasAttachments) ...[
                const SizedBox(height: 4),
                Text('Adjuntos detectados: ${widget.email.attachmentNames.join(", ")}', 
                  style: TextStyle(color: theme.colorScheme.primary, fontSize: 13)),
              ],
            ],
          ),
        ),

        // Body Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: bodyWidgets,
            ),
          ),
        ),
      ],
    );
  }
}
