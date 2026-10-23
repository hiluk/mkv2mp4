// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'busy.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Идёт ли сейчас конвертация или нарезка (отмена у них общая, поэтому
/// одновременно запускать нельзя).

@ProviderFor(busy)
final busyProvider = BusyProvider._();

/// Идёт ли сейчас конвертация или нарезка (отмена у них общая, поэтому
/// одновременно запускать нельзя).

final class BusyProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Идёт ли сейчас конвертация или нарезка (отмена у них общая, поэтому
  /// одновременно запускать нельзя).
  BusyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'busyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$busyHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return busy(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$busyHash() => r'3b5c8763106f6263e78c29a8bf63040151102943';
