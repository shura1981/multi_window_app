import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:enough_mail/enough_mail.dart';

class CidImageExtension extends HtmlExtension {
  final MimeMessage message;
  CidImageExtension(this.message);

  @override
  Set<String> get supportedTags => {"img"};

  @override
  bool matches(ExtensionContext context) {
    if (context.elementName == "img") {
      final src = context.attributes['src'];
      return src != null && src.startsWith('cid:');
    }
    return false;
  }

  @override
  InlineSpan build(ExtensionContext context) {
    final src = context.attributes['src']!;
    final cid = src.substring(4);
    final part = message.getPartWithContentId(cid);
    if (part != null) {
      final data = part.decodeContentBinary();
      if (data != null) {
        return WidgetSpan(child: Image.memory(data));
      }
    }
    return const WidgetSpan(child: SizedBox());
  }
}

void main() {
  final MimeMessage message = MimeMessage();
  Html(
    data: '<img src="cid:test">',
    extensions: [
      CidImageExtension(message),
    ],
  );
}
