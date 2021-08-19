import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:msal_flutter/msal_flutter.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const String _authority = "https://login.microsoftonline.com/organizations/oauth2/v2.0/authorize";
  static const String _clientId = "xxxxxxxxxxxxxxxxxxxxx";

  String _output = 'NONE';
  String _accessToken = 'NONE';
  String _accountId = 'NONE';

  static const List<String> kScopes = [
    "https://graph.microsoft.com/user.read",
    "https://graph.microsoft.com/Calendars.ReadWrite",
  ];

  PublicClientApplication? pca;

  Future<void> _acquireToken() async {
    if (pca == null) {
      pca = await PublicClientApplication.createPublicClientApplication(
          clientId: _clientId, authority: _authority);
    }

    Account res;
    String error = 'NONE';
    try {
      res = (await pca!.acquireToken(scopes: kScopes));
      setState(() {
        _output = res.accessToken.substring(0, 40) + "...";
        _accessToken = res.accessToken;
        _accountId = res.accountId;
      });
    } on MsalUserCancelledException {
      error = "User cancelled";
    } on MsalNoAccountException {
      error = "no account";
    } on MsalInvalidConfigurationException {
      error = "invalid config";
    } on MsalInvalidScopeException {
      error = "Invalid scope";
    } on MsalException {
      error = "Error getting token. Unspecified reason.";
    }

    setState(() {
      if (error != 'NONE') {
        _output = error;
      }
    });
  }

  Future<void> _acquireTokenSilently() async {
    if (pca == null) {
      pca = await PublicClientApplication.createPublicClientApplication(
          clientId: _clientId, authority: _authority);
    }

    Account res;
    String error = 'NONE';
    try {
      res =
          await pca!.acquireTokenSilent(scopes: kScopes, accountId: _accountId);
      setState(() {
        _output = "silent - " + res.accessToken.substring(0, 40) + "...";
        _accessToken = res.accessToken;
        _accountId = res.accountId;
      });
    } on MsalUserCancelledException {
      error = "User cancelled";
    } on MsalNoAccountException {
      error = "no account";
    } on MsalInvalidConfigurationException {
      error = "invalid config";
    } on MsalInvalidScopeException catch (e) {
      error = "Invalid scope: ${e.errorMessage}";
    } on MsalException {
      error = "Error getting token silently!";
    }

    setState(() {
      if (error != 'NONE') {
        _output = error;
      }
    });
  }

  Future _logout() async {
    print("called logout");
    if (pca == null) {
      pca = await PublicClientApplication.createPublicClientApplication(
          clientId: _clientId, authority: _authority);
    }

    String res;
    try {
      await pca!.logout(accountId: _accountId);
      res = "Account removed";
    } on MsalException {
      res = "MsalException - Error signing out";
    } on PlatformException catch (e) {
      res = "some other exception ${e.toString()}";
    }

    print("setting state");
    setState(() {
      _output = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Microsoft Azure'),
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              ElevatedButton(
                onPressed: _acquireToken,
                child: Text('AcquireToken()'),
              ),
              ElevatedButton(
                  onPressed: _acquireTokenSilently,
                  child: Text('AcquireTokenSilently()')),
              ElevatedButton(onPressed: _logout, child: Text('Logout')),
              Text("output: " + _output),
              Text("accountId: " + _accountId),
            ],
          ),
        ),
      ),
    );
  
}
