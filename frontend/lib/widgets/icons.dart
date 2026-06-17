import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum TrailheadIconData {
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
}

class TrailheadIcon extends StatelessWidget {
  final TrailheadIconData icon;
  final double size;
  final Color color;

  const TrailheadIcon({
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

String _svg(TrailheadIconData icon) {
  const s = 'xmlns="http://www.w3.org/2000/svg"';
  const a = 'fill="none" stroke="white" stroke-width="1.5" '
      'stroke-linecap="round" stroke-linejoin="round"';
  final body = _bodies[icon]!;
  return '<svg $s width="24" height="24" viewBox="0 0 24 24" $a>$body</svg>';
}

const Map<TrailheadIconData, String> _bodies = {
  TrailheadIconData.pencil:
      '<path d="M12 20h9"/><path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4 12.5-12.5z"/>',

  TrailheadIconData.stopwatch:
      '<circle cx="12" cy="14" r="8"/><line x1="12" y1="10" x2="12" y2="14"/>'
      '<line x1="9" y1="2" x2="15" y2="2"/><line x1="12" y1="2" x2="12" y2="4"/>',

  TrailheadIconData.list:
      '<line x1="8" y1="6" x2="21" y2="6"/><line x1="8" y1="12" x2="21" y2="12"/>'
      '<line x1="8" y1="18" x2="21" y2="18"/><line x1="3" y1="6" x2="3.01" y2="6"/>'
      '<line x1="3" y1="12" x2="3.01" y2="12"/><line x1="3" y1="18" x2="3.01" y2="18"/>',

  TrailheadIconData.terminal:
      '<polyline points="4 17 10 11 4 5"/><line x1="12" y1="19" x2="20" y2="19"/>',

  TrailheadIconData.settings:
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

  TrailheadIconData.play:
      '<polygon points="5,3 19,12 5,21"/>',

  TrailheadIconData.bookmark:
      '<path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z"/>',

  TrailheadIconData.refresh:
      '<polyline points="23,4 23,10 17,10"/>'
      '<polyline points="1,20 1,14 7,14"/>'
      '<path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10 M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/>',

  TrailheadIconData.copy:
      '<rect x="9" y="9" width="13" height="13" rx="2" ry="2"/>'
      '<path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/>',

  TrailheadIconData.file:
      '<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>'
      '<polyline points="14,2 14,8 20,8"/>',

  TrailheadIconData.chevRight:
      '<polyline points="9,18 15,12 9,6"/>',

  TrailheadIconData.clock:
      '<circle cx="12" cy="12" r="10"/>'
      '<polyline points="12,6 12,12 16,14"/>',

  TrailheadIconData.workflow:
      '<path d="M18 8h1a4 4 0 0 1 0 8h-1"/>'
      '<path d="M2 8h16v9a4 4 0 0 1-4 4H6a4 4 0 0 1-4-4z"/>'
      '<line x1="6" y1="1" x2="6" y2="4"/>'
      '<line x1="10" y1="1" x2="10" y2="4"/>'
      '<line x1="14" y1="1" x2="14" y2="4"/>',

  TrailheadIconData.x:
      '<line x1="18" y1="6" x2="6" y2="18"/>'
      '<line x1="6" y1="6" x2="18" y2="18"/>',

  TrailheadIconData.gitBranch:
      '<circle cx="18" cy="18" r="3"/>'
      '<circle cx="6" cy="6" r="3"/>'
      '<path d="M6 21V9a9 9 0 0 0 9 9"/>',

  TrailheadIconData.forEach:
      '<circle cx="4" cy="12" r="2"/>'
      '<circle cx="20" cy="5" r="2"/>'
      '<circle cx="20" cy="12" r="2"/>'
      '<circle cx="20" cy="19" r="2"/>'
      '<path d="M6 12h6M12 5v14M12 5h6M12 12h6M12 19h6"/>',

  TrailheadIconData.merge:
      '<circle cx="4" cy="5" r="2"/>'
      '<circle cx="4" cy="12" r="2"/>'
      '<circle cx="4" cy="19" r="2"/>'
      '<circle cx="20" cy="12" r="2"/>'
      '<path d="M6 5h6M6 12h6M6 19h6M12 5v14M12 12h6"/>',

  TrailheadIconData.zap:
      '<polygon points="13,2 3,14 12,14 11,22 21,10 12,10 13,2"/>',

  TrailheadIconData.check:
      '<polyline points="20,6 9,17 4,12"/>',

  TrailheadIconData.save:
      '<path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/>'
      '<polyline points="17,21 17,13 7,13 7,21"/>'
      '<polyline points="7,3 7,8 15,8"/>',

  TrailheadIconData.search:
      '<circle cx="11" cy="11" r="8"/>'
      '<line x1="21" y1="21" x2="16.65" y2="16.65"/>',

  TrailheadIconData.lock:
      '<rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>'
      '<path d="M7 11V7a5 5 0 0 1 10 0v4"/>',

  TrailheadIconData.collapseLink:
      '<path d="M15 3h6v6M9 21H3v-6M21 3l-7 7M3 21l7-7"/>',
};
