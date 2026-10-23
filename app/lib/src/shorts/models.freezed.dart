// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ShortsJob {

 String get input; MediaInfo? get info;/// Номер выбранной дорожки субтитров (среди субтитров).
 int? get subtitleTrack;/// Распознавать речь вместо субтитров из файла.
 bool get speech; int get audioTrack; ShortsStatus get status; double get progress; String get message;/// Предупреждение, с которым нарезка всё же закончилась.
 String get warning; int get clipsDone; int get clipsTotal; String? get outputDir;
/// Create a copy of ShortsJob
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShortsJobCopyWith<ShortsJob> get copyWith => _$ShortsJobCopyWithImpl<ShortsJob>(this as ShortsJob, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShortsJob&&(identical(other.input, input) || other.input == input)&&(identical(other.info, info) || other.info == info)&&(identical(other.subtitleTrack, subtitleTrack) || other.subtitleTrack == subtitleTrack)&&(identical(other.speech, speech) || other.speech == speech)&&(identical(other.audioTrack, audioTrack) || other.audioTrack == audioTrack)&&(identical(other.status, status) || other.status == status)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.message, message) || other.message == message)&&(identical(other.warning, warning) || other.warning == warning)&&(identical(other.clipsDone, clipsDone) || other.clipsDone == clipsDone)&&(identical(other.clipsTotal, clipsTotal) || other.clipsTotal == clipsTotal)&&(identical(other.outputDir, outputDir) || other.outputDir == outputDir));
}


@override
int get hashCode => Object.hash(runtimeType,input,info,subtitleTrack,speech,audioTrack,status,progress,message,warning,clipsDone,clipsTotal,outputDir);

@override
String toString() {
  return 'ShortsJob(input: $input, info: $info, subtitleTrack: $subtitleTrack, speech: $speech, audioTrack: $audioTrack, status: $status, progress: $progress, message: $message, warning: $warning, clipsDone: $clipsDone, clipsTotal: $clipsTotal, outputDir: $outputDir)';
}


}

/// @nodoc
abstract mixin class $ShortsJobCopyWith<$Res>  {
  factory $ShortsJobCopyWith(ShortsJob value, $Res Function(ShortsJob) _then) = _$ShortsJobCopyWithImpl;
@useResult
$Res call({
 String input, MediaInfo? info, int? subtitleTrack, bool speech, int audioTrack, ShortsStatus status, double progress, String message, String warning, int clipsDone, int clipsTotal, String? outputDir
});




}
/// @nodoc
class _$ShortsJobCopyWithImpl<$Res>
    implements $ShortsJobCopyWith<$Res> {
  _$ShortsJobCopyWithImpl(this._self, this._then);

  final ShortsJob _self;
  final $Res Function(ShortsJob) _then;

/// Create a copy of ShortsJob
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? input = null,Object? info = freezed,Object? subtitleTrack = freezed,Object? speech = null,Object? audioTrack = null,Object? status = null,Object? progress = null,Object? message = null,Object? warning = null,Object? clipsDone = null,Object? clipsTotal = null,Object? outputDir = freezed,}) {
  return _then(_self.copyWith(
input: null == input ? _self.input : input // ignore: cast_nullable_to_non_nullable
as String,info: freezed == info ? _self.info : info // ignore: cast_nullable_to_non_nullable
as MediaInfo?,subtitleTrack: freezed == subtitleTrack ? _self.subtitleTrack : subtitleTrack // ignore: cast_nullable_to_non_nullable
as int?,speech: null == speech ? _self.speech : speech // ignore: cast_nullable_to_non_nullable
as bool,audioTrack: null == audioTrack ? _self.audioTrack : audioTrack // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ShortsStatus,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,warning: null == warning ? _self.warning : warning // ignore: cast_nullable_to_non_nullable
as String,clipsDone: null == clipsDone ? _self.clipsDone : clipsDone // ignore: cast_nullable_to_non_nullable
as int,clipsTotal: null == clipsTotal ? _self.clipsTotal : clipsTotal // ignore: cast_nullable_to_non_nullable
as int,outputDir: freezed == outputDir ? _self.outputDir : outputDir // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ShortsJob].
extension ShortsJobPatterns on ShortsJob {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShortsJob value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShortsJob() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShortsJob value)  $default,){
final _that = this;
switch (_that) {
case _ShortsJob():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShortsJob value)?  $default,){
final _that = this;
switch (_that) {
case _ShortsJob() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String input,  MediaInfo? info,  int? subtitleTrack,  bool speech,  int audioTrack,  ShortsStatus status,  double progress,  String message,  String warning,  int clipsDone,  int clipsTotal,  String? outputDir)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShortsJob() when $default != null:
return $default(_that.input,_that.info,_that.subtitleTrack,_that.speech,_that.audioTrack,_that.status,_that.progress,_that.message,_that.warning,_that.clipsDone,_that.clipsTotal,_that.outputDir);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String input,  MediaInfo? info,  int? subtitleTrack,  bool speech,  int audioTrack,  ShortsStatus status,  double progress,  String message,  String warning,  int clipsDone,  int clipsTotal,  String? outputDir)  $default,) {final _that = this;
switch (_that) {
case _ShortsJob():
return $default(_that.input,_that.info,_that.subtitleTrack,_that.speech,_that.audioTrack,_that.status,_that.progress,_that.message,_that.warning,_that.clipsDone,_that.clipsTotal,_that.outputDir);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String input,  MediaInfo? info,  int? subtitleTrack,  bool speech,  int audioTrack,  ShortsStatus status,  double progress,  String message,  String warning,  int clipsDone,  int clipsTotal,  String? outputDir)?  $default,) {final _that = this;
switch (_that) {
case _ShortsJob() when $default != null:
return $default(_that.input,_that.info,_that.subtitleTrack,_that.speech,_that.audioTrack,_that.status,_that.progress,_that.message,_that.warning,_that.clipsDone,_that.clipsTotal,_that.outputDir);case _:
  return null;

}
}

}

/// @nodoc


class _ShortsJob extends ShortsJob {
  const _ShortsJob({required this.input, this.info, this.subtitleTrack, this.speech = false, this.audioTrack = 0, this.status = ShortsStatus.loading, this.progress = 0, this.message = '', this.warning = '', this.clipsDone = 0, this.clipsTotal = 0, this.outputDir}): super._();
  

@override final  String input;
@override final  MediaInfo? info;
/// Номер выбранной дорожки субтитров (среди субтитров).
@override final  int? subtitleTrack;
/// Распознавать речь вместо субтитров из файла.
@override@JsonKey() final  bool speech;
@override@JsonKey() final  int audioTrack;
@override@JsonKey() final  ShortsStatus status;
@override@JsonKey() final  double progress;
@override@JsonKey() final  String message;
/// Предупреждение, с которым нарезка всё же закончилась.
@override@JsonKey() final  String warning;
@override@JsonKey() final  int clipsDone;
@override@JsonKey() final  int clipsTotal;
@override final  String? outputDir;

/// Create a copy of ShortsJob
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShortsJobCopyWith<_ShortsJob> get copyWith => __$ShortsJobCopyWithImpl<_ShortsJob>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShortsJob&&(identical(other.input, input) || other.input == input)&&(identical(other.info, info) || other.info == info)&&(identical(other.subtitleTrack, subtitleTrack) || other.subtitleTrack == subtitleTrack)&&(identical(other.speech, speech) || other.speech == speech)&&(identical(other.audioTrack, audioTrack) || other.audioTrack == audioTrack)&&(identical(other.status, status) || other.status == status)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.message, message) || other.message == message)&&(identical(other.warning, warning) || other.warning == warning)&&(identical(other.clipsDone, clipsDone) || other.clipsDone == clipsDone)&&(identical(other.clipsTotal, clipsTotal) || other.clipsTotal == clipsTotal)&&(identical(other.outputDir, outputDir) || other.outputDir == outputDir));
}


@override
int get hashCode => Object.hash(runtimeType,input,info,subtitleTrack,speech,audioTrack,status,progress,message,warning,clipsDone,clipsTotal,outputDir);

@override
String toString() {
  return 'ShortsJob(input: $input, info: $info, subtitleTrack: $subtitleTrack, speech: $speech, audioTrack: $audioTrack, status: $status, progress: $progress, message: $message, warning: $warning, clipsDone: $clipsDone, clipsTotal: $clipsTotal, outputDir: $outputDir)';
}


}

/// @nodoc
abstract mixin class _$ShortsJobCopyWith<$Res> implements $ShortsJobCopyWith<$Res> {
  factory _$ShortsJobCopyWith(_ShortsJob value, $Res Function(_ShortsJob) _then) = __$ShortsJobCopyWithImpl;
@override @useResult
$Res call({
 String input, MediaInfo? info, int? subtitleTrack, bool speech, int audioTrack, ShortsStatus status, double progress, String message, String warning, int clipsDone, int clipsTotal, String? outputDir
});




}
/// @nodoc
class __$ShortsJobCopyWithImpl<$Res>
    implements _$ShortsJobCopyWith<$Res> {
  __$ShortsJobCopyWithImpl(this._self, this._then);

  final _ShortsJob _self;
  final $Res Function(_ShortsJob) _then;

/// Create a copy of ShortsJob
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? input = null,Object? info = freezed,Object? subtitleTrack = freezed,Object? speech = null,Object? audioTrack = null,Object? status = null,Object? progress = null,Object? message = null,Object? warning = null,Object? clipsDone = null,Object? clipsTotal = null,Object? outputDir = freezed,}) {
  return _then(_ShortsJob(
input: null == input ? _self.input : input // ignore: cast_nullable_to_non_nullable
as String,info: freezed == info ? _self.info : info // ignore: cast_nullable_to_non_nullable
as MediaInfo?,subtitleTrack: freezed == subtitleTrack ? _self.subtitleTrack : subtitleTrack // ignore: cast_nullable_to_non_nullable
as int?,speech: null == speech ? _self.speech : speech // ignore: cast_nullable_to_non_nullable
as bool,audioTrack: null == audioTrack ? _self.audioTrack : audioTrack // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ShortsStatus,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,warning: null == warning ? _self.warning : warning // ignore: cast_nullable_to_non_nullable
as String,clipsDone: null == clipsDone ? _self.clipsDone : clipsDone // ignore: cast_nullable_to_non_nullable
as int,clipsTotal: null == clipsTotal ? _self.clipsTotal : clipsTotal // ignore: cast_nullable_to_non_nullable
as int,outputDir: freezed == outputDir ? _self.outputDir : outputDir // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$ShortsSettings {

/// Максимальная длина ролика, секунды.
 int get maxLen;/// Только лучшие моменты (выбирает Claude), а не всё видео подряд.
 bool get bestMoments;/// Как показывать текст.
 CaptionStyle get captions;/// Куда класть папки с роликами; null — рядом с исходником.
 String? get outDir;
/// Create a copy of ShortsSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShortsSettingsCopyWith<ShortsSettings> get copyWith => _$ShortsSettingsCopyWithImpl<ShortsSettings>(this as ShortsSettings, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShortsSettings&&(identical(other.maxLen, maxLen) || other.maxLen == maxLen)&&(identical(other.bestMoments, bestMoments) || other.bestMoments == bestMoments)&&(identical(other.captions, captions) || other.captions == captions)&&(identical(other.outDir, outDir) || other.outDir == outDir));
}


@override
int get hashCode => Object.hash(runtimeType,maxLen,bestMoments,captions,outDir);

@override
String toString() {
  return 'ShortsSettings(maxLen: $maxLen, bestMoments: $bestMoments, captions: $captions, outDir: $outDir)';
}


}

/// @nodoc
abstract mixin class $ShortsSettingsCopyWith<$Res>  {
  factory $ShortsSettingsCopyWith(ShortsSettings value, $Res Function(ShortsSettings) _then) = _$ShortsSettingsCopyWithImpl;
@useResult
$Res call({
 int maxLen, bool bestMoments, CaptionStyle captions, String? outDir
});




}
/// @nodoc
class _$ShortsSettingsCopyWithImpl<$Res>
    implements $ShortsSettingsCopyWith<$Res> {
  _$ShortsSettingsCopyWithImpl(this._self, this._then);

  final ShortsSettings _self;
  final $Res Function(ShortsSettings) _then;

/// Create a copy of ShortsSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? maxLen = null,Object? bestMoments = null,Object? captions = null,Object? outDir = freezed,}) {
  return _then(_self.copyWith(
maxLen: null == maxLen ? _self.maxLen : maxLen // ignore: cast_nullable_to_non_nullable
as int,bestMoments: null == bestMoments ? _self.bestMoments : bestMoments // ignore: cast_nullable_to_non_nullable
as bool,captions: null == captions ? _self.captions : captions // ignore: cast_nullable_to_non_nullable
as CaptionStyle,outDir: freezed == outDir ? _self.outDir : outDir // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ShortsSettings].
extension ShortsSettingsPatterns on ShortsSettings {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShortsSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShortsSettings() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShortsSettings value)  $default,){
final _that = this;
switch (_that) {
case _ShortsSettings():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShortsSettings value)?  $default,){
final _that = this;
switch (_that) {
case _ShortsSettings() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int maxLen,  bool bestMoments,  CaptionStyle captions,  String? outDir)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShortsSettings() when $default != null:
return $default(_that.maxLen,_that.bestMoments,_that.captions,_that.outDir);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int maxLen,  bool bestMoments,  CaptionStyle captions,  String? outDir)  $default,) {final _that = this;
switch (_that) {
case _ShortsSettings():
return $default(_that.maxLen,_that.bestMoments,_that.captions,_that.outDir);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int maxLen,  bool bestMoments,  CaptionStyle captions,  String? outDir)?  $default,) {final _that = this;
switch (_that) {
case _ShortsSettings() when $default != null:
return $default(_that.maxLen,_that.bestMoments,_that.captions,_that.outDir);case _:
  return null;

}
}

}

/// @nodoc


class _ShortsSettings implements ShortsSettings {
  const _ShortsSettings({this.maxLen = 60, this.bestMoments = false, this.captions = CaptionStyle.revealHighlight, this.outDir});
  

/// Максимальная длина ролика, секунды.
@override@JsonKey() final  int maxLen;
/// Только лучшие моменты (выбирает Claude), а не всё видео подряд.
@override@JsonKey() final  bool bestMoments;
/// Как показывать текст.
@override@JsonKey() final  CaptionStyle captions;
/// Куда класть папки с роликами; null — рядом с исходником.
@override final  String? outDir;

/// Create a copy of ShortsSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShortsSettingsCopyWith<_ShortsSettings> get copyWith => __$ShortsSettingsCopyWithImpl<_ShortsSettings>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShortsSettings&&(identical(other.maxLen, maxLen) || other.maxLen == maxLen)&&(identical(other.bestMoments, bestMoments) || other.bestMoments == bestMoments)&&(identical(other.captions, captions) || other.captions == captions)&&(identical(other.outDir, outDir) || other.outDir == outDir));
}


@override
int get hashCode => Object.hash(runtimeType,maxLen,bestMoments,captions,outDir);

@override
String toString() {
  return 'ShortsSettings(maxLen: $maxLen, bestMoments: $bestMoments, captions: $captions, outDir: $outDir)';
}


}

/// @nodoc
abstract mixin class _$ShortsSettingsCopyWith<$Res> implements $ShortsSettingsCopyWith<$Res> {
  factory _$ShortsSettingsCopyWith(_ShortsSettings value, $Res Function(_ShortsSettings) _then) = __$ShortsSettingsCopyWithImpl;
@override @useResult
$Res call({
 int maxLen, bool bestMoments, CaptionStyle captions, String? outDir
});




}
/// @nodoc
class __$ShortsSettingsCopyWithImpl<$Res>
    implements _$ShortsSettingsCopyWith<$Res> {
  __$ShortsSettingsCopyWithImpl(this._self, this._then);

  final _ShortsSettings _self;
  final $Res Function(_ShortsSettings) _then;

/// Create a copy of ShortsSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? maxLen = null,Object? bestMoments = null,Object? captions = null,Object? outDir = freezed,}) {
  return _then(_ShortsSettings(
maxLen: null == maxLen ? _self.maxLen : maxLen // ignore: cast_nullable_to_non_nullable
as int,bestMoments: null == bestMoments ? _self.bestMoments : bestMoments // ignore: cast_nullable_to_non_nullable
as bool,captions: null == captions ? _self.captions : captions // ignore: cast_nullable_to_non_nullable
as CaptionStyle,outDir: freezed == outDir ? _self.outDir : outDir // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$ShortsState {

 List<ShortsJob> get jobs; ShortsSettings get settings; bool get running;
/// Create a copy of ShortsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShortsStateCopyWith<ShortsState> get copyWith => _$ShortsStateCopyWithImpl<ShortsState>(this as ShortsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShortsState&&const DeepCollectionEquality().equals(other.jobs, jobs)&&(identical(other.settings, settings) || other.settings == settings)&&(identical(other.running, running) || other.running == running));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(jobs),settings,running);

@override
String toString() {
  return 'ShortsState(jobs: $jobs, settings: $settings, running: $running)';
}


}

/// @nodoc
abstract mixin class $ShortsStateCopyWith<$Res>  {
  factory $ShortsStateCopyWith(ShortsState value, $Res Function(ShortsState) _then) = _$ShortsStateCopyWithImpl;
@useResult
$Res call({
 List<ShortsJob> jobs, ShortsSettings settings, bool running
});


$ShortsSettingsCopyWith<$Res> get settings;

}
/// @nodoc
class _$ShortsStateCopyWithImpl<$Res>
    implements $ShortsStateCopyWith<$Res> {
  _$ShortsStateCopyWithImpl(this._self, this._then);

  final ShortsState _self;
  final $Res Function(ShortsState) _then;

/// Create a copy of ShortsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? jobs = null,Object? settings = null,Object? running = null,}) {
  return _then(_self.copyWith(
jobs: null == jobs ? _self.jobs : jobs // ignore: cast_nullable_to_non_nullable
as List<ShortsJob>,settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as ShortsSettings,running: null == running ? _self.running : running // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of ShortsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShortsSettingsCopyWith<$Res> get settings {
  
  return $ShortsSettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}
}


/// Adds pattern-matching-related methods to [ShortsState].
extension ShortsStatePatterns on ShortsState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShortsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShortsState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShortsState value)  $default,){
final _that = this;
switch (_that) {
case _ShortsState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShortsState value)?  $default,){
final _that = this;
switch (_that) {
case _ShortsState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ShortsJob> jobs,  ShortsSettings settings,  bool running)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShortsState() when $default != null:
return $default(_that.jobs,_that.settings,_that.running);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ShortsJob> jobs,  ShortsSettings settings,  bool running)  $default,) {final _that = this;
switch (_that) {
case _ShortsState():
return $default(_that.jobs,_that.settings,_that.running);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ShortsJob> jobs,  ShortsSettings settings,  bool running)?  $default,) {final _that = this;
switch (_that) {
case _ShortsState() when $default != null:
return $default(_that.jobs,_that.settings,_that.running);case _:
  return null;

}
}

}

/// @nodoc


class _ShortsState extends ShortsState {
  const _ShortsState({final  List<ShortsJob> jobs = const [], this.settings = const ShortsSettings(), this.running = false}): _jobs = jobs,super._();
  

 final  List<ShortsJob> _jobs;
@override@JsonKey() List<ShortsJob> get jobs {
  if (_jobs is EqualUnmodifiableListView) return _jobs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_jobs);
}

@override@JsonKey() final  ShortsSettings settings;
@override@JsonKey() final  bool running;

/// Create a copy of ShortsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShortsStateCopyWith<_ShortsState> get copyWith => __$ShortsStateCopyWithImpl<_ShortsState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShortsState&&const DeepCollectionEquality().equals(other._jobs, _jobs)&&(identical(other.settings, settings) || other.settings == settings)&&(identical(other.running, running) || other.running == running));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_jobs),settings,running);

@override
String toString() {
  return 'ShortsState(jobs: $jobs, settings: $settings, running: $running)';
}


}

/// @nodoc
abstract mixin class _$ShortsStateCopyWith<$Res> implements $ShortsStateCopyWith<$Res> {
  factory _$ShortsStateCopyWith(_ShortsState value, $Res Function(_ShortsState) _then) = __$ShortsStateCopyWithImpl;
@override @useResult
$Res call({
 List<ShortsJob> jobs, ShortsSettings settings, bool running
});


@override $ShortsSettingsCopyWith<$Res> get settings;

}
/// @nodoc
class __$ShortsStateCopyWithImpl<$Res>
    implements _$ShortsStateCopyWith<$Res> {
  __$ShortsStateCopyWithImpl(this._self, this._then);

  final _ShortsState _self;
  final $Res Function(_ShortsState) _then;

/// Create a copy of ShortsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? jobs = null,Object? settings = null,Object? running = null,}) {
  return _then(_ShortsState(
jobs: null == jobs ? _self._jobs : jobs // ignore: cast_nullable_to_non_nullable
as List<ShortsJob>,settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as ShortsSettings,running: null == running ? _self.running : running // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of ShortsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShortsSettingsCopyWith<$Res> get settings {
  
  return $ShortsSettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}
}

// dart format on
