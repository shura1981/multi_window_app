import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:multi_window_app/features/emails/data/email_model.dart';
import 'package:multi_window_app/features/emails/data/email_service.dart';

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
  bool _showHtml = true;

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
    
    // Attempt to extract HTML content first, then fallback to plain text
    String? htmlBody = message.decodeTextHtmlPart();
    String? plainBody = message.decodeTextPlainPart();
    
    // Fallbacks
    if (htmlBody == null || htmlBody.trim().isEmpty) {
      _showHtml = false;
    }
    
    List<Widget> bodyWidgets = [];
    
    if (_showHtml && htmlBody != null && htmlBody.isNotEmpty) {
      bodyWidgets.add(
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Container(
              color: Colors.white, // Force email canvas to white (standard for HTML newsletters)
              padding: const EdgeInsets.all(16.0),
              child: HtmlWidget(
                htmlBody,
                textStyle: const TextStyle(
                  fontSize: 14.0,
                  color: Colors.black, // Force text to black to contrast the white canvas
                ),
                // Override inline font-family and strictly enforce black text on all nodes
                customStylesBuilder: (element) {
                  return {
                    'font-family': 'system-ui, sans-serif',
                    'color': '#000000',
                  };
                },
                customWidgetBuilder: (element) {
                  if (element.localName == 'img') {
                  final src = element.attributes['src'] ?? '';
                  if (src.startsWith('cid:')) {
                    final cid = src.substring(4);
                    final part = message.getPartWithContentId(cid);
                    if (part != null) {
                      final data = part.decodeContentBinary();
                      if (data != null) {
                        return Image.memory(
                          data, 
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => 
                            const Icon(Icons.broken_image, color: Colors.grey),
                        );
                      }
                    }
                    return const Icon(Icons.broken_image, color: Colors.grey);
                  }
                }
                return null;
              },
            ),
          ),
        ),
      ));
    } else if (plainBody != null && plainBody.isNotEmpty) {
      bodyWidgets.add(
        SelectableText(
          plainBody,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
        ),
      );
    } else {
      bodyWidgets.add(
        const Text('El correo no contiene contenido visualizable.'),
      );
    }

    // Still append inline images encoded in the email that weren't strictly matched inside HTML tags
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
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
                  if (htmlBody != null && htmlBody.isNotEmpty)
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: true, label: Text('HTML')),
                        ButtonSegment(value: false, label: Text('Texto')),
                      ],
                      selected: {_showHtml},
                      onSelectionChanged: (Set<bool> newSelection) {
                        setState(() {
                          _showHtml = newSelection.first;
                        });
                      },
                      showSelectedIcon: false,
                    ),
                ],
              ),
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

// Removed CidImageExtension as HtmlWidget uses inline customWidgetBuilder
