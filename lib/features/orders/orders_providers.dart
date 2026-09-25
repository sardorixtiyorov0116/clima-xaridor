import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'data/order_models.dart';
import 'data/order_repository.dart';
import 'data/tracking_models.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) => OrderRepository(ref.read(apiClientProvider)));

/// Xaridorning buyurtmalari — yangilari tepada.
final myOrdersProvider = FutureProvider<List<Order>>((ref) async {
  final s = ref.watch(sessionProvider);
  if (s == null) return const [];
  final list = await ref.read(orderRepositoryProvider).mine(s.userId);
  return list..sort((a, b) => b.id.compareTo(a.id));
});

/// Kuzatish (№38, №39): bosqichlar, kuryer va usta. Sahifa yopilganda tozalanadi.
final orderTrackingProvider = FutureProvider.autoDispose.family<OrderTracking, int>(
  (ref, id) => ref.read(orderRepositoryProvider).tracking(id),
);
