// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SettingsState {

 String get backendUrl; bool get toolsEnabled; bool get tamilMode; bool get isDarkTheme; String get geminiModel; bool get memoryEnabled; bool get mcpEnabled; String get customInstructions;
/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsStateCopyWith<SettingsState> get copyWith => _$SettingsStateCopyWithImpl<SettingsState>(this as SettingsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsState&&(identical(other.backendUrl, backendUrl) || other.backendUrl == backendUrl)&&(identical(other.toolsEnabled, toolsEnabled) || other.toolsEnabled == toolsEnabled)&&(identical(other.tamilMode, tamilMode) || other.tamilMode == tamilMode)&&(identical(other.isDarkTheme, isDarkTheme) || other.isDarkTheme == isDarkTheme)&&(identical(other.geminiModel, geminiModel) || other.geminiModel == geminiModel)&&(identical(other.memoryEnabled, memoryEnabled) || other.memoryEnabled == memoryEnabled)&&(identical(other.mcpEnabled, mcpEnabled) || other.mcpEnabled == mcpEnabled)&&(identical(other.customInstructions, customInstructions) || other.customInstructions == customInstructions));
}


@override
int get hashCode => Object.hash(runtimeType,backendUrl,toolsEnabled,tamilMode,isDarkTheme,geminiModel,memoryEnabled,mcpEnabled,customInstructions);

@override
String toString() {
  return 'SettingsState(backendUrl: $backendUrl, toolsEnabled: $toolsEnabled, tamilMode: $tamilMode, isDarkTheme: $isDarkTheme, geminiModel: $geminiModel, memoryEnabled: $memoryEnabled, mcpEnabled: $mcpEnabled, customInstructions: $customInstructions)';
}


}

/// @nodoc
abstract mixin class $SettingsStateCopyWith<$Res>  {
  factory $SettingsStateCopyWith(SettingsState value, $Res Function(SettingsState) _then) = _$SettingsStateCopyWithImpl;
@useResult
$Res call({
 String backendUrl, bool toolsEnabled, bool tamilMode, bool isDarkTheme, String geminiModel, bool memoryEnabled, bool mcpEnabled, String customInstructions
});




}
/// @nodoc
class _$SettingsStateCopyWithImpl<$Res>
    implements $SettingsStateCopyWith<$Res> {
  _$SettingsStateCopyWithImpl(this._self, this._then);

  final SettingsState _self;
  final $Res Function(SettingsState) _then;

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? backendUrl = null,Object? toolsEnabled = null,Object? tamilMode = null,Object? isDarkTheme = null,Object? geminiModel = null,Object? memoryEnabled = null,Object? mcpEnabled = null,Object? customInstructions = null,}) {
  return _then(_self.copyWith(
backendUrl: null == backendUrl ? _self.backendUrl : backendUrl // ignore: cast_nullable_to_non_nullable
as String,toolsEnabled: null == toolsEnabled ? _self.toolsEnabled : toolsEnabled // ignore: cast_nullable_to_non_nullable
as bool,tamilMode: null == tamilMode ? _self.tamilMode : tamilMode // ignore: cast_nullable_to_non_nullable
as bool,isDarkTheme: null == isDarkTheme ? _self.isDarkTheme : isDarkTheme // ignore: cast_nullable_to_non_nullable
as bool,geminiModel: null == geminiModel ? _self.geminiModel : geminiModel // ignore: cast_nullable_to_non_nullable
as String,memoryEnabled: null == memoryEnabled ? _self.memoryEnabled : memoryEnabled // ignore: cast_nullable_to_non_nullable
as bool,mcpEnabled: null == mcpEnabled ? _self.mcpEnabled : mcpEnabled // ignore: cast_nullable_to_non_nullable
as bool,customInstructions: null == customInstructions ? _self.customInstructions : customInstructions // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SettingsState].
extension SettingsStatePatterns on SettingsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SettingsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SettingsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SettingsState value)  $default,){
final _that = this;
switch (_that) {
case _SettingsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SettingsState value)?  $default,){
final _that = this;
switch (_that) {
case _SettingsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String backendUrl,  bool toolsEnabled,  bool tamilMode,  bool isDarkTheme,  String geminiModel,  bool memoryEnabled,  bool mcpEnabled,  String customInstructions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SettingsState() when $default != null:
return $default(_that.backendUrl,_that.toolsEnabled,_that.tamilMode,_that.isDarkTheme,_that.geminiModel,_that.memoryEnabled,_that.mcpEnabled,_that.customInstructions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String backendUrl,  bool toolsEnabled,  bool tamilMode,  bool isDarkTheme,  String geminiModel,  bool memoryEnabled,  bool mcpEnabled,  String customInstructions)  $default,) {final _that = this;
switch (_that) {
case _SettingsState():
return $default(_that.backendUrl,_that.toolsEnabled,_that.tamilMode,_that.isDarkTheme,_that.geminiModel,_that.memoryEnabled,_that.mcpEnabled,_that.customInstructions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String backendUrl,  bool toolsEnabled,  bool tamilMode,  bool isDarkTheme,  String geminiModel,  bool memoryEnabled,  bool mcpEnabled,  String customInstructions)?  $default,) {final _that = this;
switch (_that) {
case _SettingsState() when $default != null:
return $default(_that.backendUrl,_that.toolsEnabled,_that.tamilMode,_that.isDarkTheme,_that.geminiModel,_that.memoryEnabled,_that.mcpEnabled,_that.customInstructions);case _:
  return null;

}
}

}

/// @nodoc


class _SettingsState implements SettingsState {
  const _SettingsState({required this.backendUrl, required this.toolsEnabled, required this.tamilMode, required this.isDarkTheme, required this.geminiModel, required this.memoryEnabled, required this.mcpEnabled, this.customInstructions = ''});
  

@override final  String backendUrl;
@override final  bool toolsEnabled;
@override final  bool tamilMode;
@override final  bool isDarkTheme;
@override final  String geminiModel;
@override final  bool memoryEnabled;
@override final  bool mcpEnabled;
@override@JsonKey() final  String customInstructions;

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SettingsStateCopyWith<_SettingsState> get copyWith => __$SettingsStateCopyWithImpl<_SettingsState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SettingsState&&(identical(other.backendUrl, backendUrl) || other.backendUrl == backendUrl)&&(identical(other.toolsEnabled, toolsEnabled) || other.toolsEnabled == toolsEnabled)&&(identical(other.tamilMode, tamilMode) || other.tamilMode == tamilMode)&&(identical(other.isDarkTheme, isDarkTheme) || other.isDarkTheme == isDarkTheme)&&(identical(other.geminiModel, geminiModel) || other.geminiModel == geminiModel)&&(identical(other.memoryEnabled, memoryEnabled) || other.memoryEnabled == memoryEnabled)&&(identical(other.mcpEnabled, mcpEnabled) || other.mcpEnabled == mcpEnabled)&&(identical(other.customInstructions, customInstructions) || other.customInstructions == customInstructions));
}


@override
int get hashCode => Object.hash(runtimeType,backendUrl,toolsEnabled,tamilMode,isDarkTheme,geminiModel,memoryEnabled,mcpEnabled,customInstructions);

@override
String toString() {
  return 'SettingsState(backendUrl: $backendUrl, toolsEnabled: $toolsEnabled, tamilMode: $tamilMode, isDarkTheme: $isDarkTheme, geminiModel: $geminiModel, memoryEnabled: $memoryEnabled, mcpEnabled: $mcpEnabled, customInstructions: $customInstructions)';
}


}

/// @nodoc
abstract mixin class _$SettingsStateCopyWith<$Res> implements $SettingsStateCopyWith<$Res> {
  factory _$SettingsStateCopyWith(_SettingsState value, $Res Function(_SettingsState) _then) = __$SettingsStateCopyWithImpl;
@override @useResult
$Res call({
 String backendUrl, bool toolsEnabled, bool tamilMode, bool isDarkTheme, String geminiModel, bool memoryEnabled, bool mcpEnabled, String customInstructions
});




}
/// @nodoc
class __$SettingsStateCopyWithImpl<$Res>
    implements _$SettingsStateCopyWith<$Res> {
  __$SettingsStateCopyWithImpl(this._self, this._then);

  final _SettingsState _self;
  final $Res Function(_SettingsState) _then;

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? backendUrl = null,Object? toolsEnabled = null,Object? tamilMode = null,Object? isDarkTheme = null,Object? geminiModel = null,Object? memoryEnabled = null,Object? mcpEnabled = null,Object? customInstructions = null,}) {
  return _then(_SettingsState(
backendUrl: null == backendUrl ? _self.backendUrl : backendUrl // ignore: cast_nullable_to_non_nullable
as String,toolsEnabled: null == toolsEnabled ? _self.toolsEnabled : toolsEnabled // ignore: cast_nullable_to_non_nullable
as bool,tamilMode: null == tamilMode ? _self.tamilMode : tamilMode // ignore: cast_nullable_to_non_nullable
as bool,isDarkTheme: null == isDarkTheme ? _self.isDarkTheme : isDarkTheme // ignore: cast_nullable_to_non_nullable
as bool,geminiModel: null == geminiModel ? _self.geminiModel : geminiModel // ignore: cast_nullable_to_non_nullable
as String,memoryEnabled: null == memoryEnabled ? _self.memoryEnabled : memoryEnabled // ignore: cast_nullable_to_non_nullable
as bool,mcpEnabled: null == mcpEnabled ? _self.mcpEnabled : mcpEnabled // ignore: cast_nullable_to_non_nullable
as bool,customInstructions: null == customInstructions ? _self.customInstructions : customInstructions // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
