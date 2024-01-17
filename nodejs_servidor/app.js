const express = require('express')
const multer = require('multer');
const url = require('url');
const axios = require('axios');




const app = express()
const port = process.env.PORT || 3000

// Configurar la rebuda d'arxius a través de POST
const storage = multer.memoryStorage(); // Guardarà l'arxiu a la memòria
const upload = multer({ storage: storage });

// Tots els arxius de la carpeta 'public' estàn disponibles a través del servidor
// http://localhost:3000/
// http://localhost:3000/images/imgO.png
app.use(express.static('public'))

// Configurar per rebre dades POST en format JSON
app.use(express.json());

// Activar el servidor HTTP
const httpServer = app.listen(port, appListen)
async function appListen() {
  console.log(`Listening for HTTP queries on: http://localhost:${port}`)
}

// Tancar adequadament les connexions quan el servidor es tanqui
process.on('SIGTERM', shutDown);
process.on('SIGINT', shutDown);
function shutDown() {
  console.log('Received kill signal, shutting down gracefully');
  httpServer.close()
  process.exit(0);
}

// Configurar direcció tipus 'GET' amb la URL ‘/itei per retornar codi HTML
// http://localhost:3000/ieti
app.get('/ieti', getIeti)
async function getIeti(req, res) {

  // Aquí s'executen totes les accions necessaries
  // - fer una petició a un altre servidor
  // - consultar la base de dades
  // - calcular un resultat
  // - cridar la linia de comandes
  // - etc.

  res.writeHead(200, { 'Content-Type': 'text/html' })
  res.end('<html><head><meta charset="UTF-8"></head><body><b>El millor</b> institut del món!</body></html>')
}

// Configurar direcció tipus 'GET' amb la URL ‘/llistat’ i paràmetres URL 
// http://localhost:3000/llistat?cerca=cotxes&color=blau
// http://localhost:3000/llistat?cerca=motos&color=vermell


// Configurar direcció tipus 'POST' amb la URL ‘/data'
// Enlloc de fer una crida des d'un navegador, fer servir 'curl'
// curl -X POST -F "data={\"type\":\"test\"}" -F "file=@package.json" http://localhost:3000/data
// Esto es importate para que se envien los mensajes poco a poco

app.post('/data', upload.single('file'), async (req, res) => {
  const textPost = req.body;
  const uploadedFile = req.file;
  let objPost = {};

  try {
    console.log('textPost.data:', textPost);  // Agrega esta línea para imprimir el contenido
    objPost = JSON.parse(textPost.data);
  } catch (error) {
    console.log('Error parsing JSON:', error);  // Agrega esta línea para imprimir el error
    res.status(400).send('Solicitud incorrecta.');
    return;
  }


  if (objPost.type == 'mistral' && objPost.mensaje) {
    console.log(true);
    try {
      console.log(objPost.mensaje);
      // Utiliza el mensaje proporcionado en lugar del prompt fijo
      const apiResponse = await axios.post('http://localhost:11434/api/generate', {
        model: 'mistral',
        prompt: objPost.mensaje,
      });

      // Almacena todas las respuestas en un array
      const responses = [];
      apiResponse.data.split('\n').forEach(line => {
        if (line.trim() !== '') {
          const responseObj = JSON.parse(line);
          responses.push(responseObj);
          // Imprime cada respuesta en el servidor
          
        }
      });

      // Construye un objeto JSON con la estructura deseada
      const jsonResponse = {
        type: 'respuesta',
        mensaje: responses.map(response => response.response).join(''),
      };
      console.log(jsonResponse.mensaje);
      // Envía el objeto JSON como respuesta
      res.status(200).json(jsonResponse);
      responses.clear;
    } catch (error) {
      console.error('Error al realizar la solicitud a la API:', error);
      res.status(500).send('Error interno del seridor.');
    }


  } else if(objPost.type == 'llava' ){
    if (uploadedFile) {
      //console.log(objPost.data);
      // Suponiendo que el campo de archivo contiene datos de imagen codificados en base64
      const base64Data = uploadedFile.buffer.toString('base64');
      

      const responses = [];
      // Enviar datos a la otra API usando axios
      try {
        const apiUrl = 'http://localhost:11434/api/generate';
        const requestData = {
          model: 'llava',
          prompt: 'Que hay en esta foto',
          images: [base64Data],
        };

        const response = await axios.post(apiUrl, requestData);

        console.log('Response from API:');
        const responses = [];
        response.data.split('\n').forEach(line => {
          if (line.trim() !== '') {
            const responseObj = JSON.parse(line);
            responses.push(responseObj);
          }
        });

        // Construir un objeto JSON con la estructura deseada
        const jsonResponse = {
          type: 'respuesta',
          mensaje: responses.map(response => response.response).join(''),
        };
       /*{
          type: 'respuesta',
          mensaje: " In this picture, there is a large elephant with a wide trunk standing in the grass. It appears to be an adult male African elephant. The setting is outdoors with the sky visible above the elephant's head, creating a serene and natural atmosphere."
        }*/
       
        // Enviar la respuesta JSON al cliente
        res.status(200).json(jsonResponse);
        responses.clear;



      } catch (error) {
        console.error('Error haciendo la solicitud a la API:', error.message);
        res.status(500).json({ error: 'Error haciendo la solicitud a la API' });
        return;
      }
    } else {
      // Si no hay archivo adjunto, enviar una respuesta JSON simple al cliente
      res.status(200).json({ type: 'respuesta', mensaje: 'Sin archivo adjunto' });
    }

  }
   else {
    res.status(400).send('Solicitud incorrecta. Se requiere la propiedad "type" y "mensaje".');
  }
});


