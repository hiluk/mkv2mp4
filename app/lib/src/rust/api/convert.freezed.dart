// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'convert.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ConvertEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConvertEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ConvertEvent()';
}


}

/// @nodoc
class $ConvertEventCopyWith<$Res>  {
$ConvertEventCopyWith(ConvertEvent _, $Res Function(ConvertEvent) __);
}


/// Adds pattern-matching-related methods to [ConvertEvent].
extension ConvertEventPatterns on ConvertEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ConvertEvent_Attempt value)?  attempt,TResult Function( ConvertEvent_Info value)?  info,TResult Function( ConvertEvent_Progress value)?  progress,TResult Function( ConvertEvent_Done value)?  done,TResult Function( ConvertEvent_Skipped value)?  skipped,TResult Function( ConvertEvent_Cancelled value)?  cancelled,TResult Function( ConvertEvent_Error value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ConvertEvent_Attempt() when attempt != null:
return attempt(_that);case ConvertEvent_Info() when info != null:
return info(_that);case ConvertEvent_Progress() when progress != null:
return progress(_that);case ConvertEvent_Done() when done != null:
return done(_that);case ConvertEvent_Skipped() when skipped != null:
return skipped(_that);case ConvertEvent_Cancelled() when cancelled != null:
return cancelled(_that);case ConvertEvent_Error() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ConvertEvent_Attempt value)  attempt,required TResult Function( ConvertEvent_Info value)  info,required TResult Function( ConvertEvent_Progress value)  progress,required TResult Function( ConvertEvent_Done value)  done,required TResult Function( ConvertEvent_Skipped value)  skipped,required TResult Function( ConvertEvent_Cancelled value)  cancelled,required TResult Function( ConvertEvent_Error value)  error,}){
final _that = this;
switch (_that) {
case ConvertEvent_Attempt():
return attempt(_that);case ConvertEvent_Info():
return info(_that);case ConvertEvent_Progress():
return progress(_that);case ConvertEvent_Done():
return done(_that);case ConvertEvent_Skipped():
return skipped(_that);case ConvertEvent_Cancelled():
return cancelled(_that);case ConvertEvent_Error():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ConvertEvent_Attempt value)?  attempt,TResult? Function( ConvertEvent_Info value)?  info,TResult? Function( ConvertEvent_Progress value)?  progress,TResult? Function( ConvertEvent_Done value)?  done,TResult? Function( ConvertEvent_Skipped value)?  skipped,TResult? Function( ConvertEvent_Cancelled value)?  cancelled,TResult? Function( ConvertEvent_Error value)?  error,}){
final _that = this;
switch (_that) {
case ConvertEvent_Attempt() when attempt != null:
return attempt(_that);case ConvertEvent_Info() when info != null:
return info(_that);case ConvertEvent_Progress() when progress != null:
return progress(_that);case ConvertEvent_Done() when done != null:
return done(_that);case ConvertEvent_Skipped() when skipped != null:
return skipped(_that);case ConvertEvent_Cancelled() when cancelled != null:
return cancelled(_that);case ConvertEvent_Error() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String label)?  attempt,TResult Function( String message)?  info,TResult Function( double value)?  progress,TResult Function( String output)?  done,TResult Function( String output)?  skipped,TResult Function()?  cancelled,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ConvertEvent_Attempt() when attempt != null:
return attempt(_that.label);case ConvertEvent_Info() when info != null:
return info(_that.message);case ConvertEvent_Progress() when progress != null:
return progress(_that.value);case ConvertEvent_Done() when done != null:
return done(_that.output);case ConvertEvent_Skipped() when skipped != null:
return skipped(_that.output);case ConvertEvent_Cancelled() when cancelled != null:
return cancelled();case ConvertEvent_Error() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String label)  attempt,required TResult Function( String message)  info,required TResult Function( double value)  progress,required TResult Function( String output)  done,required TResult Function( String output)  skipped,required TResult Function()  cancelled,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case ConvertEvent_Attempt():
return attempt(_that.label);case ConvertEvent_Info():
return info(_that.message);case ConvertEvent_Progress():
return progress(_that.value);case ConvertEvent_Done():
return done(_that.output);case ConvertEvent_Skipped():
return skipped(_that.output);case ConvertEvent_Cancelled():
return cancelled();case ConvertEvent_Error():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String label)?  attempt,TResult? Function( String message)?  info,TResult? Function( double value)?  progress,TResult? Function( String output)?  done,TResult? Function( String output)?  skipped,TResult? Function()?  cancelled,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case ConvertEvent_Attempt() when attempt != null:
return attempt(_that.label);case ConvertEvent_Info() when info != null:
return info(_that.message);case ConvertEvent_Progress() when progress != null:
return progress(_that.value);case ConvertEvent_Done() when done != null:
return done(_that.output);case ConvertEvent_Skipped() when skipped != null:
return skipped(_that.output);case ConvertEvent_Cancelled() when cancelled != null:
return cancelled();case ConvertEvent_Error() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class ConvertEvent_Attempt extends ConvertEvent {
  const ConvertEvent_Attempt({required this.label}): super._();
  

 final  String label;

/// Create a copy of ConvertEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConvertEvent_AttemptCopyWith<ConvertEvent_Attempt> get copyWith => _$ConvertEvent_AttemptCopyWithImpl<ConvertEvent_Attempt>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConvertEvent_Attempt&&(identical(other.label, label) || other.label == label));
}


@override
int get hashCode => Object.hash(runtimeType,label);

@override
String toString() {
  return 'ConvertEvent.attempt(label: $label)';
}


}

/// @nodoc
abstract mixin class $ConvertEvent_AttemptCopyWith<$Res> implements $ConvertEventCopyWith<$Res> {
  factory $ConvertEvent_AttemptCopyWith(ConvertEvent_Attempt value, $Res Function(ConvertEvent_Attempt) _then) = _$ConvertEvent_AttemptCopyWithImpl;
@useResult
$Res call({
 String label
});




}
/// @nodoc
class _$ConvertEvent_AttemptCopyWithImpl<$Res>
    implements $ConvertEvent_AttemptCopyWith<$Res> {
  _$ConvertEvent_AttemptCopyWithImpl(this._self, this._then);

  final ConvertEvent_Attempt _self;
  final $Res Function(ConvertEvent_Attempt) _then;

/// Create a copy of ConvertEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? label = null,}) {
  return _then(ConvertEvent_Attempt(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ConvertEvent_Info extends ConvertEvent {
  const ConvertEvent_Info({required this.message}): super._();
  

 final  String message;

/// Create a copy of ConvertEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConvertEvent_InfoCopyWith<ConvertEvent_Info> get copyWith => _$ConvertEvent_InfoCopyWithImpl<ConvertEvent_Info>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConvertEvent_Info&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ConvertEvent.info(message: $message)';
}


}

/// @nodoc
abstract mixin class $ConvertEvent_InfoCopyWith<$Res> implements $ConvertEventCopyWith<$Res> {
  factory $ConvertEvent_InfoCopyWith(ConvertEvent_Info value, $Res Function(ConvertEvent_Info) _then) = _$ConvertEvent_InfoCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ConvertEvent_InfoCopyWithImpl<$Res>
    implements $ConvertEvent_InfoCopyWith<$Res> {
  _$ConvertEvent_InfoCopyWithImpl(this._self, this._then);

  final ConvertEvent_Info _self;
  final $Res Function(ConvertEvent_Info) _then;

/// Create a copy of ConvertEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ConvertEvent_Info(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ConvertEvent_Progress extends ConvertEvent {
  const ConvertEvent_Progress({required this.value}): super._();
  

 final  double value;

/// Create a copy of ConvertEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConvertEvent_ProgressCopyWith<ConvertEvent_Progress> get copyWith => _$ConvertEvent_ProgressCopyWithImpl<ConvertEvent_Progress>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConvertEvent_Progress&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'ConvertEvent.progress(value: $value)';
}


}

/// @nodoc
abstract mixin class $ConvertEvent_ProgressCopyWith<$Res> implements $ConvertEventCopyWith<$Res> {
  factory $ConvertEvent_ProgressCopyWith(ConvertEvent_Progress value, $Res Function(ConvertEvent_Progress) _then) = _$ConvertEvent_ProgressCopyWithImpl;
@useResult
$Res call({
 double value
});




}
/// @nodoc
class _$ConvertEvent_ProgressCopyWithImpl<$Res>
    implements $ConvertEvent_ProgressCopyWith<$Res> {
  _$ConvertEvent_ProgressCopyWithImpl(this._self, this._then);

  final ConvertEvent_Progress _self;
  final $Res Function(ConvertEvent_Progress) _then;

/// Create a copy of ConvertEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(ConvertEvent_Progress(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class ConvertEvent_Done extends ConvertEvent {
  const ConvertEvent_Done({required this.output}): super._();
  

 final  String output;

/// Create a copy of ConvertEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConvertEvent_DoneCopyWith<ConvertEvent_Done> get copyWith => _$ConvertEvent_DoneCopyWithImpl<ConvertEvent_Done>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConvertEvent_Done&&(identical(other.output, output) || other.output == output));
}


@override
int get hashCode => Object.hash(runtimeType,output);

@override
String toString() {
  return 'ConvertEvent.done(output: $output)';
}


}

/// @nodoc
abstract mixin class $ConvertEvent_DoneCopyWith<$Res> implements $ConvertEventCopyWith<$Res> {
  factory $ConvertEvent_DoneCopyWith(ConvertEvent_Done value, $Res Function(ConvertEvent_Done) _then) = _$ConvertEvent_DoneCopyWithImpl;
@useResult
$Res call({
 String output
});




}
/// @nodoc
class _$ConvertEvent_DoneCopyWithImpl<$Res>
    implements $ConvertEvent_DoneCopyWith<$Res> {
  _$ConvertEvent_DoneCopyWithImpl(this._self, this._then);

  final ConvertEvent_Done _self;
  final $Res Function(ConvertEvent_Done) _then;

/// Create a copy of ConvertEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? output = null,}) {
  return _then(ConvertEvent_Done(
output: null == output ? _self.output : output // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ConvertEvent_Skipped extends ConvertEvent {
  const ConvertEvent_Skipped({required this.output}): super._();
  

 final  String output;

/// Create a copy of ConvertEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConvertEvent_SkippedCopyWith<ConvertEvent_Skipped> get copyWith => _$ConvertEvent_SkippedCopyWithImpl<ConvertEvent_Skipped>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConvertEvent_Skipped&&(identical(other.output, output) || other.output == output));
}


@override
int get hashCode => Object.hash(runtimeType,output);

@override
String toString() {
  return 'ConvertEvent.skipped(output: $output)';
}


}

/// @nodoc
abstract mixin class $ConvertEvent_SkippedCopyWith<$Res> implements $ConvertEventCopyWith<$Res> {
  factory $ConvertEvent_SkippedCopyWith(ConvertEvent_Skipped value, $Res Function(ConvertEvent_Skipped) _then) = _$ConvertEvent_SkippedCopyWithImpl;
@useResult
$Res call({
 String output
});




}
/// @nodoc
class _$ConvertEvent_SkippedCopyWithImpl<$Res>
    implements $ConvertEvent_SkippedCopyWith<$Res> {
  _$ConvertEvent_SkippedCopyWithImpl(this._self, this._then);

  final ConvertEvent_Skipped _self;
  final $Res Function(ConvertEvent_Skipped) _then;

/// Create a copy of ConvertEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? output = null,}) {
  return _then(ConvertEvent_Skipped(
output: null == output ? _self.output : output // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ConvertEvent_Cancelled extends ConvertEvent {
  const ConvertEvent_Cancelled(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConvertEvent_Cancelled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ConvertEvent.cancelled()';
}


}




/// @nodoc


class ConvertEvent_Error extends ConvertEvent {
  const ConvertEvent_Error({required this.message}): super._();
  

 final  String message;

/// Create a copy of ConvertEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConvertEvent_ErrorCopyWith<ConvertEvent_Error> get copyWith => _$ConvertEvent_ErrorCopyWithImpl<ConvertEvent_Error>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConvertEvent_Error&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ConvertEvent.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $ConvertEvent_ErrorCopyWith<$Res> implements $ConvertEventCopyWith<$Res> {
  factory $ConvertEvent_ErrorCopyWith(ConvertEvent_Error value, $Res Function(ConvertEvent_Error) _then) = _$ConvertEvent_ErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ConvertEvent_ErrorCopyWithImpl<$Res>
    implements $ConvertEvent_ErrorCopyWith<$Res> {
  _$ConvertEvent_ErrorCopyWithImpl(this._self, this._then);

  final ConvertEvent_Error _self;
  final $Res Function(ConvertEvent_Error) _then;

/// Create a copy of ConvertEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ConvertEvent_Error(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
