# Comprinhas

App Flutter do projeto Comprinhas.

## Plataformas suportadas

Atualmente o projeto mantém suporte ativo para `Android`.

Há também uma versão `Web` em implantação inicial, com escopo focado no
domínio de listas e compartilhamento por URL hospedada no Firebase Hosting.

O suporte a `iOS` está em processo de depreciação e não deve mais ser tratado
como plataforma alvo para configuração, build ou validação do app.

## Desenvolvimento

Comandos úteis no diretório raiz:

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `dart format lib test`
- `flutter build web`

## Web e Hosting

- O deploy web usa `Firebase Hosting` estático com saída em `build/web`.
- O roteamento SPA é resolvido por rewrite para `/index.html`, então rotas como
  `/join/<codigo>` e `/list/<id>` funcionam após refresh.
- Antes de buildar para web, crie um `.env` a partir de `.env.example`.
- Fluxo de deploy:
  - `flutter build web`
  - `firebase deploy --only hosting`
