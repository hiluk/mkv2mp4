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
mixin _$Job {

 String get input; JobStatus get status; double get progress; String get message; String? get output;
/// Create a copy of Job
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JobCopyWith<Job> get copyWith => _$JobCopyWithImpl<Job>(this as Job, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Job&&(identical(other.input, input) || other.input == input)&&(identical(other.status, status) || other.status == status)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.message, message) || other.message == message)&&(identical(other.output, output) || other.output == output));
}


@override
int get hashCode => Object.hash(runtimeType,input,status,progress,message,output);

@override
String toString() {
  return 'Job(input: $input, status: $status, progress: $progress, message: $message, output: $output)';
}


}

/// @nodoc
abstract mixin class $JobCopyWith<$Res>  {
  factory $JobCopyWith(Job value, $Res Function(Job) _then) = _$JobCopyWithImpl;
@useResult
$Res call({
 String input, JobStatus status, double progress, String message, String? output
});




}
/// @nodoc
class _$JobCopyWithImpl<$Res>
    implements $JobCopyWith<$Res> {
  _$JobCopyWithImpl(this._self, this._then);

  final Job _self;
  final $Res Function(Job) _then;

/// Create a copy of Job
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? input = null,Object? status = null,Object? progress = null,Object? message = null,Object? output = freezed,}) {
  return _then(_self.copyWith(
input: null == input ? _self.input : input // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JobStatus,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,output: freezed == output ? _self.output : output // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Job].
extension JobPatterns on Job {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Job value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Job() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Job value)  $default,){
final _that = this;
switch (_that) {
case _Job():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Job value)?  $default,){
final _that = this;
switch (_that) {
case _Job() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String input,  JobStatus status,  double progress,  String message,  String? output)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Job() when $default != null:
return $default(_that.input,_that.status,_that.progress,_that.message,_that.output);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String input,  JobStatus status,  double progress,  String message,  String? output)  $default,) {final _that = this;
switch (_that) {
case _Job():
return $default(_that.input,_that.status,_that.progress,_that.message,_that.output);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String input,  JobStatus status,  double progress,  String message,  String? output)?  $default,) {final _that = this;
switch (_that) {
case _Job() when $default != null:
return $default(_that.input,_that.status,_that.progress,_that.message,_that.output);case _:
  return null;

}
}

}

/// @nodoc


class _Job extends Job {
  const _Job({required this.input, this.status = JobStatus.waiting, this.progress = 0, this.message = '', this.output}): super._();
  

@override final  String input;
@override@JsonKey() final  JobStatus status;
@override@JsonKey() final  double progress;
@override@JsonKey() final  String message;
@override final  String? output;

/// Create a copy of Job
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JobCopyWith<_Job> get copyWith => __$JobCopyWithImpl<_Job>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Job&&(identical(other.input, input) || other.input == input)&&(identical(other.status, status) || other.status == status)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.message, message) || other.message == message)&&(identical(other.output, output) || other.output == output));
}


@override
int get hashCode => Object.hash(runtimeType,input,status,progress,message,output);

@override
String toString() {
  return 'Job(input: $input, status: $status, progress: $progress, message: $message, output: $output)';
}


}

/// @nodoc
abstract mixin class _$JobCopyWith<$Res> implements $JobCopyWith<$Res> {
  factory _$JobCopyWith(_Job value, $Res Function(_Job) _then) = __$JobCopyWithImpl;
@override @useResult
$Res call({
 String input, JobStatus status, double progress, String message, String? output
});




}
/// @nodoc
class __$JobCopyWithImpl<$Res>
    implements _$JobCopyWith<$Res> {
  __$JobCopyWithImpl(this._self, this._then);

  final _Job _self;
  final $Res Function(_Job) _then;

/// Create a copy of Job
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? input = null,Object? status = null,Object? progress = null,Object? message = null,Object? output = freezed,}) {
  return _then(_Job(
input: null == input ? _self.input : input // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JobStatus,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,output: freezed == output ? _self.output : output // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$ConverterSettings {

/// Полное перекодирование вместо ремукса.
 bool get reencode; bool get overwrite;/// Папка для результатов; null — рядом с исходником.
 String? get outDir;
/// Create a copy of ConverterSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConverterSettingsCopyWith<ConverterSettings> get copyWith => _$ConverterSettingsCopyWithImpl<ConverterSettings>(this as ConverterSettings, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConverterSettings&&(identical(other.reencode, reencode) || other.reencode == reencode)&&(identical(other.overwrite, overwrite) || other.overwrite == overwrite)&&(identical(other.outDir, outDir) || other.outDir == outDir));
}


@override
int get hashCode => Object.hash(runtimeType,reencode,overwrite,outDir);

@override
String toString() {
  return 'ConverterSettings(reencode: $reencode, overwrite: $overwrite, outDir: $outDir)';
}


}

/// @nodoc
abstract mixin class $ConverterSettingsCopyWith<$Res>  {
  factory $ConverterSettingsCopyWith(ConverterSettings value, $Res Function(ConverterSettings) _then) = _$ConverterSettingsCopyWithImpl;
@useResult
$Res call({
 bool reencode, bool overwrite, String? outDir
});




}
/// @nodoc
class _$ConverterSettingsCopyWithImpl<$Res>
    implements $ConverterSettingsCopyWith<$Res> {
  _$ConverterSettingsCopyWithImpl(this._self, this._then);

  final ConverterSettings _self;
  final $Res Function(ConverterSettings) _then;

/// Create a copy of ConverterSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reencode = null,Object? overwrite = null,Object? outDir = freezed,}) {
  return _then(_self.copyWith(
reencode: null == reencode ? _self.reencode : reencode // ignore: cast_nullable_to_non_nullable
as bool,overwrite: null == overwrite ? _self.overwrite : overwrite // ignore: cast_nullable_to_non_nullable
as bool,outDir: freezed == outDir ? _self.outDir : outDir // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ConverterSettings].
extension ConverterSettingsPatterns on ConverterSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConverterSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConverterSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConverterSettings value)  $default,){
final _that = this;
switch (_that) {
case _ConverterSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConverterSettings value)?  $default,){
final _that = this;
switch (_that) {
case _ConverterSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool reencode,  bool overwrite,  String? outDir)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConverterSettings() when $default != null:
return $default(_that.reencode,_that.overwrite,_that.outDir);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool reencode,  bool overwrite,  String? outDir)  $default,) {final _that = this;
switch (_that) {
case _ConverterSettings():
return $default(_that.reencode,_that.overwrite,_that.outDir);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool reencode,  bool overwrite,  String? outDir)?  $default,) {final _that = this;
switch (_that) {
case _ConverterSettings() when $default != null:
return $default(_that.reencode,_that.overwrite,_that.outDir);case _:
  return null;

}
}

}

/// @nodoc


class _ConverterSettings implements ConverterSettings {
  const _ConverterSettings({this.reencode = false, this.overwrite = false, this.outDir});
  

/// Полное перекодирование вместо ремукса.
@override@JsonKey() final  bool reencode;
@override@JsonKey() final  bool overwrite;
/// Папка для результатов; null — рядом с исходником.
@override final  String? outDir;

/// Create a copy of ConverterSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConverterSettingsCopyWith<_ConverterSettings> get copyWith => __$ConverterSettingsCopyWithImpl<_ConverterSettings>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConverterSettings&&(identical(other.reencode, reencode) || other.reencode == reencode)&&(identical(other.overwrite, overwrite) || other.overwrite == overwrite)&&(identical(other.outDir, outDir) || other.outDir == outDir));
}


@override
int get hashCode => Object.hash(runtimeType,reencode,overwrite,outDir);

@override
String toString() {
  return 'ConverterSettings(reencode: $reencode, overwrite: $overwrite, outDir: $outDir)';
}


}

/// @nodoc
abstract mixin class _$ConverterSettingsCopyWith<$Res> implements $ConverterSettingsCopyWith<$Res> {
  factory _$ConverterSettingsCopyWith(_ConverterSettings value, $Res Function(_ConverterSettings) _then) = __$ConverterSettingsCopyWithImpl;
@override @useResult
$Res call({
 bool reencode, bool overwrite, String? outDir
});




}
/// @nodoc
class __$ConverterSettingsCopyWithImpl<$Res>
    implements _$ConverterSettingsCopyWith<$Res> {
  __$ConverterSettingsCopyWithImpl(this._self, this._then);

  final _ConverterSettings _self;
  final $Res Function(_ConverterSettings) _then;

/// Create a copy of ConverterSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reencode = null,Object? overwrite = null,Object? outDir = freezed,}) {
  return _then(_ConverterSettings(
reencode: null == reencode ? _self.reencode : reencode // ignore: cast_nullable_to_non_nullable
as bool,overwrite: null == overwrite ? _self.overwrite : overwrite // ignore: cast_nullable_to_non_nullable
as bool,outDir: freezed == outDir ? _self.outDir : outDir // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$ConverterState {

 List<Job> get jobs; ConverterSettings get settings; bool get running;
/// Create a copy of ConverterState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConverterStateCopyWith<ConverterState> get copyWith => _$ConverterStateCopyWithImpl<ConverterState>(this as ConverterState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConverterState&&const DeepCollectionEquality().equals(other.jobs, jobs)&&(identical(other.settings, settings) || other.settings == settings)&&(identical(other.running, running) || other.running == running));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(jobs),settings,running);

@override
String toString() {
  return 'ConverterState(jobs: $jobs, settings: $settings, running: $running)';
}


}

/// @nodoc
abstract mixin class $ConverterStateCopyWith<$Res>  {
  factory $ConverterStateCopyWith(ConverterState value, $Res Function(ConverterState) _then) = _$ConverterStateCopyWithImpl;
@useResult
$Res call({
 List<Job> jobs, ConverterSettings settings, bool running
});


$ConverterSettingsCopyWith<$Res> get settings;

}
/// @nodoc
class _$ConverterStateCopyWithImpl<$Res>
    implements $ConverterStateCopyWith<$Res> {
  _$ConverterStateCopyWithImpl(this._self, this._then);

  final ConverterState _self;
  final $Res Function(ConverterState) _then;

/// Create a copy of ConverterState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? jobs = null,Object? settings = null,Object? running = null,}) {
  return _then(_self.copyWith(
jobs: null == jobs ? _self.jobs : jobs // ignore: cast_nullable_to_non_nullable
as List<Job>,settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as ConverterSettings,running: null == running ? _self.running : running // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of ConverterState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConverterSettingsCopyWith<$Res> get settings {
  
  return $ConverterSettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}
}


/// Adds pattern-matching-related methods to [ConverterState].
extension ConverterStatePatterns on ConverterState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConverterState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConverterState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConverterState value)  $default,){
final _that = this;
switch (_that) {
case _ConverterState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConverterState value)?  $default,){
final _that = this;
switch (_that) {
case _ConverterState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Job> jobs,  ConverterSettings settings,  bool running)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConverterState() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Job> jobs,  ConverterSettings settings,  bool running)  $default,) {final _that = this;
switch (_that) {
case _ConverterState():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Job> jobs,  ConverterSettings settings,  bool running)?  $default,) {final _that = this;
switch (_that) {
case _ConverterState() when $default != null:
return $default(_that.jobs,_that.settings,_that.running);case _:
  return null;

}
}

}

/// @nodoc


class _ConverterState extends ConverterState {
  const _ConverterState({final  List<Job> jobs = const [], this.settings = const ConverterSettings(), this.running = false}): _jobs = jobs,super._();
  

 final  List<Job> _jobs;
@override@JsonKey() List<Job> get jobs {
  if (_jobs is EqualUnmodifiableListView) return _jobs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_jobs);
}

@override@JsonKey() final  ConverterSettings settings;
@override@JsonKey() final  bool running;

/// Create a copy of ConverterState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConverterStateCopyWith<_ConverterState> get copyWith => __$ConverterStateCopyWithImpl<_ConverterState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConverterState&&const DeepCollectionEquality().equals(other._jobs, _jobs)&&(identical(other.settings, settings) || other.settings == settings)&&(identical(other.running, running) || other.running == running));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_jobs),settings,running);

@override
String toString() {
  return 'ConverterState(jobs: $jobs, settings: $settings, running: $running)';
}


}

/// @nodoc
abstract mixin class _$ConverterStateCopyWith<$Res> implements $ConverterStateCopyWith<$Res> {
  factory _$ConverterStateCopyWith(_ConverterState value, $Res Function(_ConverterState) _then) = __$ConverterStateCopyWithImpl;
@override @useResult
$Res call({
 List<Job> jobs, ConverterSettings settings, bool running
});


@override $ConverterSettingsCopyWith<$Res> get settings;

}
/// @nodoc
class __$ConverterStateCopyWithImpl<$Res>
    implements _$ConverterStateCopyWith<$Res> {
  __$ConverterStateCopyWithImpl(this._self, this._then);

  final _ConverterState _self;
  final $Res Function(_ConverterState) _then;

/// Create a copy of ConverterState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? jobs = null,Object? settings = null,Object? running = null,}) {
  return _then(_ConverterState(
jobs: null == jobs ? _self._jobs : jobs // ignore: cast_nullable_to_non_nullable
as List<Job>,settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as ConverterSettings,running: null == running ? _self.running : running // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of ConverterState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConverterSettingsCopyWith<$Res> get settings {
  
  return $ConverterSettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}
}

// dart format on
