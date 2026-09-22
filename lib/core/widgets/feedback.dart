import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../api/api_client.dart';

/// Xatoni foydalanuvchiga tushunarli matnga aylantiradi.
/// 4xx da backend matni o'zbekcha va aniq — shuni ko'rsatamiz.
String errorText(BuildContext context, Object e) {
  final s = S.of(context);
  if (e is ApiException) {
    return switch (e.kind) {
      ApiErrorKind.network => s.errNetwork,
      ApiErrorKind.tooMany => s.errTooMany,
      ApiErrorKind.server5xx => s.errServer,
      ApiErrorKind.server4xx || ApiErrorKind.unauthorized => e.message ?? s.errUnknown,
      ApiErrorKind.unknown => s.errUnknown,
    };
  }
  return s.errUnknown;
}

void showSnack(BuildContext context, String text, {IconData? icon}) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    content: Row(
      children: [
        if (icon != null) ...[Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 10)],
        Expanded(child: Text(text)),
      ],
    ),
  ));
}
