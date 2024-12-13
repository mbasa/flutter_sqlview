import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class NetworkHelper {
  static Future<String> postCsvData(
      String url, String csv, String layerName) async {
    try {
      String rBody = "layername=$layerName&data=$csv";

      var request = http.Request("POST", Uri.parse(url));
      request.body = rBody;
      request.headers["Content-Type"] =
          "application/x-www-form-urlencoded; charset=utf-8";
      request.encoding = Encoding.getByName("utf-8")!;

      var sResponse = await request.send();

      if (sResponse.statusCode == 200) {
        var response = await http.Response.fromStream(sResponse);
        debugPrint(response.body);
        return response.body;
      } else {
        debugPrint("response code: ${sResponse.statusCode}");
      }
    } catch (e) {
      debugPrint("http: ${e.toString()}");
    }
    return "";
  }

  static Future<String> postCsvData2(
      String url, String csv, String layerName) async {
    try {
      String rBody = "layername=$layerName&data=$csv";
      debugPrint("body length: ${rBody.length}");

      var response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded; charset=utf-8",
          "Content-Length": "-1", //rBody.length.toString(),
        },
        encoding: Encoding.getByName('utf-8'),
        body: rBody,
        /*
        body: {
          "layername": layerName,
          "data": csv
        },
         */
      );

      if (response.statusCode == 200) {
        debugPrint(response.body);
        return response.body;
      } else {
        debugPrint("response code: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("http: ${e.toString()}");
    }
    return "";
  }
}
