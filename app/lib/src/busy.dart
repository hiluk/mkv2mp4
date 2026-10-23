import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'converter/converter.dart';
import 'shorts/shorts.dart';

part 'busy.g.dart';

/// Идёт ли сейчас конвертация или нарезка (отмена у них общая, поэтому
/// одновременно запускать нельзя).
@riverpod
bool busy(Ref ref) =>
    ref.watch(converterProvider.select((s) => s.running)) ||
    ref.watch(shortsProvider.select((s) => s.running));
