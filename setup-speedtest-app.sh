#!/bin/bash

# Nome do projeto
PROJECT_NAME="speedtest-electron-app-ByProkapa"

# Verifica se o Node.js e npm estão instalados
if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
    echo "Node.js e npm não estão instalados. Instalando..."
    sudo pacman -S --needed nodejs npm
fi

# Cria a pasta do projeto
echo "Criando projeto $PROJECT_NAME..."
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME" || exit

# Inicializa o projeto Node.js
echo "Inicializando o projeto..."
npm init -y

# Baixa o ícone do Speedtest
echo "Baixando o ícone do Speedtest..."
mkdir -p assets
wget -O assets/icon.png https://m.media-amazon.com/images/I/2165FoT1qvL.png

# Cria o arquivo main.js
echo "Criando arquivo main.js..."
cat <<EOL > main.js
const { app, BrowserWindow, session } = require('electron');

let mainWindow;

app.on('ready', () => {
    app.setName("SpeedtestApp"); // Define o nome do aplicativo (WM_CLASS no Linux)
    mainWindow = new BrowserWindow({
        width: 1250, // Largura fixa
        height: 850, // Altura fixa
        resizable: false, // Desativa o redimensionamento da janela
        icon: __dirname + '/assets/icon.png', // Define o ícone do aplicativo
        title: "Speedtest App", // Nome da janela principal
        webPreferences: {
            contextIsolation: true,
            enableRemoteModule: false,
            nodeIntegration: false
        }
    });

    // Carrega o site do Speedtest
    mainWindow.loadURL('https://www.speedtest.net');

    // Injeta CSS e JavaScript para corrigir comportamento de scroll
    mainWindow.webContents.on('did-finish-load', () => {
        mainWindow.webContents.insertCSS(\`
            body, html {
                margin: 0;
                padding: 0;
                width: 100%;
                height: 850px; /* Define altura fixa de 850px */
                overflow: hidden; /* Remove funcionalidade de rolagem */
                scrollbar-width: none; /* Remove barras de rolagem no Firefox */
            }

            ::-webkit-scrollbar {
                display: none;
            }

            body {
                transform: translateY(0); /* Garante que o conteúdo começa no topo */
            }
        \`);

        mainWindow.webContents.executeJavaScript(\`
            window.scrollTo(0, 0);
        \`);
    });

    // Bloqueio de anúncios
    session.defaultSession.webRequest.onBeforeRequest((details, callback) => {
        const blockList = [
            /.*\.googlesyndication\.com.*/,
            /.*\.doubleclick\.net.*/,
            /.*\.adservice\.google\.com.*/,
            /.*\.ads-twitter\.com.*/,
            /.*\.ads\.speedtest\.net.*/,
            /.*\.analytics\.speedtest\.net.*/
        ];

        if (blockList.some((regex) => regex.test(details.url))) {
            callback({ cancel: true });
        } else {
            callback({});
        }
    });
});

app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') {
        app.quit();
    }
});
EOL

# Configura o package.json
echo "Configurando package.json para o electron-builder..."
cat <<EOL > package.json
{
  "name": "speedtest-electron-app-byprokapa",
  "version": "1.0.0",
  "description": "Speedtest Electron App",
  "author": "Maicon Moraes",
  "main": "main.js",
  "scripts": {
    "start": "electron .",
    "dist": "electron-builder"
  },
  "devDependencies": {
    "electron": "25.4.0",
    "electron-builder": "23.6.0"
  },
  "build": {
    "appId": "com.example.speedtestapp",
    "productName": "SpeedtestApp",
    "linux": {
      "target": "AppImage",
      "icon": "assets/icon.png",
      "category": "Utility"
    }
  }
}
EOL

# Reinstala dependências para garantir que tudo está correto
echo "Instalando dependências..."
npm install

# Gera o AppImage
echo "Criando o AppImage..."
npm run dist

# Cria o arquivo .desktop
echo "Criando o atalho .desktop..."
cat <<EOL > ~/.local/share/applications/speedtestapp.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=Speedtest App
Comment=Teste a velocidade de sua conexão com o Speedtest
Exec=$PWD/dist/SpeedtestApp-1.0.0.AppImage
Icon=$PWD/assets/icon.png
Terminal=false
Categories=Utility;Network;
StartupWMClass=SpeedtestApp
EOL

# Atualiza a base de dados de atalhos
echo "Atualizando banco de dados de atalhos..."
update-desktop-database ~/.local/share/applications/

echo "Setup completo! O aplicativo está pronto para ser executado e fixado nos favoritos."
