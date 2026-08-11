// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'diplomatic_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DiplomaticMessage {

 String get id; String get fromPlayerId; String get toPlayerId; DiplomaticMessageTopic get topic; DiplomaticMessageCategory get category; int get createdTurn; int get expiresOnTurn; DiplomaticMessageResponse? get response; int? get respondedTurn; int get relationScoreDelta; int? get relationScoreAfter; int? get promiseDueTurn; bool get promiseBroken;
/// Create a copy of DiplomaticMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiplomaticMessageCopyWith<DiplomaticMessage> get copyWith => _$DiplomaticMessageCopyWithImpl<DiplomaticMessage>(this as DiplomaticMessage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiplomaticMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.fromPlayerId, fromPlayerId) || other.fromPlayerId == fromPlayerId)&&(identical(other.toPlayerId, toPlayerId) || other.toPlayerId == toPlayerId)&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.category, category) || other.category == category)&&(identical(other.createdTurn, createdTurn) || other.createdTurn == createdTurn)&&(identical(other.expiresOnTurn, expiresOnTurn) || other.expiresOnTurn == expiresOnTurn)&&(identical(other.response, response) || other.response == response)&&(identical(other.respondedTurn, respondedTurn) || other.respondedTurn == respondedTurn)&&(identical(other.relationScoreDelta, relationScoreDelta) || other.relationScoreDelta == relationScoreDelta)&&(identical(other.relationScoreAfter, relationScoreAfter) || other.relationScoreAfter == relationScoreAfter)&&(identical(other.promiseDueTurn, promiseDueTurn) || other.promiseDueTurn == promiseDueTurn)&&(identical(other.promiseBroken, promiseBroken) || other.promiseBroken == promiseBroken));
}


@override
int get hashCode => Object.hash(runtimeType,id,fromPlayerId,toPlayerId,topic,category,createdTurn,expiresOnTurn,response,respondedTurn,relationScoreDelta,relationScoreAfter,promiseDueTurn,promiseBroken);

@override
String toString() {
  return 'DiplomaticMessage(id: $id, fromPlayerId: $fromPlayerId, toPlayerId: $toPlayerId, topic: $topic, category: $category, createdTurn: $createdTurn, expiresOnTurn: $expiresOnTurn, response: $response, respondedTurn: $respondedTurn, relationScoreDelta: $relationScoreDelta, relationScoreAfter: $relationScoreAfter, promiseDueTurn: $promiseDueTurn, promiseBroken: $promiseBroken)';
}


}

/// @nodoc
abstract mixin class $DiplomaticMessageCopyWith<$Res>  {
  factory $DiplomaticMessageCopyWith(DiplomaticMessage value, $Res Function(DiplomaticMessage) _then) = _$DiplomaticMessageCopyWithImpl;
@useResult
$Res call({
 String id, String fromPlayerId, String toPlayerId, DiplomaticMessageTopic topic, DiplomaticMessageCategory category, int createdTurn, int expiresOnTurn, DiplomaticMessageResponse? response, int? respondedTurn, int relationScoreDelta, int? relationScoreAfter, int? promiseDueTurn, bool promiseBroken
});




}
/// @nodoc
class _$DiplomaticMessageCopyWithImpl<$Res>
    implements $DiplomaticMessageCopyWith<$Res> {
  _$DiplomaticMessageCopyWithImpl(this._self, this._then);

  final DiplomaticMessage _self;
  final $Res Function(DiplomaticMessage) _then;

/// Create a copy of DiplomaticMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fromPlayerId = null,Object? toPlayerId = null,Object? topic = null,Object? category = null,Object? createdTurn = null,Object? expiresOnTurn = null,Object? response = freezed,Object? respondedTurn = freezed,Object? relationScoreDelta = null,Object? relationScoreAfter = freezed,Object? promiseDueTurn = freezed,Object? promiseBroken = null,}) {
  return _then(DiplomaticMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fromPlayerId: null == fromPlayerId ? _self.fromPlayerId : fromPlayerId // ignore: cast_nullable_to_non_nullable
as String,toPlayerId: null == toPlayerId ? _self.toPlayerId : toPlayerId // ignore: cast_nullable_to_non_nullable
as String,topic: null == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as DiplomaticMessageTopic,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as DiplomaticMessageCategory,createdTurn: null == createdTurn ? _self.createdTurn : createdTurn // ignore: cast_nullable_to_non_nullable
as int,expiresOnTurn: null == expiresOnTurn ? _self.expiresOnTurn : expiresOnTurn // ignore: cast_nullable_to_non_nullable
as int,response: freezed == response ? _self.response : response // ignore: cast_nullable_to_non_nullable
as DiplomaticMessageResponse?,respondedTurn: freezed == respondedTurn ? _self.respondedTurn : respondedTurn // ignore: cast_nullable_to_non_nullable
as int?,relationScoreDelta: null == relationScoreDelta ? _self.relationScoreDelta : relationScoreDelta // ignore: cast_nullable_to_non_nullable
as int,relationScoreAfter: freezed == relationScoreAfter ? _self.relationScoreAfter : relationScoreAfter // ignore: cast_nullable_to_non_nullable
as int?,promiseDueTurn: freezed == promiseDueTurn ? _self.promiseDueTurn : promiseDueTurn // ignore: cast_nullable_to_non_nullable
as int?,promiseBroken: null == promiseBroken ? _self.promiseBroken : promiseBroken // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DiplomaticMessage].
extension DiplomaticMessagePatterns on DiplomaticMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DiplomaticMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DiplomaticMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DiplomaticMessage value)  $default,){
final _that = this;
switch (_that) {
case _DiplomaticMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DiplomaticMessage value)?  $default,){
final _that = this;
switch (_that) {
case _DiplomaticMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String fromPlayerId,  String toPlayerId,  DiplomaticMessageTopic topic,  DiplomaticMessageCategory category,  int createdTurn,  int expiresOnTurn,  DiplomaticMessageResponse? response,  int? respondedTurn,  int relationScoreDelta,  int? relationScoreAfter,  int? promiseDueTurn,  bool promiseBroken)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DiplomaticMessage() when $default != null:
return $default(_that.id,_that.fromPlayerId,_that.toPlayerId,_that.topic,_that.category,_that.createdTurn,_that.expiresOnTurn,_that.response,_that.respondedTurn,_that.relationScoreDelta,_that.relationScoreAfter,_that.promiseDueTurn,_that.promiseBroken);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String fromPlayerId,  String toPlayerId,  DiplomaticMessageTopic topic,  DiplomaticMessageCategory category,  int createdTurn,  int expiresOnTurn,  DiplomaticMessageResponse? response,  int? respondedTurn,  int relationScoreDelta,  int? relationScoreAfter,  int? promiseDueTurn,  bool promiseBroken)  $default,) {final _that = this;
switch (_that) {
case _DiplomaticMessage():
return $default(_that.id,_that.fromPlayerId,_that.toPlayerId,_that.topic,_that.category,_that.createdTurn,_that.expiresOnTurn,_that.response,_that.respondedTurn,_that.relationScoreDelta,_that.relationScoreAfter,_that.promiseDueTurn,_that.promiseBroken);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String fromPlayerId,  String toPlayerId,  DiplomaticMessageTopic topic,  DiplomaticMessageCategory category,  int createdTurn,  int expiresOnTurn,  DiplomaticMessageResponse? response,  int? respondedTurn,  int relationScoreDelta,  int? relationScoreAfter,  int? promiseDueTurn,  bool promiseBroken)?  $default,) {final _that = this;
switch (_that) {
case _DiplomaticMessage() when $default != null:
return $default(_that.id,_that.fromPlayerId,_that.toPlayerId,_that.topic,_that.category,_that.createdTurn,_that.expiresOnTurn,_that.response,_that.respondedTurn,_that.relationScoreDelta,_that.relationScoreAfter,_that.promiseDueTurn,_that.promiseBroken);case _:
  return null;

}
}

}

/// @nodoc


class _DiplomaticMessage extends DiplomaticMessage {
  const _DiplomaticMessage({required this.id, required this.fromPlayerId, required this.toPlayerId, required this.topic, required this.category, required this.createdTurn, required this.expiresOnTurn, this.response, this.respondedTurn, this.relationScoreDelta = 0, this.relationScoreAfter, this.promiseDueTurn, this.promiseBroken = false}): super._();
  

@override final  String id;
@override final  String fromPlayerId;
@override final  String toPlayerId;
@override final  DiplomaticMessageTopic topic;
@override final  DiplomaticMessageCategory category;
@override final  int createdTurn;
@override final  int expiresOnTurn;
@override final  DiplomaticMessageResponse? response;
@override final  int? respondedTurn;
@override@JsonKey() final  int relationScoreDelta;
@override final  int? relationScoreAfter;
@override final  int? promiseDueTurn;
@override@JsonKey() final  bool promiseBroken;

/// Create a copy of DiplomaticMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DiplomaticMessageCopyWith<_DiplomaticMessage> get copyWith => __$DiplomaticMessageCopyWithImpl<_DiplomaticMessage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DiplomaticMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.fromPlayerId, fromPlayerId) || other.fromPlayerId == fromPlayerId)&&(identical(other.toPlayerId, toPlayerId) || other.toPlayerId == toPlayerId)&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.category, category) || other.category == category)&&(identical(other.createdTurn, createdTurn) || other.createdTurn == createdTurn)&&(identical(other.expiresOnTurn, expiresOnTurn) || other.expiresOnTurn == expiresOnTurn)&&(identical(other.response, response) || other.response == response)&&(identical(other.respondedTurn, respondedTurn) || other.respondedTurn == respondedTurn)&&(identical(other.relationScoreDelta, relationScoreDelta) || other.relationScoreDelta == relationScoreDelta)&&(identical(other.relationScoreAfter, relationScoreAfter) || other.relationScoreAfter == relationScoreAfter)&&(identical(other.promiseDueTurn, promiseDueTurn) || other.promiseDueTurn == promiseDueTurn)&&(identical(other.promiseBroken, promiseBroken) || other.promiseBroken == promiseBroken));
}


@override
int get hashCode => Object.hash(runtimeType,id,fromPlayerId,toPlayerId,topic,category,createdTurn,expiresOnTurn,response,respondedTurn,relationScoreDelta,relationScoreAfter,promiseDueTurn,promiseBroken);

@override
String toString() {
  return 'DiplomaticMessage(id: $id, fromPlayerId: $fromPlayerId, toPlayerId: $toPlayerId, topic: $topic, category: $category, createdTurn: $createdTurn, expiresOnTurn: $expiresOnTurn, response: $response, respondedTurn: $respondedTurn, relationScoreDelta: $relationScoreDelta, relationScoreAfter: $relationScoreAfter, promiseDueTurn: $promiseDueTurn, promiseBroken: $promiseBroken)';
}


}

/// @nodoc
abstract mixin class _$DiplomaticMessageCopyWith<$Res> implements $DiplomaticMessageCopyWith<$Res> {
  factory _$DiplomaticMessageCopyWith(_DiplomaticMessage value, $Res Function(_DiplomaticMessage) _then) = __$DiplomaticMessageCopyWithImpl;
@override @useResult
$Res call({
 String id, String fromPlayerId, String toPlayerId, DiplomaticMessageTopic topic, DiplomaticMessageCategory category, int createdTurn, int expiresOnTurn, DiplomaticMessageResponse? response, int? respondedTurn, int relationScoreDelta, int? relationScoreAfter, int? promiseDueTurn, bool promiseBroken
});




}
/// @nodoc
class __$DiplomaticMessageCopyWithImpl<$Res>
    implements _$DiplomaticMessageCopyWith<$Res> {
  __$DiplomaticMessageCopyWithImpl(this._self, this._then);

  final _DiplomaticMessage _self;
  final $Res Function(_DiplomaticMessage) _then;

/// Create a copy of DiplomaticMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fromPlayerId = null,Object? toPlayerId = null,Object? topic = null,Object? category = null,Object? createdTurn = null,Object? expiresOnTurn = null,Object? response = freezed,Object? respondedTurn = freezed,Object? relationScoreDelta = null,Object? relationScoreAfter = freezed,Object? promiseDueTurn = freezed,Object? promiseBroken = null,}) {
  return _then(_DiplomaticMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fromPlayerId: null == fromPlayerId ? _self.fromPlayerId : fromPlayerId // ignore: cast_nullable_to_non_nullable
as String,toPlayerId: null == toPlayerId ? _self.toPlayerId : toPlayerId // ignore: cast_nullable_to_non_nullable
as String,topic: null == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as DiplomaticMessageTopic,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as DiplomaticMessageCategory,createdTurn: null == createdTurn ? _self.createdTurn : createdTurn // ignore: cast_nullable_to_non_nullable
as int,expiresOnTurn: null == expiresOnTurn ? _self.expiresOnTurn : expiresOnTurn // ignore: cast_nullable_to_non_nullable
as int,response: freezed == response ? _self.response : response // ignore: cast_nullable_to_non_nullable
as DiplomaticMessageResponse?,respondedTurn: freezed == respondedTurn ? _self.respondedTurn : respondedTurn // ignore: cast_nullable_to_non_nullable
as int?,relationScoreDelta: null == relationScoreDelta ? _self.relationScoreDelta : relationScoreDelta // ignore: cast_nullable_to_non_nullable
as int,relationScoreAfter: freezed == relationScoreAfter ? _self.relationScoreAfter : relationScoreAfter // ignore: cast_nullable_to_non_nullable
as int?,promiseDueTurn: freezed == promiseDueTurn ? _self.promiseDueTurn : promiseDueTurn // ignore: cast_nullable_to_non_nullable
as int?,promiseBroken: null == promiseBroken ? _self.promiseBroken : promiseBroken // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
