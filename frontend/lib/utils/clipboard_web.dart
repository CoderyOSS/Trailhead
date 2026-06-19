import 'dart:html' as html;

Future<bool> fallbackCopy(String text) async {
  try {
    final ta = html.TextAreaElement()
      ..value = text
      ..style.position = 'fixed'
      ..style.opacity = '0'
      ..style.left = '-9999px';
    html.document.body!.append(ta);
    ta.focus();
    ta.select();
    final success = html.document.execCommand('copy');
    ta.remove();
    return success;
  } catch (_) {
    return false;
  }
}
