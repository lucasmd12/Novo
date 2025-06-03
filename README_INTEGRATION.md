# Resumo da Integração com Backend Render/MongoDB

Este documento resume as alterações realizadas no projeto Flutter `PROJETObaseEMANDAMENTO` para integrá-lo com o backend hospedado no Render (`https://beckend-ydd1.onrender.com`) que utiliza MongoDB e autenticação JWT, removendo as dependências anteriores do Firebase.

## Principais Alterações:

1.  **Remoção do Firebase:**
    *   As dependências `firebase_core`, `firebase_auth` e `cloud_firestore` foram removidas do arquivo `pubspec.yaml`.
    *   O arquivo `android/app/google-services.json` foi removido do projeto.
    *   Todo o código que utilizava Firebase Auth para autenticação e Firestore para armazenamento de dados foi removido dos arquivos de serviço (`lib/services/*.dart`).

2.  **Integração com API REST (Render):**
    *   Adicionada a dependência `http` ao `pubspec.yaml` para realizar chamadas de API.
    *   Criado o arquivo `lib/utils/constants.dart` para centralizar a URL base da API (`https://beckend-ydd1.onrender.com/api`) e outras constantes, como o segredo JWT (embora o segredo JWT seja usado no backend, foi incluído para referência).
    *   Os serviços (`AuthService`, `MissionService`, `QuestionnaireService`, `RoleService`) foram refatorados para fazer chamadas HTTP (GET, POST, PUT, PATCH, DELETE) aos endpoints correspondentes da API no Render.
    *   **Observação:** Os endpoints exatos (ex: `/users/me/missions`, `/missions/:id/status`, `/questionnaires/:id/responses`, etc.) foram baseados em padrões REST comuns. Pode ser necessário ajustá-los nos arquivos de serviço para corresponder exatamente à estrutura da sua API no backend.

3.  **Autenticação JWT:**
    *   Adicionada a dependência `flutter_secure_storage` ao `pubspec.yaml` para armazenar o token JWT de forma segura no dispositivo.
    *   O `AuthService` foi modificado para:
        *   Obter um token JWT do endpoint `/auth/login`.
        *   Armazenar o token usando `flutter_secure_storage`.
        *   Incluir o token JWT no cabeçalho `Authorization: Bearer <token>` de todas as requisições autenticadas feitas pelos outros serviços.
        *   Remover o token durante o logout (`signOut`).

4.  **Estrutura dos Serviços:**
    *   Métodos que antes retornavam `Stream` (do Firestore) foram adaptados para retornar `Future` (resultado de chamadas HTTP).
    *   A lógica de tratamento de erros foi ajustada para lidar com respostas e exceções HTTP.

## Próximos Passos e Considerações:

*   **Testes:** É crucial testar exaustivamente a comunicação entre o aplicativo Flutter e o backend no Render para garantir que todos os fluxos (login, registro, visualização/criação/atualização de missões, questionários, etc.) funcionem como esperado.
*   **Endpoints da API:** Verifique se os endpoints definidos nos arquivos de serviço (`lib/services/*.dart`) correspondem exatamente aos endpoints implementados no seu backend Node.js/Express no Render.
*   **Modelo de Dados (`UserModel`, `MissionModel`, etc.):** Certifique-se de que os métodos `toMap()` e `fromMap()` nos seus modelos de dados (`lib/models/*.dart`) estão alinhados com a estrutura dos dados JSON enviados e recebidos pela API.
*   **MongoDB Atlas IP Access List:** Conforme discutido, lembre-se de adicionar os IPs de saída do Render à lista de acesso do seu cluster MongoDB Atlas para permitir a conexão do backend ao banco de dados.
*   **Gerenciamento de Estado:** A refatoração dos serviços para usar `Future` em vez de `Stream` pode exigir ajustes na forma como o estado é gerenciado nas telas (usando `FutureBuilder` em vez de `StreamBuilder`, por exemplo).

O projeto agora está configurado para se comunicar exclusivamente com o seu backend no Render, utilizando autenticação JWT.
