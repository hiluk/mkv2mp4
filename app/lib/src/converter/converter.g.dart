// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'converter.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Путь к встроенному ffmpeg или null, если его нет.

@ProviderFor(ffmpegPath)
final ffmpegPathProvider = FfmpegPathProvider._();

/// Путь к встроенному ffmpeg или null, если его нет.

final class FfmpegPathProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// Путь к встроенному ffmpeg или null, если его нет.
  FfmpegPathProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ffmpegPathProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ffmpegPathHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return ffmpegPath(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$ffmpegPathHash() => r'b1535be91c3809ebedf32de8a9725ae20149cafa';

@ProviderFor(Converter)
final converterProvider = ConverterProvider._();

final class ConverterProvider
    extends $NotifierProvider<Converter, ConverterState> {
  ConverterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'converterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$converterHash();

  @$internal
  @override
  Converter create() => Converter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConverterState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConverterState>(value),
    );
  }
}

String _$converterHash() => r'6faf94f7d2d62ab808e633e756760ae80c82d1f0';

abstract class _$Converter extends $Notifier<ConverterState> {
  ConverterState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ConverterState, ConverterState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ConverterState, ConverterState>,
              ConverterState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
