const { app, BrowserWindow } = require('electron');
const { spawn } = require('child_process');
const path = require('path');
const http = require('http');
const fs = require('fs');

let mainWindow;
let rProcess;
let loadingWindow;

function createWindow() {
  loadingWindow = new BrowserWindow({
    width: 400,
    height: 300,
    frame: false,
    transparent: true,
    alwaysOnTop: true,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true
    }
  });

  loadingWindow.loadURL(`data:text/html;charset=utf-8,
    <html>
    <head>
      <style>
        body {
          margin: 0;
          padding: 0;
          background: #f0f4f8;
          font-family: 'Segoe UI', sans-serif;
          display: flex;
          justify-content: center;
          align-items: center;
          height: 100vh;
        }
        .container {
          text-align: center;
          background: white;
          padding: 30px;
          border-radius: 10px;
          box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        h2 {
          color: #0072B2;
          margin-bottom: 10px;
        }
        .spinner {
          width: 50px;
          height: 50px;
          border: 5px solid #f3f3f3;
          border-top: 5px solid #0072B2;
          border-radius: 50%;
          animation: spin 1s linear infinite;
          margin: 20px auto;
        }
        @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
      </style>
    </head>
    <body>
      <div class="container">
        <h2>RSA-UVvis</h2>
        <div class="spinner"></div>
        <p>Iniciando aplicación...</p>
      </div>
    </body>
    </html>`);

  const isDev = !app.isPackaged;
  
  // En producción, la app está en resources/app/ (sin asar)
  const appPath = isDev ? __dirname : path.join(path.dirname(app.getPath('exe')), 'resources', 'app');
  
  console.log('📂 App path:', appPath);
  
  // Rutas directas (todo dentro de appPath)
  const rPortablePath = path.join(appPath, 'R-Portable', 'App', 'R-Portable');
  const rExecutable = path.join(rPortablePath, 'bin', 'Rscript.exe');
  const rLibPath = path.join(rPortablePath, 'library');
  const rScriptPath = path.join(appPath, 'start-shiny.R');
  const shinyPath = path.join(appPath, 'shiny');
  
  console.log('🖥️ R executable:', rExecutable);
  console.log('📚 R lib path:', rLibPath);
  console.log('📜 R script:', rScriptPath);
  console.log('📁 Shiny path:', shinyPath);
  
  // Verificaciones
  const errores = [];
  if (!fs.existsSync(rExecutable)) errores.push('R executable');
  if (!fs.existsSync(rLibPath)) errores.push('R libraries');
  if (!fs.existsSync(rScriptPath)) errores.push('start-shiny.R');
  if (!fs.existsSync(shinyPath)) errores.push('shiny folder');
  
  if (errores.length > 0) {
    console.error('❌ Faltan:', errores.join(', '));
    loadingWindow.close();
    return;
  }
  
  console.log('✅ Todo verificado, iniciando R...');
  
  // Variables de entorno
  const env = {
    ...process.env,
    R_LIBS: rLibPath,
    R_LIBS_USER: rLibPath,
    R_LIBS_SITE: rLibPath
  };
  
  // Ejecutar R
  rProcess = spawn(rExecutable, [rScriptPath], {
    cwd: appPath,
    shell: true,
    env: env
  });
  
  rProcess.stdout.on('data', (data) => {
    console.log('📤 R:', data.toString());
  });
  
  rProcess.stderr.on('data', (data) => {
    console.error('🔴 R error:', data.toString());
  });
  
  // Verificar Shiny
  function checkShiny() {
    http.get('http://127.0.0.1:8888', (res) => {
      if (res.statusCode === 200) {
        console.log('✅ Shiny listo!');
        
        mainWindow = new BrowserWindow({
          width: 1200,
          height: 800,
          show: false,
          webPreferences: {
            nodeIntegration: false,
            contextIsolation: false
          }
        });
        
        mainWindow.loadURL('http://127.0.0.1:8888');
        
        mainWindow.once('ready-to-show', () => {
          mainWindow.show();
          if (loadingWindow) loadingWindow.close();
        });
        
      } else {
        setTimeout(checkShiny, 1000);
      }
    }).on('error', () => {
      setTimeout(checkShiny, 1000);
    });
  }
  
  setTimeout(checkShiny, 3000);
}

app.whenReady().then(createWindow);

app.on('window-all-closed', () => {
  if (rProcess) rProcess.kill();
  if (process.platform !== 'darwin') app.quit();
});