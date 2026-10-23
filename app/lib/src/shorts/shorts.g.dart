// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shorts.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Настройки распознавания речи (.env); `ref.invalidate` перечитывает файл.

@ProviderFor(speechConfig)
final speechConfigProvider = SpeechConfigProvider._();

/// Настройки распознавания речи (.env); `ref.invalidate` перечитывает файл.

final class SpeechConfigProvider
    extends
        $FunctionalProvider<
          AsyncValue<rust.SpeechConfig>,
          rust.SpeechConfig,
          FutureOr<rust.SpeechConfig>
        >
    with
        $FutureModifier<rust.SpeechConfig>,
        $FutureProvider<rust.SpeechConfig> {
  /// Настройки распознавания речи (.env); `ref.invalidate` перечитывает файл.
  SpeechConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'speechConfigProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$speechConfigHash();

  @$internal
  @override
  $FutureProviderElement<rust.SpeechConfig> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<rust.SpeechConfig> create(Ref ref) {
    return speechConfig(ref);
  }
}

String _$speechConfigHash() => r'6937f91291a63668fe7dffb34064f5bada7b381c';

@ProviderFor(Shorts)
final shortsProvider = ShortsProvider._();

final class ShortsProvider extends $NotifierProvider<Shorts, ShortsState> {
  ShortsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shortsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shortsHash();

  @$internal
  @override
  Shorts create() => Shorts();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShortsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShortsState>(value),
    );
  }
}

String _$shortsHash() => r'bd56b06978a9924b827363408d7723b651b54389';

abstract class _$Shorts extends $Notifier<ShortsState> {
  ShortsState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ShortsState, ShortsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ShortsState, ShortsState>,
              ShortsState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
