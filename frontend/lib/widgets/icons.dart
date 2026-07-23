import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum CartaIconData {
  pencil,
  stopwatch,
  list,
  terminal,
  settings,
  play,
  bookmark,
  refresh,
  copy,
  file,
  chevRight,
  clock,
  workflow,
  x,
  gitBranch,
  forEach,
  merge,
  zap,
  check,
  save,
  search,
  lock,
  collapseLink,
  bot,
  mousePointer,
  scissors,
  maximize,
  sun,
  layout,
  send,
  plug,
  trash,
  plus,
  globe,
  alertTriangle,
  panelRight,
}

class CartaIcon extends StatelessWidget {
  final CartaIconData icon;
  final double size;
  final Color color;

  const CartaIcon({
    super.key,
    required this.icon,
    this.size = 16,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      _svg(icon),
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

String _svg(CartaIconData icon) {
  const s = 'xmlns="http://www.w3.org/2000/svg"';
  const a = 'fill="none" stroke="white" stroke-width="1.5" '
      'stroke-linecap="round" stroke-linejoin="round"';
  final body = _bodies[icon]!;
  return '<svg $s width="24" height="24" viewBox="0 0 24 24" $a>$body</svg>';
}

const Map<CartaIconData, String> _bodies = {
  CartaIconData.pencil:
      '<path d="M12 20h9"/><path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4 12.5-12.5z"/>',

  CartaIconData.stopwatch:
      '<circle cx="12" cy="14" r="8"/><line x1="12" y1="10" x2="12" y2="14"/>'
      '<line x1="9" y1="2" x2="15" y2="2"/><line x1="12" y1="2" x2="12" y2="4"/>',

  CartaIconData.list:
      '<line x1="8" y1="6" x2="21" y2="6"/><line x1="8" y1="12" x2="21" y2="12"/>'
      '<line x1="8" y1="18" x2="21" y2="18"/><line x1="3" y1="6" x2="3.01" y2="6"/>'
      '<line x1="3" y1="12" x2="3.01" y2="12"/><line x1="3" y1="18" x2="3.01" y2="18"/>',

  CartaIconData.terminal:
      '<polyline points="4 17 10 11 4 5"/><line x1="12" y1="19" x2="20" y2="19"/>',

  CartaIconData.settings:
      '<circle cx="12" cy="12" r="3"/>'
      '<path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06'
      'a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09'
      'a1.65 1.65 0 0 0-1-1.51 1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06'
      'A1.65 1.65 0 0 0 4.6 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09'
      'A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06'
      'A1.65 1.65 0 0 0 9 4.6 1.65 1.65 0 0 0 10 3.09V3a2 2 0 0 1 4 0v.09'
      'a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06'
      'a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09'
      'a1.65 1.65 0 0 0-1.51 1z"/>',

  CartaIconData.play:
      '<polygon points="5,3 19,12 5,21"/>',

  CartaIconData.bookmark:
      '<path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z"/>',

  CartaIconData.refresh:
      '<polyline points="23,4 23,10 17,10"/>'
      '<polyline points="1,20 1,14 7,14"/>'
      '<path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10 M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/>',

  CartaIconData.copy:
      '<rect x="9" y="9" width="13" height="13" rx="2" ry="2"/>'
      '<path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/>',

  CartaIconData.file:
      '<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>'
      '<polyline points="14,2 14,8 20,8"/>',

  CartaIconData.chevRight:
      '<polyline points="9,18 15,12 9,6"/>',

  CartaIconData.clock:
      '<circle cx="12" cy="12" r="10"/>'
      '<polyline points="12,6 12,12 16,14"/>',

  CartaIconData.workflow:
      '<path d="M18 8h1a4 4 0 0 1 0 8h-1"/>'
      '<path d="M2 8h16v9a4 4 0 0 1-4 4H6a4 4 0 0 1-4-4z"/>'
      '<line x1="6" y1="1" x2="6" y2="4"/>'
      '<line x1="10" y1="1" x2="10" y2="4"/>'
      '<line x1="14" y1="1" x2="14" y2="4"/>',

  CartaIconData.x:
      '<line x1="18" y1="6" x2="6" y2="18"/>'
      '<line x1="6" y1="6" x2="18" y2="18"/>',

  CartaIconData.gitBranch:
      '<circle cx="18" cy="18" r="3"/>'
      '<circle cx="6" cy="6" r="3"/>'
      '<path d="M6 21V9a9 9 0 0 0 9 9"/>',

  CartaIconData.forEach:
      '<circle cx="4" cy="12" r="2"/>'
      '<circle cx="20" cy="5" r="2"/>'
      '<circle cx="20" cy="12" r="2"/>'
      '<circle cx="20" cy="19" r="2"/>'
      '<path d="M6 12h6M12 5v14M12 5h6M12 12h6M12 19h6"/>',

  CartaIconData.merge:
      '<circle cx="4" cy="5" r="2"/>'
      '<circle cx="4" cy="12" r="2"/>'
      '<circle cx="4" cy="19" r="2"/>'
      '<circle cx="20" cy="12" r="2"/>'
      '<path d="M6 5h6M6 12h6M6 19h6M12 5v14M12 12h6"/>',

  CartaIconData.zap:
      '<polygon points="13,2 3,14 12,14 11,22 21,10 12,10 13,2"/>',

  CartaIconData.check:
      '<polyline points="20,6 9,17 4,12"/>',

  CartaIconData.save:
      '<path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/>'
      '<polyline points="17,21 17,13 7,13 7,21"/>'
      '<polyline points="7,3 7,8 15,8"/>',

  CartaIconData.search:
      '<circle cx="11" cy="11" r="8"/>'
      '<line x1="21" y1="21" x2="16.65" y2="16.65"/>',

  CartaIconData.lock:
      '<rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>'
      '<path d="M7 11V7a5 5 0 0 1 10 0v4"/>',

  CartaIconData.collapseLink:
      '<path d="M15 3h6v6M9 21H3v-6M21 3l-7 7M3 21l7-7"/>',

  CartaIconData.bot:
      '<path d="M12 8V4H8"/>'
      '<rect width="16" height="12" x="4" y="8" rx="2"/>'
      '<path d="M2 14h2"/><path d="M20 14h2"/>'
      '<path d="M15 13v2"/><path d="M9 13v2"/>',

  CartaIconData.mousePointer:
      '<path d="M3 3l7.07 16.97 2.51-7.39 7.39-2.51L3 3z"/>'
      '<line x1="13" y1="13" x2="21" y2="21"/>'
      '<line x1="13" y1="13" x2="16" y2="16"/>',

  CartaIconData.scissors:
      '<circle cx="6" cy="6" r="3"/>'
      '<circle cx="6" cy="18" r="3"/>'
      '<line x1="20" y1="4" x2="8.12" y2="15.88"/>'
      '<line x1="14.47" y1="14.48" x2="20" y2="20"/>'
      '<line x1="8.12" y1="8.12" x2="12" y2="12"/>',

  CartaIconData.maximize:
      '<path d="M8 3H5a2 2 0 0 0-2 2v3"/>'
      '<path d="M21 8V5a2 2 0 0 0-2-2h-3"/>'
      '<path d="M3 16v3a2 2 0 0 0 2 2h3"/>'
      '<path d="M16 21h3a2 2 0 0 0 2-2v-3"/>',

  CartaIconData.sun:
      '<circle cx="12" cy="12" r="5"/><line x1="12" y1="1" x2="12" y2="3"/>'
      '<line x1="12" y1="21" x2="12" y2="23"/><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/>'
      '<line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/><line x1="1" y1="12" x2="3" y2="12"/>'
      '<line x1="21" y1="12" x2="23" y2="12"/><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/>'
      '<line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/>',

  CartaIconData.layout:
      '<rect x="3" y="3" width="18" height="18" rx="2" ry="2"/><line x1="3" y1="9" x2="21" y2="9"/>'
      '<line x1="9" y1="21" x2="9" y2="9"/>',

  CartaIconData.send:
      '<line x1="22" y1="2" x2="11" y2="13"/>'
      '<polygon points="22,2 15,22 11,13 2,9 22,2"/>',

  CartaIconData.plug:
      '<path d="M12 22v-5"/><path d="M9 8V2"/><path d="M15 8V2"/>'
      '<path d="M18 8v5a4 4 0 0 1-4 4h-4a4 4 0 0 1-4-4V8Z"/>',

  CartaIconData.trash:
      '<path d="M3 6h18"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6"/>'
      '<line x1="10" y1="11" x2="10" y2="17"/><line x1="14" y1="11" x2="14" y2="17"/>'
      '<path d="M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>',
  CartaIconData.plus:
      '<line x1="12" y1="5" x2="12" y2="19"/>'
      '<line x1="5" y1="12" x2="19" y2="12"/>',
  CartaIconData.globe:
      '<circle cx="12" cy="12" r="10"/>'
      '<line x1="2" y1="12" x2="22" y2="12"/>'
      '<path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/>',

  CartaIconData.alertTriangle:
      '<path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/>'
      '<line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/>',

  CartaIconData.panelRight:
      '<rect x="3" y="4" width="18" height="16" rx="2"/>'
      '<line x1="15" y1="4" x2="15" y2="20"/>',
};
