import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cupertino_desktop_kit/cdk.dart';
import 'package:http_parser/http_parser.dart';
import 'package:provider/provider.dart';

import 'app_data.dart';

class LayoutDesktop extends StatefulWidget {
  const LayoutDesktop({super.key, required this.title});

  final String title;

  @override
  State<LayoutDesktop> createState() => _LayoutDesktopState();
}

class _LayoutDesktopState extends State<LayoutDesktop> {
  TextEditingController _textController = TextEditingController();
  TextEditingController _receivedMessageController = TextEditingController();
  static ScrollController _scrollController = ScrollController();

  int posicionMensaje = 1;
  bool generatingMessage = false;
  static File? imagen;

  // Return a custom button
  Widget buildCustomButton(String buttonText, VoidCallback onPressedAction) {
    return SizedBox(
      width: 150, // Amplada total de l'espai
      child: Align(
        alignment: Alignment.centerRight, // Alineació a la dreta
        child: CDKButton(
          style: CDKButtonStyle.normal,
          isLarge: false,
          onPressed: onPressedAction,
          child: Text(buttonText),
        ),
      ),
    );
  }

  // Function to select a file
  Future<File?> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);
      return file;
    } else {
      return null; // Return null if no file is selected
    }
  }

  // Function to upload the selected file with a POST request
  Future<void> uploadFile(AppData appData,String text) async {
    try {
      if (imagen != null) {
        load(appData,text,"POST", selectedFile: imagen!);
      }
    } catch (e) {
      if (kDebugMode) {
        print("Excepción (uploadFile): $e");
      }
    }
  }

  static void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 10),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    AppData appData = Provider.of<AppData>(context);

    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Container(
            width: 600,
            height: 800,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[200], // Fondo del contenedor
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Título del chat
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    "XatIETI",
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Área de mensajes
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.white, // Fondo del área de mensajes
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: appData.messages?.length ?? 0,
                      itemBuilder: (context, index) {
                        IconData iconData =
                            index.isEven ? Icons.android : Icons.apple;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    Colors.blue, // Color del círculo del icono
                                child: Icon(
                                  iconData,
                                  color: Colors.white, // Color del icono
                                ),
                              ),
                              title: Text(
                                appData.messages?[index] ?? "",
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),


                            SizedBox(height: 4), // Espacio entre elementos
                            Divider(
                                color: Colors.black,
                                height: 1), // Añade espacio entre mensajes
                          ],
                        );
                      },
                    ),
                  ),
                ),

                SizedBox(height: 16),
                imagen != null
                    ? Container(
                  width: 200,
                  height: 200,
                  child: Image.file(imagen!),
                )
                    : Container(),

                SizedBox(height: 8),
                // Barra para poner texto
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: Colors.white, // Fondo del campo de texto
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _textController,
                                onSubmitted: (text) async {

                                  _scrollToBottom();
                                  if (imagen != null){
                                    await uploadFile(appData,_textController.text);
                                    imagen = null;
                                  }else if (imagen == null ){
                                    _sendMessage(appData);
                                  }


                                },
                                decoration: InputDecoration(
                                  hintText: 'Escribe tu mensaje...',
                                  border: InputBorder.none,
                                ),
                                enabled: !generatingMessage,
                              ),
                            ),
                            SizedBox(width: 8),
                            generatingMessage
                                ? Row(
                                    children: [
                                      buildIconButton(Icons.stop, () {
                                        setState(() {
                                          generatingMessage = false;
                                        });
                                      }),
                                      SizedBox(width: 8),
                                      CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.blue,
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                              children: [
                                // Button to send
                                buildIconButton(Icons.send, () async {
                                  _scrollToBottom();
                                  if (imagen != null){
                                    await uploadFile(appData,_textController.text);
                                    imagen = null;
                                  }else if (imagen == null ){
                                    _sendMessage(appData);
                                  }
                                }),
                                const SizedBox(width: 8),
                                // Button to upload a file (image)
                                buildIconButton(Icons.file_upload, () async {
                                  File? selectedFile = await pickFile();
                                  if (selectedFile != null) {
                                    setState(() {
                                      imagen = selectedFile;
                                    });


                                  }
                                }),
                              ],
                            ),

                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void load(AppData appData,String text,String type, {File? selectedFile} ) async {
    String texto = _textController.text;
    if (texto.isEmpty){
      texto = "What is in the picture?";
    }
    appData.addMessage(texto);
    switch (type) {
      case 'POST':


        setState(() {
          generatingMessage = true;
        });
        var dataPost = await loadHttpPostByChunks(
            'http://localhost:3000/data', selectedFile!,texto);

        Map<String, dynamic> jsonResponse = json.decode(dataPost);

        // Obtener el mensaje del JSON de la respuesta
        String mensaje = jsonResponse["mensaje"];

        await generateMessage(appData, mensaje);

        setState(() {
          generatingMessage = false;
        });

        _textController.clear();
        break;
    }
  }

  Future<String> loadHttpPostByChunks(String url, File file, String text) async {
    var request = http.MultipartRequest('POST', Uri.parse(url));
    // Agregar los datos JSON como parte del formulario
    request.fields['data'] = '{"type":"llava"}';

    // Adjuntar el archivo como parte del formulario
    var fileStream = http.ByteStream(file.openRead());
    var fileLength = await file.length();
    var filePart = http.MultipartFile(
      'file',
      fileStream,
      fileLength,
      filename: file.path.split('/').last,
      contentType: MediaType('application', 'octet-stream'),
    );
    request.files.add(filePart);

    // Agregar el texto como parte del formulario
    request.fields['text'] = text;

    try {
      var response = await request.send();

      if (response.statusCode == 200) {
        // La solicitud ha sido exitosa
        var responseData = await response.stream.toBytes();
        var responseString = utf8.decode(responseData);

        return responseString;
      } else {
        // La solicitud ha fallado
        throw Exception(
            "Error del servidor (appData/loadHttpPostByChunks): ${response.reasonPhrase}");
      }
    } catch (error) {
      // Manejar cualquier error durante la solicitud
      throw Exception("Error durante la solicitud: $error");
    }
  }

  Future<void> generateMessage(AppData appData, String mensaje) async {
    int contador = 0;

    // Variable booleana para controlar si se debe interrumpir el bucle
    bool stopLoop = false;

    for (int i = 0; i < mensaje.length; i++) {
      if (stopLoop) {
        break; // Salir del bucle si stopLoop es true
      }

      if (contador == 0) {
        appData.addMessage(mensaje.substring(i));
        contador++;
      }
      appData.addTextToMessage(posicionMensaje, mensaje[i]);
      appData.notifyListeners();
      _scrollToBottom();

      // Esperar y verificar la variable stopLoop después de cada iteración
      await Future.delayed(const Duration(milliseconds: 30), () {
        if (generatingMessage == false) {
          stopLoop = true;
        }
      });
    }
    posicionMensaje = posicionMensaje + 2;
  }

  Future<void> _sendMessage(AppData appData) async {
    String texto = _textController.text;
    if (texto.isNotEmpty) {
      setState(() {
        generatingMessage = true;
      });
      // Crear un JSON con la pregunta y el mensaje
      Map<String, dynamic> jsonBody = {
        "type": "mistral",
        "mensaje": texto,
      };

      // Convertir el JSON a una cadena
      String jsonString = json.encode(jsonBody);

      appData.addMessage(texto);
      _textController.clear();

      // Enviar la cadena JSON al servidor
      var response = await appData.sendTextToServer(appData.url, jsonString);
      // Parsear el JSON de la respuesta
      Map<String, dynamic> jsonResponse = json.decode(response);

      // Obtener el mensaje del JSON de la respuesta
      String mensaje = jsonResponse["mensaje"];

      await generateMessage(appData, mensaje);

      setState(() {
        generatingMessage = false;
      });
    }
  }

// Función para crear un botón con icono
  Widget buildIconButton(IconData icon, VoidCallback onClick) {
    return IconButton(
      onPressed: onClick,
      icon: Icon(icon),
    );
  }
}
