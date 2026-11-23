import 'package:flutter/material.dart';

import '../../core/theme/atmos_text.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.overline,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String overline;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(overline.toUpperCase(), style: AtmosText.overline),
                const SizedBox(height: 8),
                Semantics(
                    header: true, child: Text(title, style: AtmosText.title)),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(subtitle!, style: AtmosText.body),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: AtmosText.heading),
            ),
          ),
          if (trailing != null)
            Flexible(
              child: Text(
                trailing!,
                style: AtmosText.caption,
                textAlign: TextAlign.end,
              ),
            ),
        ],
      ),
    );
  }
}
