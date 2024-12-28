import 'package:flutter/material.dart';

class DialogUtil {
  static void showOnSendDialog(BuildContext context, String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: SizedBox(
            height: 150.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const CircularProgressIndicator(),
                const SizedBox(
                  height: 12.0,
                ),
                Text(
                  msg,
                  style: const TextStyle(fontSize: 12.0),
                  textAlign: TextAlign.center,
                )
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> showCustomDialog(
      BuildContext context, String title, String msg, String btnMsg,
      {Color titleColor = Colors.red}) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(msg),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff00ac7d)),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                btnMsg,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  static Future<bool> showConfirmDialog(BuildContext context, String title,
      String msg, String cancelBtnMsg, String okBtnMsg,
      {Color titleColor = Colors.red}) async {
    return await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(msg),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                cancelBtnMsg,
                style: const TextStyle(color: Color(0xff546e7a)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff00ac7d)),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                okBtnMsg,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  static Future<Map<String, String>> showConfigDialog(
      BuildContext context, Map<String, String> inData) async {
    TextEditingController pgUrl = TextEditingController(text: inData["pgUrl"]);

    TextEditingController geofuseUrl =
        TextEditingController(text: inData["geofuseUrl"]);

    TextEditingController layerName =
        TextEditingController(text: inData["layerName"]);

    return await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Server Configuration'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: layerName,
                  decoration: const InputDecoration(
                    labelText: 'Layer Name',
                    labelStyle: TextStyle(
                      color: Colors.deepOrange,
                    ),
                  ),
                ),
                TextField(
                  controller: pgUrl,
                  decoration: const InputDecoration(
                    labelText: 'PostgreSQL URL',
                    labelStyle: TextStyle(
                      color: Colors.deepOrange,
                    ),
                  ),
                ),
                TextField(
                  controller: geofuseUrl,
                  decoration: const InputDecoration(
                    labelText: 'GeoFuse URL',
                    labelStyle: TextStyle(color: Colors.deepOrange),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop({
                    "pgUrl": pgUrl.text,
                    "geofuseUrl": geofuseUrl.text,
                    "layerName": layerName.text,
                  });
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
  }
}
