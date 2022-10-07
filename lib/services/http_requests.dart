// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:adguard_home_manager/models/logs.dart';
import 'package:adguard_home_manager/models/filtering_status.dart';
import 'package:adguard_home_manager/models/app_log.dart';
import 'package:adguard_home_manager/models/server_status.dart';
import 'package:adguard_home_manager/models/clients.dart';
import 'package:adguard_home_manager/models/clients_allowed_blocked.dart';
import 'package:adguard_home_manager/models/server.dart';


Future<Map<String, dynamic>> apiRequest({
  required Server server, 
  required String method, 
  required String urlPath, 
  Map<String, dynamic>? body,
  required String type,
}) async {
  try {
    HttpClient httpClient = HttpClient();
    if (method == 'get') {
      HttpClientRequest request = await httpClient.getUrl(Uri.parse("${server.connectionMethod}://${server.domain}${server.path ?? ""}${server.port != null ? ':${server.port}' : ""}/control$urlPath"));
      request.headers.set('authorization', 'Basic ${server.authToken}');
      HttpClientResponse response = await request.close().timeout(const Duration(seconds: 10));
      response.timeout(const Duration(seconds: 10));
      String reply = await response.transform(utf8.decoder).join();
      httpClient.close();
      if (response.statusCode == 200) {
        return {
          'hasResponse': true,
          'error': false,
          'statusCode': response.statusCode,
          'body': reply
        };
      }
      else {
        return {
          'hasResponse': true,
          'error': true,
          'statusCode': response.statusCode,
          'body': reply
        };
      }    
    }
    else if (method == 'post') {
      HttpClientRequest request = await httpClient.postUrl(Uri.parse("${server.connectionMethod}://${server.domain}${server.path ?? ""}${server.port != null ? ':${server.port}' : ""}/control$urlPath"));
      request.headers.set('authorization', 'Basic ${server.authToken}');
      request.headers.set('content-type', 'application/json');
      request.add(utf8.encode(json.encode(body)));
      HttpClientResponse response = await request.close().timeout(const Duration(seconds: 10));
      String reply = await response.transform(utf8.decoder).join();
      httpClient.close();
      if (response.statusCode == 200) {
        return {
          'hasResponse': true,
          'error': false,
          'statusCode': response.statusCode,
          'body': reply
        };
      }
      else {
        return {
          'hasResponse': true,
          'error': true,
          'statusCode': response.statusCode,
          'body': reply
        };
      }    
    }
    else {
      throw Exception('Method is required');
    }
  } on SocketException {
    return {
      'result': 'no_connection', 
      'log': AppLog(
        type: type, 
        dateTime: DateTime.now(), 
        message: 'SocketException'
      )
    };
  } on TimeoutException {
    return {
      'result': 'no_connection', 
      'log': AppLog(
        type: type, 
        dateTime: DateTime.now(), 
        message: 'TimeoutException'
      )
    };
  } on HandshakeException {
    return {
      'result': 'ssl_error', 
      'message': 'HandshakeException',
      'log': AppLog(
        type: type, 
        dateTime: DateTime.now(), 
        message: 'TimeoutException'
      )
    };
  } catch (e) {
    return {
      'result': 'error', 
      'log': AppLog(
        type: type, 
        dateTime: DateTime.now(), 
        message: e.toString()
      )
    };
  }
}

Future login(Server server) async {
  final result = await apiRequest(
    server: server,
    method: 'post',
    urlPath: '/login', 
    body: {
      "name": server.user,
      "password": server.password
    },
    type: 'login'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {'result': 'success'};
    }
    else if (result['statusCode'] == 400) {
      return {
        'result': 'invalid_username_password',
        'log': AppLog(
          type: 'login', 
          dateTime: DateTime.now(), 
          message: 'invalid_username_password',
          statusCode: result['statusCode'].toString(),
          resBody: result['body']
        )
      };
    }
    else if (result['statusCode'] == 429) {
      return {
        'result': 'many_attempts',
        'log': AppLog(
          type: 'login', 
          dateTime: DateTime.now(), 
          message: 'many_attempts',
          statusCode: result['statusCode'].toString(),
          resBody: result['body']
        )
      };
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'login', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body']
        )
      };
    }
  }
  else {
    return result;
  }
}

Future getServerStatus(Server server) async {
  final result = await Future.wait([
    apiRequest(server: server, method: 'get', urlPath: '/stats', type: 'server_status'),
    apiRequest(server: server, method: 'get', urlPath: '/status', type: 'server_status'),
    apiRequest(server: server, method: 'get', urlPath: '/filtering/status', type: 'server_status'),
    apiRequest(server: server, method: 'get', urlPath: '/safesearch/status', type: 'server_status'),
    apiRequest(server: server, method: 'get', urlPath: '/safebrowsing/status', type: 'server_status'),
    apiRequest(server: server, method: 'get', urlPath: '/parental/status', type: 'server_status'),
  ]);

  if (
    result[0]['hasResponse'] == true &&
    result[1]['hasResponse'] == true &&
    result[2]['hasResponse'] == true &&
    result[3]['hasResponse'] == true &&
    result[4]['hasResponse'] == true &&
    result[5]['hasResponse'] == true
  ) {
    if (
      result[0]['statusCode'] == 200 &&
      result[1]['statusCode'] == 200 &&
      result[2]['statusCode'] == 200 &&
      result[3]['statusCode'] == 200 &&
      result[4]['statusCode'] == 200 &&
      result[5]['statusCode'] == 200 
    ) {
      final Map<String, dynamic> mappedData = {
        'stats': jsonDecode(result[0]['body']),
        'generalEnabled': jsonDecode(result[1]['body']),
        'filteringEnabled': jsonDecode(result[2]['body']),
        'safeSearchEnabled': jsonDecode(result[3]['body']),
        'safeBrowsingEnabled': jsonDecode(result[4]['body']),
        'parentalControlEnabled': jsonDecode(result[5]['body']),
      };
      return {
        'result': 'success',
        'data': ServerStatusData.fromJson(mappedData)
      };
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'get_server_status', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result.map((res) => res['statusCode']).toString(),
          resBody: result.map((res) => res['body']).toString()
        )
      };
    }
  }
  else {
    return {
      'result': 'error',
      'log': AppLog(
        type: 'get_server_status', 
        dateTime: DateTime.now(), 
        message: 'no_response',
        statusCode: result.map((res) => res['statusCode'] ?? 'null').toString(),
        resBody: result.map((res) => res['body'] ?? 'null').toString()
      )
    };
  }
}

Future updateFiltering(Server server, bool enable) async {
  final result = await apiRequest(
    urlPath: '/filtering/config', 
    method: 'post',
    server: server, 
    body: {
      'enabled': enable
    },
    type: 'update_filtering'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {'result': 'success'};
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'update_filtering', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body']
        )
      };
    }
  }
  else {
    return result;
  }
}

Future updateSafeSearch(Server server, bool enable) async {
  final result = enable == true 
    ? await apiRequest(
        urlPath: '/safesearch/enable', 
        method: 'post',
        server: server, 
        type: 'enable_safe_search'
      )
    : await apiRequest(
        urlPath: '/safesearch/disable', 
        method: 'post',
        server: server,
        type: 'disable_safe_search'
      );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {'result': 'success'};
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'safe_search', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body']
        )
      };
    }
  }
  else {
    return result;
  }
}

Future updateSafeBrowsing(Server server, bool enable) async {
  final result = enable == true 
    ? await apiRequest(
        urlPath: '/safebrowsing/enable', 
        method: 'post',
        server: server, 
        type: 'enable_safe_browsing'
      )
    : await apiRequest(
        urlPath: '/safebrowsing/disable', 
        method: 'post',
        server: server, 
        type: 'disable_safe_browsing'
      );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {'result': 'success'};
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'safe_browsing', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body']
        )
      };
    }
  }
  else {
    return result;
  }
}

Future updateParentalControl(Server server, bool enable) async {
  final result = enable == true 
    ? await apiRequest(
        urlPath: '/parental/enable', 
        method: 'post',
        server: server, 
        type: 'enable_parental_control'
      )
    : await apiRequest(
        urlPath: '/parental/disable', 
        method: 'post',
        server: server, 
        type: 'disable_parental_control'
      );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {'result': 'success'};
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'parental_control', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body']
        )
      };
    }
  }
  else {
    return result;
  }
}

Future updateGeneralProtection(Server server, bool enable) async {
    final result = await apiRequest(
    urlPath: '/dns_config', 
    method: 'post',
    server: server, 
    body: {
      'protection_enabled': enable
    },
    type: 'general_protection'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {'result': 'success'};
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'general_protection', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body']
        )
      };
    }
  }
  else {
    return result;
  }
}

Future getClients(Server server) async {
  final result = await Future.wait([
    apiRequest(server: server, method: 'get', urlPath: '/clients', type: 'get_clients'),
    apiRequest(server: server, method: 'get', urlPath: '/access/list', type: 'get_clients'),
  ]);

  if (result[0]['hasResponse'] == true && result[1]['hasResponse'] == true) {
    if (result[0]['statusCode'] == 200 && result[1]['statusCode'] == 200) {
      final clients = ClientsData.fromJson(jsonDecode(result[0]['body']));
      clients.clientsAllowedBlocked = ClientsAllowedBlocked.fromJson(jsonDecode(result[1]['body']));
      return {
        'result': 'success',
        'data': clients
      };
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'get_clients', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result.map((res) => res['statusCode'] ?? 'null').toString(),
          resBody: result.map((res) => res['body'] ?? 'null').toString(),
        )
      };
    }
  }
  else {
    return {
      'result': 'error',
      'log': AppLog(
        type: 'get_clients', 
        dateTime: DateTime.now(), 
        message: 'no_response',
        statusCode: result.map((res) => res['statusCode'] ?? 'null').toString(),
        resBody: result.map((res) => res['body'] ?? 'null').toString(),
      )
    };
  }
}

Future requestAllowedBlockedClientsHosts(Server server, Map<String, List<String>?> body) async {
  final result = await apiRequest(
    urlPath: '/access/set', 
    method: 'post',
    server: server, 
    body: body,
    type: 'get_clients'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {'result': 'success'};
    }
    if (result['statusCode'] == 400) {
      return {
        'result': 'error',
        'message': 'client_another_list'
      };
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'get_clients', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body']
        )
      };
    }
  }
  else {
    return result;
  }
}

Future getLogs({
  required Server server, 
  required int count, 
  int? offset,
  DateTime? olderThan,
  String? responseStatus,
  String? search
}) async {
  final result = await apiRequest(
    server: server, 
    method: 'get', 
    urlPath: '/querylog?limit=$count${offset != null ? '&offset=$offset' : ''}${olderThan != null ? '&older_than=${olderThan.toIso8601String()}' : ''}${responseStatus != null ? '&response_status=$responseStatus' : ''}${search != null ? '&search=$search' : ''}',
    type: 'get_logs'
  );
    
  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {
        'result': 'success',
        'data': LogsData.fromJson(jsonDecode(result['body']))
      };
    }
    else {
      return {
        'result': 'error', 
        'log': AppLog(
          type: 'get_logs', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body']
        )
      };
    }
  }
  else {
    return result;
  }
}

Future getFilteringRules({
  required Server server, 
}) async {
  final result = await apiRequest(
    server: server, 
    method: 'get', 
    urlPath: '/filtering/status',
    type: 'get_filtering_rules'
  );
    
  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {
        'result': 'success',
        'data': FilteringStatus.fromJson(jsonDecode(result['body']))
      };
    }
    else {
      return {
        'result': 'error', 
        'log': AppLog(
          type: 'get_filtering_rules', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body']
        )
      };
    }
  }
  else {
    return result;
  }
}

Future postFilteringRules({
  required Server server, 
  required Map<String, List<String>> data, 
}) async {
    final result = await apiRequest(
    urlPath: '/filtering/set_rules', 
    method: 'post',
    server: server, 
    body: data,
    type: 'post_filering_rules'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {'result': 'success'};
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'post_filtering_rules', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body']
        )
      };
    }
  }
  else {
    return result;
  }
}

Future postAddClient({
  required Server server, 
  required Map<String, dynamic> data, 
}) async {
    final result = await apiRequest(
    urlPath: '/clients/add', 
    method: 'post',
    server: server, 
    body: data,
    type: 'add_client'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {'result': 'success'};
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'add_client', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body']
        )
      };
    }
  }
  else {
    return result;
  }
}

Future postUpdateClient({
  required Server server, 
  required Map<String, dynamic> data, 
}) async {
    final result = await apiRequest(
    urlPath: '/clients/update', 
    method: 'post',
    server: server, 
    body: data,
    type: 'update_client'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {'result': 'success'};
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'update_client', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body']
        )
      };
    }
  }
  else {
    return result;
  }
}

Future postDeleteClient({
  required Server server, 
  required String name, 
}) async {
    final result = await apiRequest(
    urlPath: '/clients/delete', 
    method: 'post',
    server: server, 
    body: {'name': name},
    type: 'remove_client'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {'result': 'success'};
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'remove_client', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body']
        )
      };
    }
  }
  else {
    return result;
  }
}