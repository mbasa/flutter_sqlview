import 'dart:async';
import 'dart:io';

import 'package:data_table_2/data_table_2.dart';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_sqlview/utils/dialog_utils.dart';
import 'package:flutter_sqlview/utils/geofuse_utils.dart';
import 'package:flutter_sqlview/utils/net_utils.dart';
import 'package:highlight/languages/sql.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:postgresql2/postgresql.dart' as psql;

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (runWebViewTitleBarWidget(args, backgroundColor: Colors.lightGreen)) {
    return;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Application',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter SQL Viewer'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late psql.Connection _con;
  bool _inProcess = true;

  String _pgUrl = "postgres://postgres:postgres@localhost:5432/addresses2020";
  String _geofuseUrl = "http://localhost:8080/geofuse/indata";

  final List<DataColumn2> _dataCols = [];
  final List<DataRow2> _dataRows = [];

  final String _initialSql =
      "select code,todofuken,lon,lat from pggeocoder.address_t";

  final _codeController = CodeController(language: sql, text: "");

  @override
  void initState() {
    super.initState();
    _codeController.text = _initialSql;
    _setConnection(_initialSql);
  }

  @override
  void dispose() {
    debugPrint("Closing PostgreSQL connection");
    _con.close();
    super.dispose();
  }

  Future<void> _setConnection(String sql) async {
    if (sql.isEmpty) {
      return;
    }

    try {
      _con = await psql.connect(_pgUrl);

      var results = _con.query(sql);
      _dataRows.clear();
      _dataCols.clear();

      results.toList().then((rs) {
        if (rs.isNotEmpty) {
          var cols = rs[0].getColumns();

          for (var col in cols) {
            //debugPrint("field type: ${col.fieldType} field id: ${col.fieldId}");
            _dataCols.add(DataColumn2(
                label: Text(
                  col.name,
                  textAlign: TextAlign.center,
                ),
                size: ColumnSize.S));
          }

          for (var result in rs) {
            List<DataCell> dataCells = [];

            result.forEach((n, v) {
              dataCells.add(DataCell(Text(
                v.toString(),
                textAlign: TextAlign.left,
              )));
            });

            _dataRows.add(DataRow2(
              cells: dataCells,
            ));
          }
        }

        setState(() {
          debugPrint("connection PID: ${_con.backendPid}");
          _con.close();
          _inProcess = false;
        });
      }).catchError((e) {
        DialogUtil.showCustomDialog(
            context, "PostgreSQL Error", e.toString(), "Close");
        setState(() {
          _con.close();
          _inProcess = false;
        });
      });
    } catch (e) {
      debugPrint("PostgreSQL Error: ${e.toString()}");
      _con.close();
    }
  }

  String _resultToCSV() {
    StringBuffer sb = StringBuffer();
    int c;
    for (c = 0; c < _dataCols.length - 1; c++) {
      var t = _dataCols[c].label as Text;
      sb.write(t.data);
      sb.write("\t");
    }
    sb.write("${(_dataCols[c].label as Text).data}\n");

    for (var row in _dataRows) {
      for (c = 0; c < row.cells.length - 1; c++) {
        var t = row.cells[c].child as Text;
        sb.write(t.data);
        sb.write("\t");
      }
      sb.write("${(row.cells[c].child as Text).data}\n");
    }
    //debugPrint(sb.toString());
    return sb.toString();
  }

  Future<String> _getWebViewPath() async {
    final document = await getApplicationDocumentsDirectory();
    return p.join(
      document.path,
      'desktop_webview_window',
    );
  }

  bool _isMappable() {
    try {
      if (_dataRows.isEmpty || _dataCols.isEmpty) {
        return false;
      }

      if (_dataCols.length < 2) {
        return false;
      }

      var u = _dataCols[0].label as Text;
      debugPrint("Col[0]: ${u.data} ${geoFuseLinkCol.contains(u.data)}");
      if (geoFuseLinkCol.contains(u.data)) {
        return true;
      }

      var s = _dataCols[_dataCols.length - 2].label as Text;
      var t = _dataCols[_dataCols.length - 1].label as Text;

      if (s.data?.compareTo("lon") == 0 &&
          t.data?.compareTo("lat") == 0 &&
          _dataCols.length > 3) {
        return true;
      }
    } catch (e) {
      debugPrint("Mappable Check Error: ${e.toString()}");
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor:
            Colors.white, //Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        elevation: 28.0,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: "Clear SQL",
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () {
              setState(() {
                _codeController.fullText = "";
              });
            },
          ),
          IconButton(
              tooltip: "Query",
              icon: const Icon(Icons.find_in_page),
              onPressed: () {
                setState(() {
                  _inProcess = true;
                  _setConnection(_codeController.fullText);
                });
              }),
          IconButton(
              tooltip: "Server Configuration",
              onPressed: () async {
                Map<String, String> retData =
                    await DialogUtil.showConfigDialog(context, {
                  "pgUrl": _pgUrl,
                  "geofuseUrl": _geofuseUrl,
                });

                debugPrint("GeoFuse URL: ${retData["geofuseUrl"]}");

                if (retData["pgUrl"]!.isNotEmpty) {
                  _pgUrl = retData["pgUrl"]!;
                }
                if (retData["geofuseUrl"]!.isNotEmpty) {
                  _geofuseUrl = retData["geofuseUrl"]!;
                }
              },
              icon: const Icon(Icons.settings)),
        ],
      ),
      body: Center(
        child: _inProcess
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  CircularProgressIndicator(
                    color: Colors.deepOrange,
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                    'In Process',
                  ),
                ],
              )
            : Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: CodeTheme(
                      data: CodeThemeData(styles: githubTheme),
                      child: SingleChildScrollView(
                        child: CodeField(
                          controller: _codeController,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    color: Colors.indigo,
                    height: 1,
                  ),
                  Expanded(
                    flex: 7,
                    child: _dataRows.isEmpty
                        ? const Center(
                            child: Text(
                              "No Records Selected",
                              textAlign: TextAlign.center,
                            ),
                          )
                        : DataTable2(
                            columns: _dataCols,
                            rows: _dataRows,
                            //minWidth: 1200,
                            columnSpacing: 4,
                            horizontalMargin: 1,
                            headingRowColor: WidgetStateColor.resolveWith(
                                (states) => Colors.indigo),
                            headingTextStyle:
                                const TextStyle(color: Colors.white),

                            border: TableBorder(
                                top: const BorderSide(color: Colors.black),
                                bottom: BorderSide(color: Colors.grey[300]!),
                                left: BorderSide(color: Colors.grey[300]!),
                                right: BorderSide(color: Colors.grey[300]!),
                                verticalInside:
                                    BorderSide(color: Colors.grey[300]!),
                                horizontalInside: const BorderSide(
                                    color: Colors.grey, width: 1)),
                            dividerThickness: 1,
                          ),
                  )
                ],
              ),
      ),
      floatingActionButton: !_isMappable()
          ? null
          : FloatingActionButton(
              onPressed: () async {
                DialogUtil.showOnSendDialog(context, "Sending Data to GeoFuse");
                String csv = _resultToCSV();
                //debugPrint(csv);
                String result = await NetworkHelper.postCsvData(
                    _geofuseUrl, csv, "flutter_mb");
                Navigator.pop(context);

                if (result.isEmpty || result.startsWith("Error")) {
                  DialogUtil.showCustomDialog(context, "Network Error",
                      "An error has occurred while uploading data", "Close");
                } else {
                  final webView = await WebviewWindow.create(
                    configuration: CreateConfiguration(
                      userDataFolderWindows: await _getWebViewPath(),
                      titleBarTopPadding: Platform.isMacOS ? 20 : 0,
                      title: "GeoFuse Thematic Map",
                      titleBarHeight: 30,
                      windowWidth: 950,
                    ),
                  );

                  webView
                    ..setBrightness(Brightness.dark)
                    ..setApplicationNameForUserAgent(" WebviewExample/1.0.0")
                    //..openDevToolsWindow()
                    ..onClose.whenComplete(() {
                      debugPrint("on close");
                    })
                    ..launch(result);
                }
              },
              tooltip: 'Upload to GeoFuse',
              backgroundColor:
                  _dataRows.isEmpty ? Colors.grey : Colors.deepOrangeAccent,
              child: const Icon(Icons.send_outlined),
            ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
