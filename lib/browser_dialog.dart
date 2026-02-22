import 'package:flutter/material.dart';
import 'package:desktop_webview_window/desktop_webview_window.dart';

class BrowserLauncherDialog extends StatefulWidget {
  const BrowserLauncherDialog({super.key});

  @override
  State<BrowserLauncherDialog> createState() => _BrowserLauncherDialogState();
}

class _BrowserLauncherDialogState extends State<BrowserLauncherDialog> {
  final TextEditingController _urlController = TextEditingController(text: 'https://flutter.dev');
  bool _isWebViewAvailable = false;
  Webview? _webview;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    final available = await WebviewWindow.isWebviewAvailable();
    if (mounted) {
      setState(() {
        _isWebViewAvailable = available;
      });
    }
  }

  Future<void> _launchWebView() async {
    String urlStr = _urlController.text.trim();
    if (urlStr.isEmpty) return;
    if (!urlStr.startsWith('http://') && !urlStr.startsWith('https://')) {
      urlStr = 'https://$urlStr';
    }

    // Launch the native window
    _webview = await WebviewWindow.create(
      configuration: const CreateConfiguration(
        windowHeight: 700,
        windowWidth: 1000,
        title: "Navegador Web",
      ),
    );
    
    _webview?.onClose.whenComplete(() {
      _webview = null;
    });

    _webview?.launch(urlStr);
    
    // Close the dialog after launching
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      icon: Icon(Icons.travel_explore, size: 48, color: theme.colorScheme.primary),
      title: const Text('Lanzar Navegador Web'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ingresa la dirección web que deseas visitar. El navegador se abrirá en una ventana nativa acelerada por hardware.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'ej. google.com',
                prefixIcon: Icon(Icons.link),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              onSubmitted: (_) => _isWebViewAvailable ? _launchWebView() : null,
              autofocus: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _isWebViewAvailable ? _launchWebView : null,
          icon: const Icon(Icons.open_in_new),
          label: Text(_isWebViewAvailable ? 'Abrir' : 'No disponible'),
        ),
      ],
    );
  }
}
