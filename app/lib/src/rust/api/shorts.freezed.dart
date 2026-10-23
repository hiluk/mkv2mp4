// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shorts.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ShortsEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShortsEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ShortsEvent()';
}


}

/// @nodoc
class $ShortsEventCopyWith<$Res>  {
$ShortsEventCopyWith(ShortsEvent _, $Res Function(ShortsEvent) __);
}


/// Adds pattern-matching-related methods to [ShortsEvent].
extension ShortsEventPatterns on ShortsEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ShortsEvent_Stage value)?  stage,TResult Function( ShortsEvent_Progress value)?  progress,TResult Function( ShortsEvent_Clip value)?  clip,TResult Function( ShortsEvent_Warning value)?  warning,TResult Function( ShortsEvent_Done value)?  done,TResult Function( ShortsEvent_Cancelled value)?  cancelled,TResult Function( ShortsEvent_Error value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ShortsEvent_Stage() when stage != null:
return stage(_that);case ShortsEvent_Progress() when progress != null:
return progress(_that);case ShortsEvent_Clip() when clip != null:
return clip(_that);case ShortsEvent_Warning() when warning != null:
return warning(_that);case ShortsEvent_Done() when done != null:
return done(_that);case ShortsEvent_Cancelled() when cancelled != null:
return cancelled(_that);case ShortsEvent_Error() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ShortsEvent_Stage value)  stage,required TResult Function( ShortsEvent_Progress value)  progress,required TResult Function( ShortsEvent_Clip value)  clip,required TResult Function( ShortsEvent_Warning value)  warning,required TResult Function( ShortsEvent_Done value)  done,required TResult Function( ShortsEvent_Cancelled value)  cancelled,required TResult Function( ShortsEvent_Error value)  error,}){
final _that = this;
switch (_that) {
case ShortsEvent_Stage():
return stage(_that);case ShortsEvent_Progress():
return progress(_that);case ShortsEvent_Clip():
return clip(_that);case ShortsEvent_Warning():
return warning(_that);case ShortsEvent_Done():
return done(_that);case ShortsEvent_Cancelled():
return cancelled(_that);case ShortsEvent_Error():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ShortsEvent_Stage value)?  stage,TResult? Function( ShortsEvent_Progress value)?  progress,TResult? Function( ShortsEvent_Clip value)?  clip,TResult? Function( ShortsEvent_Warning value)?  warning,TResult? Function( ShortsEvent_Done value)?  done,TResult? Function( ShortsEvent_Cancelled value)?  cancelled,TResult? Function( ShortsEvent_Error value)?  error,}){
final _that = this;
switch (_that) {
case ShortsEvent_Stage() when stage != null:
return stage(_that);case ShortsEvent_Progress() when progress != null:
return progress(_that);case ShortsEvent_Clip() when clip != null:
return clip(_that);case ShortsEvent_Warning() when warning != null:
return warning(_that);case ShortsEvent_Done() when done != null:
return done(_that);case ShortsEvent_Cancelled() when cancelled != null:
return cancelled(_that);case ShortsEvent_Error() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String message)?  stage,TResult Function( double value)?  progress,TResult Function( int index,  int total,  String path)?  clip,TResult Function( String message)?  warning,TResult Function( String dir,  int clips)?  done,TResult Function()?  cancelled,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ShortsEvent_Stage() when stage != null:
return stage(_that.message);case ShortsEvent_Progress() when progress != null:
return progress(_that.value);case ShortsEvent_Clip() when clip != null:
return clip(_that.index,_that.total,_that.path);case ShortsEvent_Warning() when warning != null:
return warning(_that.message);case ShortsEvent_Done() when done != null:
return done(_that.dir,_that.clips);case ShortsEvent_Cancelled() when cancelled != null:
return cancelled();case ShortsEvent_Error() when error != null:
return error(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String message)  stage,required TResult Function( double value)  progress,required TResult Function( int index,  int total,  String path)  clip,required TResult Function( String message)  warning,required TResult Function( String dir,  int clips)  done,required TResult Function()  cancelled,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case ShortsEvent_Stage():
return stage(_that.message);case ShortsEvent_Progress():
return progress(_that.value);case ShortsEvent_Clip():
return clip(_that.index,_that.total,_that.path);case ShortsEvent_Warning():
return warning(_that.message);case ShortsEvent_Done():
return done(_that.dir,_that.clips);case ShortsEvent_Cancelled():
return cancelled();case ShortsEvent_Error():
return error(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String message)?  stage,TResult? Function( double value)?  progress,TResult? Function( int index,  int total,  String path)?  clip,TResult? Function( String message)?  warning,TResult? Function( String dir,  int clips)?  done,TResult? Function()?  cancelled,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case ShortsEvent_Stage() when stage != null:
return stage(_that.message);case ShortsEvent_Progress() when progress != null:
return progress(_that.value);case ShortsEvent_Clip() when clip != null:
return clip(_that.index,_that.total,_that.path);case ShortsEvent_Warning() when warning != null:
return warning(_that.message);case ShortsEvent_Done() when done != null:
return done(_that.dir,_that.clips);case ShortsEvent_Cancelled() when cancelled != null:
return cancelled();case ShortsEvent_Error() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class ShortsEvent_Stage extends ShortsEvent {
  const ShortsEvent_Stage({required this.message}): super._();
  

 final  String message;

/// Create a copy of ShortsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShortsEvent_StageCopyWith<ShortsEvent_Stage> get copyWith => _$ShortsEvent_StageCopyWithImpl<ShortsEvent_Stage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShortsEvent_Stage&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ShortsEvent.stage(message: $message)';
}


}

/// @nodoc
abstract mixin class $ShortsEvent_StageCopyWith<$Res> implements $ShortsEventCopyWith<$Res> {
  factory $ShortsEvent_StageCopyWith(ShortsEvent_Stage value, $Res Function(ShortsEvent_Stage) _then) = _$ShortsEvent_StageCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ShortsEvent_StageCopyWithImpl<$Res>
    implements $ShortsEvent_StageCopyWith<$Res> {
  _$ShortsEvent_StageCopyWithImpl(this._self, this._then);

  final ShortsEvent_Stage _self;
  final $Res Function(ShortsEvent_Stage) _then;

/// Create a copy of ShortsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ShortsEvent_Stage(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ShortsEvent_Progress extends ShortsEvent {
  const ShortsEvent_Progress({required this.value}): super._();
  

 final  double value;

/// Create a copy of ShortsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShortsEvent_ProgressCopyWith<ShortsEvent_Progress> get copyWith => _$ShortsEvent_ProgressCopyWithImpl<ShortsEvent_Progress>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShortsEvent_Progress&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'ShortsEvent.progress(value: $value)';
}


}

/// @nodoc
abstract mixin class $ShortsEvent_ProgressCopyWith<$Res> implements $ShortsEventCopyWith<$Res> {
  factory $ShortsEvent_ProgressCopyWith(ShortsEvent_Progress value, $Res Function(ShortsEvent_Progress) _then) = _$ShortsEvent_ProgressCopyWithImpl;
@useResult
$Res call({
 double value
});




}
/// @nodoc
class _$ShortsEvent_ProgressCopyWithImpl<$Res>
    implements $ShortsEvent_ProgressCopyWith<$Res> {
  _$ShortsEvent_ProgressCopyWithImpl(this._self, this._then);

  final ShortsEvent_Progress _self;
  final $Res Function(ShortsEvent_Progress) _then;

/// Create a copy of ShortsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(ShortsEvent_Progress(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class ShortsEvent_Clip extends ShortsEvent {
  const ShortsEvent_Clip({required this.index, required this.total, required this.path}): super._();
  

 final  int index;
 final  int total;
 final  String path;

/// Create a copy of ShortsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShortsEvent_ClipCopyWith<ShortsEvent_Clip> get copyWith => _$ShortsEvent_ClipCopyWithImpl<ShortsEvent_Clip>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShortsEvent_Clip&&(identical(other.index, index) || other.index == index)&&(identical(other.total, total) || other.total == total)&&(identical(other.path, path) || other.path == path));
}


@override
int get hashCode => Object.hash(runtimeType,index,total,path);

@override
String toString() {
  return 'ShortsEvent.clip(index: $index, total: $total, path: $path)';
}


}

/// @nodoc
abstract mixin class $ShortsEvent_ClipCopyWith<$Res> implements $ShortsEventCopyWith<$Res> {
  factory $ShortsEvent_ClipCopyWith(ShortsEvent_Clip value, $Res Function(ShortsEvent_Clip) _then) = _$ShortsEvent_ClipCopyWithImpl;
@useResult
$Res call({
 int index, int total, String path
});




}
/// @nodoc
class _$ShortsEvent_ClipCopyWithImpl<$Res>
    implements $ShortsEvent_ClipCopyWith<$Res> {
  _$ShortsEvent_ClipCopyWithImpl(this._self, this._then);

  final ShortsEvent_Clip _self;
  final $Res Function(ShortsEvent_Clip) _then;

/// Create a copy of ShortsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? index = null,Object? total = null,Object? path = null,}) {
  return _then(ShortsEvent_Clip(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ShortsEvent_Warning extends ShortsEvent {
  const ShortsEvent_Warning({required this.message}): super._();
  

 final  String message;

/// Create a copy of ShortsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShortsEvent_WarningCopyWith<ShortsEvent_Warning> get copyWith => _$ShortsEvent_WarningCopyWithImpl<ShortsEvent_Warning>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShortsEvent_Warning&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ShortsEvent.warning(message: $message)';
}


}

/// @nodoc
abstract mixin class $ShortsEvent_WarningCopyWith<$Res> implements $ShortsEventCopyWith<$Res> {
  factory $ShortsEvent_WarningCopyWith(ShortsEvent_Warning value, $Res Function(ShortsEvent_Warning) _then) = _$ShortsEvent_WarningCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ShortsEvent_WarningCopyWithImpl<$Res>
    implements $ShortsEvent_WarningCopyWith<$Res> {
  _$ShortsEvent_WarningCopyWithImpl(this._self, this._then);

  final ShortsEvent_Warning _self;
  final $Res Function(ShortsEvent_Warning) _then;

/// Create a copy of ShortsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ShortsEvent_Warning(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ShortsEvent_Done extends ShortsEvent {
  const ShortsEvent_Done({required this.dir, required this.clips}): super._();
  

 final  String dir;
 final  int clips;

/// Create a copy of ShortsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShortsEvent_DoneCopyWith<ShortsEvent_Done> get copyWith => _$ShortsEvent_DoneCopyWithImpl<ShortsEvent_Done>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShortsEvent_Done&&(identical(other.dir, dir) || other.dir == dir)&&(identical(other.clips, clips) || other.clips == clips));
}


@override
int get hashCode => Object.hash(runtimeType,dir,clips);

@override
String toString() {
  return 'ShortsEvent.done(dir: $dir, clips: $clips)';
}


}

/// @nodoc
abstract mixin class $ShortsEvent_DoneCopyWith<$Res> implements $ShortsEventCopyWith<$Res> {
  factory $ShortsEvent_DoneCopyWith(ShortsEvent_Done value, $Res Function(ShortsEvent_Done) _then) = _$ShortsEvent_DoneCopyWithImpl;
@useResult
$Res call({
 String dir, int clips
});




}
/// @nodoc
class _$ShortsEvent_DoneCopyWithImpl<$Res>
    implements $ShortsEvent_DoneCopyWith<$Res> {
  _$ShortsEvent_DoneCopyWithImpl(this._self, this._then);

  final ShortsEvent_Done _self;
  final $Res Function(ShortsEvent_Done) _then;

/// Create a copy of ShortsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? dir = null,Object? clips = null,}) {
  return _then(ShortsEvent_Done(
dir: null == dir ? _self.dir : dir // ignore: cast_nullable_to_non_nullable
as String,clips: null == clips ? _self.clips : clips // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class ShortsEvent_Cancelled extends ShortsEvent {
  const ShortsEvent_Cancelled(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShortsEvent_Cancelled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ShortsEvent.cancelled()';
}


}




/// @nodoc


class ShortsEvent_Error extends ShortsEvent {
  const ShortsEvent_Error({required this.message}): super._();
  

 final  String message;

/// Create a copy of ShortsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShortsEvent_ErrorCopyWith<ShortsEvent_Error> get copyWith => _$ShortsEvent_ErrorCopyWithImpl<ShortsEvent_Error>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShortsEvent_Error&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ShortsEvent.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $ShortsEvent_ErrorCopyWith<$Res> implements $ShortsEventCopyWith<$Res> {
  factory $ShortsEvent_ErrorCopyWith(ShortsEvent_Error value, $Res Function(ShortsEvent_Error) _then) = _$ShortsEvent_ErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ShortsEvent_ErrorCopyWithImpl<$Res>
    implements $ShortsEvent_ErrorCopyWith<$Res> {
  _$ShortsEvent_ErrorCopyWithImpl(this._self, this._then);

  final ShortsEvent_Error _self;
  final $Res Function(ShortsEvent_Error) _then;

/// Create a copy of ShortsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ShortsEvent_Error(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
