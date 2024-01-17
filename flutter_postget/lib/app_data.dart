import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_postget/layout_desktop.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class AppData with ChangeNotifier {
  // Access appData globaly with:
  // AppData appData = Provider.of<AppData>(context);
  // AppData appData = Provider.of<AppData>(context, listen: false)

  bool loadingGet = false;
  bool loadingPost = false;
  bool loadingFile = false;

  var url = 'http://localhost:3000/data';

  dynamic dataGet;
  dynamic dataPost;
  dynamic dataFile;

  List<String> _messages = [];

  List<String> get messages => _messages;

  // Function to add a message
  void addMessage(String message) {
    _messages.add(message);
    notifyListeners(); // Notify listeners to update the UI
  }

  void addTextToMessage(int index, String additionalText) {
    if (index >= 0 && index < _messages.length) {
      _messages[index] += additionalText;
      notifyListeners(); // Notificar a los escuchadores para actualizar la interfaz
    }
  }

  // Funció per fer crides tipus 'GET' i agafar la informació a mida que es va rebent
  Future<String> loadHttpGetByChunks(String url) async {
    var httpClient = HttpClient();
    var completer = Completer<String>();
    String result = "";

    // If development, wait 1 second to simulate a delay
    if (!kReleaseMode) {
      await Future.delayed(const Duration(seconds: 1));
    }

    try {
      var request = await httpClient.getUrl(Uri.parse(url));
      var response = await request.close();

      response.transform(utf8.decoder).listen(
        (data) {
          // Aquí rep cada un dels troços de dades que envia el servidor amb 'res.write'
          result += data;
        },
        onDone: () {
          completer.complete(result);
        },
        onError: (error) {
          completer.completeError(
              "Error del servidor (appData/loadHttpGetByChunks): $error");
        },
      );
    } catch (e) {
      completer.completeError("Excepció (appData/loadHttpGetByChunks): $e");
    }

    return completer.future;
  }

  // Funció per fer crides tipus 'POST' amb un arxiu adjunt,
  //i agafar la informació a mida que es va rebent
  Future<String> sendTextToServer(String url, String text) async {
    try {
      // Crear la solicitud POST
      var request = http.Request('POST', Uri.parse(url));

      // Configurar el encabezado y el cuerpo de la solicitud
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({'data': text});

      // Enviar la solicitud y esperar la respuesta
      var response = await request.send();

      if (response.statusCode == 200) {
        // La solicitud ha sido exitosa
        var responseData = await response.stream.toBytes();
        var responseString = utf8.decode(responseData);
        return responseString;
      } else {
        // La solicitud ha fallado
        throw Exception("Error del servidor: ${response.reasonPhrase}");
      }
    } catch (error) {
      // Manejar errores en la solicitud
      throw Exception("Error al enviar la solicitud: $error");
    }
  }

  // Funció per fer carregar dades d'un arxiu json de la carpeta 'assets'
  Future<dynamic> readJsonAsset(String filePath) async {
    // If development, wait 1 second to simulate a delay
    if (!kReleaseMode) {
      await Future.delayed(const Duration(seconds: 1));
    }

    try {
      var jsonString = await rootBundle.loadString(filePath);
      final jsonData = json.decode(jsonString);
      return jsonData;
    } catch (e) {
      throw Exception("Excepció (appData/readJsonAsset): $e");
    }
  }




}
