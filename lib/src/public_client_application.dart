import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'msal_exception.dart';

/// Represents a PublicClientApplication used to authenticate using the implicit flow
class PublicClientApplication {
  static const MethodChannel _channel = const MethodChannel('msal_flutter');

  late String _clientId, _authority;

  /// Create a new PublicClientApplication authenticating as the given [clientId],
  /// optionally against the selected [authority], defaulting to the common
  PublicClientApplication({String? clientId, String? authority}) {
    throw Exception(
        "Direct call is no longer supported in v1.0, please use static method createPublicClientApplication");
  }

  PublicClientApplication._create(
      {required String clientId, required String authority}) {
    _clientId = clientId;
    _authority = authority;
  }

  static Future<PublicClientApplication> createPublicClientApplication(
      {required String clientId, required String authority}) async {
    var res = PublicClientApplication._create(
        clientId: clientId, authority: authority);
    await res._initialize();

    return res;
  }

  /// Acquire a token interactively for the given [scopes]
  Future<Account> acquireToken({required List<String> scopes}) async {
    //create the arguments
    var res = <String, dynamic>{'scopes': scopes};

    //call platform
    try {
      final result = await _channel.invokeMethod('acquireToken', res);
      return Account(
        accountId: result['accountId'],
        accessToken: result['accessToken'],
      );
    } on PlatformException catch (e) {
      throw _convertException(e);
    }
  }

  /// Acquire a token silently, with no user interaction, for the given [scopes]
  Future<Account> acquireTokenSilent(
      {required String accountId, required List<String> scopes}) async {
    //create the arguments
    var res = <String, dynamic>{'accountId': accountId, 'scopes': scopes};

    //call platform
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('loadAccounts');
      }
      final result = await _channel.invokeMethod('acquireTokenSilent', res);
      return Account(
        accountId: result['accountId'],
        accessToken: result['accessToken'],
      );
    } on PlatformException catch (e) {
      throw _convertException(e);
    }
  }

  Future logout({required String? accountId}) async {
    //create the arguments
    var res = <String, dynamic>{'accountId': accountId};
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('loadAccounts');
      }
      await _channel.invokeMethod('logout', res);
    } on PlatformException catch (e) {
      throw _convertException(e);
    }
  }

  MsalException _convertException(PlatformException e) {
    switch (e.code) {
      case "CANCELLED":
        return MsalUserCancelledException();
      case "NO_SCOPE":
        return MsalInvalidScopeException();
      case "NO_ACCOUNT":
        return MsalNoAccountException();
      case "NO_CLIENTID":
        return MsalInvalidConfigurationException("Client Id not set");
      case "INVALID_AUTHORITY":
        return MsalInvalidConfigurationException("Invalid authroity set.");
      case "CONFIG_ERROR":
        return MsalInvalidConfigurationException(
            "Invalid configuration, please correct your settings and try again");
      case "NO_CLIENT":
        return MsalUninitializedException();
      case "CHANGED_CLIENTID":
        return MsalChangedClientIdException();
      case "INIT_ERROR":
        return MsalInitializationException();
      case "AUTH_ERROR":
      default:
        return MsalException("Authentication error: ${e.code}");
    }
  }

  //initialize the main client platform side
  Future _initialize() async {
    var res = <String, dynamic>{'clientId': this._clientId};
    //if authority has been set, add it aswell
    if (this._authority != null) {
      res["authority"] = this._authority;
    }

    try {
      await _channel.invokeMethod('initialize', res);
    } on PlatformException catch (e) {
      debugPrint("MSAL--> ${e.message} --> ${e.code}");
      throw _convertException(e);
    }
  }
}

class Account {
  final String accessToken;
  final String accountId;

  Account({
    required this.accessToken,
    required this.accountId,
  });
}
