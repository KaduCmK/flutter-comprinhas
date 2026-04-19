# Android App Links para o domínio web

O app já possui suporte no código para receber links HTTPS do domínio:

- `https://comprinhas-460819.web.app/join/...`

Para que o Android abra o app instalado diretamente ao tocar no link, ainda é
necessário publicar um `assetlinks.json` válido no domínio com os fingerprints
SHA-256 corretos do certificado Android.

## Arquivo hospedado

O template versionado está em:

- `web/.well-known/assetlinks.json`

Depois do deploy, ele deve ficar acessível em:

- `https://comprinhas-460819.web.app/.well-known/assetlinks.json`

## O que substituir no template

Substituir os placeholders por fingerprints reais:

- `REPLACE_WITH_PLAY_APP_SIGNING_SHA256`
- `REPLACE_WITH_UPLOAD_OR_DEBUG_SHA256_IF_NEEDED`

## Qual fingerprint usar

Se o app for distribuído pela Play Store com Play App Signing:

- usar o SHA-256 do **App signing key certificate** na Play Console

Se também quiser suportar builds locais/CI instalados fora da Play:

- adicionar também o SHA-256 do certificado usado para assinar esses APKs/AABs

O `assetlinks.json` aceita múltiplos fingerprints no mesmo array.

## Onde buscar

### Play Console

- `Test and release` → `Setup` → `App integrity`
- copiar o SHA-256 de `App signing key certificate`

### Upload key / keystore local

Exemplo:

```bash
keytool -list -v -keystore /caminho/para/keystore.jks -alias SEU_ALIAS
```

## Validação

Após atualizar o arquivo e fazer deploy:

1. abrir `https://comprinhas-460819.web.app/.well-known/assetlinks.json`
2. confirmar que o JSON está público e sem placeholders
3. reinstalar ou atualizar o app Android
4. tocar em um link `https://comprinhas-460819.web.app/join/...`
5. verificar se o Android abre o app diretamente

## Referências

- Android Developers: Digital Asset Links / App Links
- Firebase: hospedar `assetlinks.json` em `/.well-known/`
