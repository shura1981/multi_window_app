import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'print_service.dart';

class PrintDialog extends StatefulWidget {
  final List<Map<String, dynamic>> usersToPrint;

  const PrintDialog({super.key, required this.usersToPrint});

  @override
  State<PrintDialog> createState() => _PrintDialogState();
}

class _PrintDialogState extends State<PrintDialog> {
  List<Printer> _printers = [];
  Printer? _selectedPrinter;
  bool _isLoading = true;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _loadPrinters();
  }

  Future<void> _loadPrinters() async {
    try {
      final printersList = await Printing.listPrinters();
      
      Printer? defaultOrFirst;
      if (printersList.isNotEmpty) {
        // Try to find default printer
        try {
          defaultOrFirst = printersList.firstWhere((p) => p.isDefault == true);
        } catch (_) { // Not found
          defaultOrFirst = printersList.first;
        }
      }

      if (mounted) {
        setState(() {
          _printers = printersList;
          _selectedPrinter = defaultOrFirst;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading printers: \$e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _printDocument() async {
    if (_selectedPrinter == null) return;
    
    setState(() => _isPrinting = true);
    
    try {
      final pdfData = await PrintService.generateUsersPdf(widget.usersToPrint);
      
      final result = await Printing.directPrintPdf(
        printer: _selectedPrinter!,
        onLayout: (format) => pdfData,
        name: 'User_List.pdf',
      );

      if (mounted) {
        Navigator.of(context).pop();
        if (result) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Document sent to \${_selectedPrinter!.name}')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Print job failed or cancelled.', style: TextStyle(color: Colors.red))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPrinting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error printing: \$e', style: const TextStyle(color: Colors.red))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Print Users Table', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              const Text('Select Printer:'),
              const SizedBox(height: 8),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_printers.isEmpty)
                const Text('No printers found on this system.', style: TextStyle(color: Colors.red))
              else
                DropdownButtonFormField<Printer>(
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  initialValue: _selectedPrinter,
                  isExpanded: true,
                  items: _printers.map((p) {
                    return DropdownMenuItem<Printer>(
                      value: p,
                      child: Text(p.name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (Printer? newValue) {
                    setState(() {
                      _selectedPrinter = newValue;
                    });
                  },
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isPrinting ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    icon: _isPrinting 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.print, size: 18),
                    label: const Text('Print'),
                    onPressed: (_printers.isEmpty || _selectedPrinter == null || _isPrinting) 
                      ? null 
                      : _printDocument,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
