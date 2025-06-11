# Projeto lucasbeatsfederacao - VoIP App

## Estrutura do Projeto

```
projeto_organizado/
├── frontend/          # Flutter App
│   ├── lib/
│   │   ├── services/
│   │   │   ├── voip_service.dart      # ✅ Novo - Gerenciamento de chamadas VoIP
│   │   │   ├── signaling_service.dart # ✅ Atualizado - Sinalização WebRTC
│   │   │   ├── socket_service.dart    # ✅ Atualizado - Comunicação Socket.IO
│   │   │   └── api_service.dart       # ✅ Existente - Comunicação HTTP
│   │   ├── screens/
│   │   │   ├── call_page.dart         # ✅ Implementado - Interface de chamada
│   │   │   └── call_history_page.dart # ✅ Novo - Histórico de chamadas
│   │   ├── widgets/
│   │   │   └── incoming_call_overlay.dart # ✅ Novo - Overlay para chamadas recebidas
│   │   └── main.dart                  # ✅ Atualizado - Providers VoIP
│   └── pubspec.yaml
└── backend/           # Node.js API
    ├── controllers/
    │   └── voipController.js          # ✅ Novo - Lógica de chamadas VoIP
    ├── routes/
    │   └── voipRoutes.js              # ✅ Novo - Endpoints VoIP
    ├── middleware/
    │   └── voipAuth.js                # ✅ Novo - Autenticação VoIP
    ├── models/
    │   └── Call.js                    # ✅ Novo - Schema de chamadas
    ├── config/
    │   ├── environment.js             # ✅ Novo - Variáveis de ambiente
    │   └── db.js                      # ✅ Atualizado - Conexão MongoDB
    └── server.js                      # ✅ Atualizado - Socket.IO + VoIP
```

## Funcionalidades Implementadas

### Frontend (Flutter)

#### 1. VoipService
- ✅ Iniciar chamadas VoIP
- ✅ Aceitar/rejeitar chamadas
- ✅ Encerrar chamadas
- ✅ Gerenciamento de estado da chamada
- ✅ Histórico de chamadas
- ✅ Timer de duração

#### 2. CallPage
- ✅ Interface completa de chamada
- ✅ Controles de áudio (mute/speaker)
- ✅ Animações de pulso
- ✅ Estados visuais (calling, connected, etc.)
- ✅ Botões de aceitar/rejeitar

#### 3. IncomingCallOverlay
- ✅ Overlay para chamadas recebidas
- ✅ Notificações em tempo real
- ✅ Integração com CallPage

#### 4. CallHistoryPage
- ✅ Lista de chamadas anteriores
- ✅ Filtros por tipo (recebida/realizada)
- ✅ Informações de duração
- ✅ Botão para nova chamada

### Backend (Node.js)

#### 1. VoIP Controller
- ✅ POST /api/voip/call/initiate - Iniciar chamada
- ✅ POST /api/voip/call/accept - Aceitar chamada
- ✅ POST /api/voip/call/reject - Rejeitar chamada
- ✅ POST /api/voip/call/end - Encerrar chamada
- ✅ GET /api/voip/call/history - Histórico de chamadas

#### 2. Socket.IO Events
- ✅ join_voice_call - Entrar em chamada
- ✅ leave_voice_call - Sair de chamada
- ✅ signal - Sinalização WebRTC
- ✅ user_joined_call - Usuário entrou
- ✅ user_left_call - Usuário saiu

#### 3. Database Schema
- ✅ Calls collection com MongoDB
- ✅ Índices para performance
- ✅ Relacionamentos com usuários

## Configuração

### Backend
```bash
cd backend
npm install
# Configurar variáveis de ambiente
MONGO_URI=mongodb+srv://lidcloned:Lucasday25@backend-voip.yru2hf8.mongodb.net/
JWT_SECRET=Lucasday25
PORT=3000
npm start
```

### Frontend
```bash
cd frontend
flutter pub get
flutter run
```

## Endpoints da API

### Autenticação
- POST /api/auth/login
- POST /api/auth/register

### VoIP
- POST /api/voip/call/initiate
- POST /api/voip/call/accept
- POST /api/voip/call/reject
- POST /api/voip/call/end
- GET /api/voip/call/history

### Outros
- GET /api/channels
- GET /api/users
- GET /api/voice-channels

## Fluxo de Chamada VoIP

1. **Iniciar Chamada**
   - Frontend chama VoipService.initiateCall()
   - API POST /api/voip/call/initiate
   - Socket.IO notifica destinatário

2. **Receber Chamada**
   - IncomingCallOverlay aparece
   - Usuário aceita/rejeita
   - CallPage abre se aceita

3. **Durante a Chamada**
   - WebRTC para áudio
   - Socket.IO para sinalização
   - CallProvider gerencia estado

4. **Encerrar Chamada**
   - Qualquer usuário pode encerrar
   - API POST /api/voip/call/end
   - Cleanup de recursos

## Tecnologias Utilizadas

### Frontend
- Flutter/Dart
- Provider (State Management)
- flutter_webrtc (WebRTC)
- socket_io_client (Socket.IO)
- http (API calls)

### Backend
- Node.js
- Express.js
- Socket.IO
- MongoDB
- JWT Authentication

## Deploy

### Backend
- Deploy no Render.com
- URL: https://beckend-ydd1.onrender.com

### Frontend
- Build via Codemagic
- APK para Android

## Próximos Passos

1. Testes de integração
2. Notificações push
3. Qualidade de chamada
4. Gravação de chamadas
5. Chamadas em grupo

