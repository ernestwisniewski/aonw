// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gamepad_control_frame.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GamepadControlFrame {

 GamepadMapDirection? get cursorStep; double get cameraX; double get cameraY; double get zoom; bool get confirmPressed; bool get cancelPressed; bool get inspectPressed; bool get moveModePressed; bool get hudFocusPreviousPressed; bool get hudFocusNextPressed; bool get focusPreviousPressed; bool get focusNextPressed; bool get primaryActionPressed;
/// Create a copy of GamepadControlFrame
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GamepadControlFrameCopyWith<GamepadControlFrame> get copyWith => _$GamepadControlFrameCopyWithImpl<GamepadControlFrame>(this as GamepadControlFrame, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GamepadControlFrame&&(identical(other.cursorStep, cursorStep) || other.cursorStep == cursorStep)&&(identical(other.cameraX, cameraX) || other.cameraX == cameraX)&&(identical(other.cameraY, cameraY) || other.cameraY == cameraY)&&(identical(other.zoom, zoom) || other.zoom == zoom)&&(identical(other.confirmPressed, confirmPressed) || other.confirmPressed == confirmPressed)&&(identical(other.cancelPressed, cancelPressed) || other.cancelPressed == cancelPressed)&&(identical(other.inspectPressed, inspectPressed) || other.inspectPressed == inspectPressed)&&(identical(other.moveModePressed, moveModePressed) || other.moveModePressed == moveModePressed)&&(identical(other.hudFocusPreviousPressed, hudFocusPreviousPressed) || other.hudFocusPreviousPressed == hudFocusPreviousPressed)&&(identical(other.hudFocusNextPressed, hudFocusNextPressed) || other.hudFocusNextPressed == hudFocusNextPressed)&&(identical(other.focusPreviousPressed, focusPreviousPressed) || other.focusPreviousPressed == focusPreviousPressed)&&(identical(other.focusNextPressed, focusNextPressed) || other.focusNextPressed == focusNextPressed)&&(identical(other.primaryActionPressed, primaryActionPressed) || other.primaryActionPressed == primaryActionPressed));
}


@override
int get hashCode => Object.hash(runtimeType,cursorStep,cameraX,cameraY,zoom,confirmPressed,cancelPressed,inspectPressed,moveModePressed,hudFocusPreviousPressed,hudFocusNextPressed,focusPreviousPressed,focusNextPressed,primaryActionPressed);

@override
String toString() {
  return 'GamepadControlFrame(cursorStep: $cursorStep, cameraX: $cameraX, cameraY: $cameraY, zoom: $zoom, confirmPressed: $confirmPressed, cancelPressed: $cancelPressed, inspectPressed: $inspectPressed, moveModePressed: $moveModePressed, hudFocusPreviousPressed: $hudFocusPreviousPressed, hudFocusNextPressed: $hudFocusNextPressed, focusPreviousPressed: $focusPreviousPressed, focusNextPressed: $focusNextPressed, primaryActionPressed: $primaryActionPressed)';
}


}

/// @nodoc
abstract mixin class $GamepadControlFrameCopyWith<$Res>  {
  factory $GamepadControlFrameCopyWith(GamepadControlFrame value, $Res Function(GamepadControlFrame) _then) = _$GamepadControlFrameCopyWithImpl;
@useResult
$Res call({
 GamepadMapDirection? cursorStep, double cameraX, double cameraY, double zoom, bool confirmPressed, bool cancelPressed, bool inspectPressed, bool moveModePressed, bool hudFocusPreviousPressed, bool hudFocusNextPressed, bool focusPreviousPressed, bool focusNextPressed, bool primaryActionPressed
});




}
/// @nodoc
class _$GamepadControlFrameCopyWithImpl<$Res>
    implements $GamepadControlFrameCopyWith<$Res> {
  _$GamepadControlFrameCopyWithImpl(this._self, this._then);

  final GamepadControlFrame _self;
  final $Res Function(GamepadControlFrame) _then;

/// Create a copy of GamepadControlFrame
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cursorStep = freezed,Object? cameraX = null,Object? cameraY = null,Object? zoom = null,Object? confirmPressed = null,Object? cancelPressed = null,Object? inspectPressed = null,Object? moveModePressed = null,Object? hudFocusPreviousPressed = null,Object? hudFocusNextPressed = null,Object? focusPreviousPressed = null,Object? focusNextPressed = null,Object? primaryActionPressed = null,}) {
  return _then(_self.copyWith(
cursorStep: freezed == cursorStep ? _self.cursorStep : cursorStep // ignore: cast_nullable_to_non_nullable
as GamepadMapDirection?,cameraX: null == cameraX ? _self.cameraX : cameraX // ignore: cast_nullable_to_non_nullable
as double,cameraY: null == cameraY ? _self.cameraY : cameraY // ignore: cast_nullable_to_non_nullable
as double,zoom: null == zoom ? _self.zoom : zoom // ignore: cast_nullable_to_non_nullable
as double,confirmPressed: null == confirmPressed ? _self.confirmPressed : confirmPressed // ignore: cast_nullable_to_non_nullable
as bool,cancelPressed: null == cancelPressed ? _self.cancelPressed : cancelPressed // ignore: cast_nullable_to_non_nullable
as bool,inspectPressed: null == inspectPressed ? _self.inspectPressed : inspectPressed // ignore: cast_nullable_to_non_nullable
as bool,moveModePressed: null == moveModePressed ? _self.moveModePressed : moveModePressed // ignore: cast_nullable_to_non_nullable
as bool,hudFocusPreviousPressed: null == hudFocusPreviousPressed ? _self.hudFocusPreviousPressed : hudFocusPreviousPressed // ignore: cast_nullable_to_non_nullable
as bool,hudFocusNextPressed: null == hudFocusNextPressed ? _self.hudFocusNextPressed : hudFocusNextPressed // ignore: cast_nullable_to_non_nullable
as bool,focusPreviousPressed: null == focusPreviousPressed ? _self.focusPreviousPressed : focusPreviousPressed // ignore: cast_nullable_to_non_nullable
as bool,focusNextPressed: null == focusNextPressed ? _self.focusNextPressed : focusNextPressed // ignore: cast_nullable_to_non_nullable
as bool,primaryActionPressed: null == primaryActionPressed ? _self.primaryActionPressed : primaryActionPressed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [GamepadControlFrame].
extension GamepadControlFramePatterns on GamepadControlFrame {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GamepadControlFrame value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GamepadControlFrame() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GamepadControlFrame value)  $default,){
final _that = this;
switch (_that) {
case _GamepadControlFrame():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GamepadControlFrame value)?  $default,){
final _that = this;
switch (_that) {
case _GamepadControlFrame() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GamepadMapDirection? cursorStep,  double cameraX,  double cameraY,  double zoom,  bool confirmPressed,  bool cancelPressed,  bool inspectPressed,  bool moveModePressed,  bool hudFocusPreviousPressed,  bool hudFocusNextPressed,  bool focusPreviousPressed,  bool focusNextPressed,  bool primaryActionPressed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GamepadControlFrame() when $default != null:
return $default(_that.cursorStep,_that.cameraX,_that.cameraY,_that.zoom,_that.confirmPressed,_that.cancelPressed,_that.inspectPressed,_that.moveModePressed,_that.hudFocusPreviousPressed,_that.hudFocusNextPressed,_that.focusPreviousPressed,_that.focusNextPressed,_that.primaryActionPressed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GamepadMapDirection? cursorStep,  double cameraX,  double cameraY,  double zoom,  bool confirmPressed,  bool cancelPressed,  bool inspectPressed,  bool moveModePressed,  bool hudFocusPreviousPressed,  bool hudFocusNextPressed,  bool focusPreviousPressed,  bool focusNextPressed,  bool primaryActionPressed)  $default,) {final _that = this;
switch (_that) {
case _GamepadControlFrame():
return $default(_that.cursorStep,_that.cameraX,_that.cameraY,_that.zoom,_that.confirmPressed,_that.cancelPressed,_that.inspectPressed,_that.moveModePressed,_that.hudFocusPreviousPressed,_that.hudFocusNextPressed,_that.focusPreviousPressed,_that.focusNextPressed,_that.primaryActionPressed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GamepadMapDirection? cursorStep,  double cameraX,  double cameraY,  double zoom,  bool confirmPressed,  bool cancelPressed,  bool inspectPressed,  bool moveModePressed,  bool hudFocusPreviousPressed,  bool hudFocusNextPressed,  bool focusPreviousPressed,  bool focusNextPressed,  bool primaryActionPressed)?  $default,) {final _that = this;
switch (_that) {
case _GamepadControlFrame() when $default != null:
return $default(_that.cursorStep,_that.cameraX,_that.cameraY,_that.zoom,_that.confirmPressed,_that.cancelPressed,_that.inspectPressed,_that.moveModePressed,_that.hudFocusPreviousPressed,_that.hudFocusNextPressed,_that.focusPreviousPressed,_that.focusNextPressed,_that.primaryActionPressed);case _:
  return null;

}
}

}

/// @nodoc


class _GamepadControlFrame extends GamepadControlFrame {
  const _GamepadControlFrame({this.cursorStep, this.cameraX = 0, this.cameraY = 0, this.zoom = 0, this.confirmPressed = false, this.cancelPressed = false, this.inspectPressed = false, this.moveModePressed = false, this.hudFocusPreviousPressed = false, this.hudFocusNextPressed = false, this.focusPreviousPressed = false, this.focusNextPressed = false, this.primaryActionPressed = false}): super._();
  

@override final  GamepadMapDirection? cursorStep;
@override@JsonKey() final  double cameraX;
@override@JsonKey() final  double cameraY;
@override@JsonKey() final  double zoom;
@override@JsonKey() final  bool confirmPressed;
@override@JsonKey() final  bool cancelPressed;
@override@JsonKey() final  bool inspectPressed;
@override@JsonKey() final  bool moveModePressed;
@override@JsonKey() final  bool hudFocusPreviousPressed;
@override@JsonKey() final  bool hudFocusNextPressed;
@override@JsonKey() final  bool focusPreviousPressed;
@override@JsonKey() final  bool focusNextPressed;
@override@JsonKey() final  bool primaryActionPressed;

/// Create a copy of GamepadControlFrame
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GamepadControlFrameCopyWith<_GamepadControlFrame> get copyWith => __$GamepadControlFrameCopyWithImpl<_GamepadControlFrame>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GamepadControlFrame&&(identical(other.cursorStep, cursorStep) || other.cursorStep == cursorStep)&&(identical(other.cameraX, cameraX) || other.cameraX == cameraX)&&(identical(other.cameraY, cameraY) || other.cameraY == cameraY)&&(identical(other.zoom, zoom) || other.zoom == zoom)&&(identical(other.confirmPressed, confirmPressed) || other.confirmPressed == confirmPressed)&&(identical(other.cancelPressed, cancelPressed) || other.cancelPressed == cancelPressed)&&(identical(other.inspectPressed, inspectPressed) || other.inspectPressed == inspectPressed)&&(identical(other.moveModePressed, moveModePressed) || other.moveModePressed == moveModePressed)&&(identical(other.hudFocusPreviousPressed, hudFocusPreviousPressed) || other.hudFocusPreviousPressed == hudFocusPreviousPressed)&&(identical(other.hudFocusNextPressed, hudFocusNextPressed) || other.hudFocusNextPressed == hudFocusNextPressed)&&(identical(other.focusPreviousPressed, focusPreviousPressed) || other.focusPreviousPressed == focusPreviousPressed)&&(identical(other.focusNextPressed, focusNextPressed) || other.focusNextPressed == focusNextPressed)&&(identical(other.primaryActionPressed, primaryActionPressed) || other.primaryActionPressed == primaryActionPressed));
}


@override
int get hashCode => Object.hash(runtimeType,cursorStep,cameraX,cameraY,zoom,confirmPressed,cancelPressed,inspectPressed,moveModePressed,hudFocusPreviousPressed,hudFocusNextPressed,focusPreviousPressed,focusNextPressed,primaryActionPressed);

@override
String toString() {
  return 'GamepadControlFrame(cursorStep: $cursorStep, cameraX: $cameraX, cameraY: $cameraY, zoom: $zoom, confirmPressed: $confirmPressed, cancelPressed: $cancelPressed, inspectPressed: $inspectPressed, moveModePressed: $moveModePressed, hudFocusPreviousPressed: $hudFocusPreviousPressed, hudFocusNextPressed: $hudFocusNextPressed, focusPreviousPressed: $focusPreviousPressed, focusNextPressed: $focusNextPressed, primaryActionPressed: $primaryActionPressed)';
}


}

/// @nodoc
abstract mixin class _$GamepadControlFrameCopyWith<$Res> implements $GamepadControlFrameCopyWith<$Res> {
  factory _$GamepadControlFrameCopyWith(_GamepadControlFrame value, $Res Function(_GamepadControlFrame) _then) = __$GamepadControlFrameCopyWithImpl;
@override @useResult
$Res call({
 GamepadMapDirection? cursorStep, double cameraX, double cameraY, double zoom, bool confirmPressed, bool cancelPressed, bool inspectPressed, bool moveModePressed, bool hudFocusPreviousPressed, bool hudFocusNextPressed, bool focusPreviousPressed, bool focusNextPressed, bool primaryActionPressed
});




}
/// @nodoc
class __$GamepadControlFrameCopyWithImpl<$Res>
    implements _$GamepadControlFrameCopyWith<$Res> {
  __$GamepadControlFrameCopyWithImpl(this._self, this._then);

  final _GamepadControlFrame _self;
  final $Res Function(_GamepadControlFrame) _then;

/// Create a copy of GamepadControlFrame
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cursorStep = freezed,Object? cameraX = null,Object? cameraY = null,Object? zoom = null,Object? confirmPressed = null,Object? cancelPressed = null,Object? inspectPressed = null,Object? moveModePressed = null,Object? hudFocusPreviousPressed = null,Object? hudFocusNextPressed = null,Object? focusPreviousPressed = null,Object? focusNextPressed = null,Object? primaryActionPressed = null,}) {
  return _then(_GamepadControlFrame(
cursorStep: freezed == cursorStep ? _self.cursorStep : cursorStep // ignore: cast_nullable_to_non_nullable
as GamepadMapDirection?,cameraX: null == cameraX ? _self.cameraX : cameraX // ignore: cast_nullable_to_non_nullable
as double,cameraY: null == cameraY ? _self.cameraY : cameraY // ignore: cast_nullable_to_non_nullable
as double,zoom: null == zoom ? _self.zoom : zoom // ignore: cast_nullable_to_non_nullable
as double,confirmPressed: null == confirmPressed ? _self.confirmPressed : confirmPressed // ignore: cast_nullable_to_non_nullable
as bool,cancelPressed: null == cancelPressed ? _self.cancelPressed : cancelPressed // ignore: cast_nullable_to_non_nullable
as bool,inspectPressed: null == inspectPressed ? _self.inspectPressed : inspectPressed // ignore: cast_nullable_to_non_nullable
as bool,moveModePressed: null == moveModePressed ? _self.moveModePressed : moveModePressed // ignore: cast_nullable_to_non_nullable
as bool,hudFocusPreviousPressed: null == hudFocusPreviousPressed ? _self.hudFocusPreviousPressed : hudFocusPreviousPressed // ignore: cast_nullable_to_non_nullable
as bool,hudFocusNextPressed: null == hudFocusNextPressed ? _self.hudFocusNextPressed : hudFocusNextPressed // ignore: cast_nullable_to_non_nullable
as bool,focusPreviousPressed: null == focusPreviousPressed ? _self.focusPreviousPressed : focusPreviousPressed // ignore: cast_nullable_to_non_nullable
as bool,focusNextPressed: null == focusNextPressed ? _self.focusNextPressed : focusNextPressed // ignore: cast_nullable_to_non_nullable
as bool,primaryActionPressed: null == primaryActionPressed ? _self.primaryActionPressed : primaryActionPressed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
