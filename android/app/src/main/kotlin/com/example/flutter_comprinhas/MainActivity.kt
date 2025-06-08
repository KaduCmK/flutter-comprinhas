package io.github.kaducmk.flutter_comprinhas

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    // Variável para guardar o caminho do deep link quando o app inicia "do zero"
    private var initialLinkPath: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        // Tenta processar o link ANTES de chamar o onCreate da classe pai
        intent.data?.let { initialLinkPath = parseDeepLink(it) }
        super.onCreate(savedInstanceState)
    }

    /**
     * Este método é chamado quando o app já está rodando (em segundo plano) e recebe um novo deep
     * link.
     */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        intent.data?.let {
            val path = parseDeepLink(it)
            path?.let { flutterEngine?.navigationChannel?.pushRoute(it) }
        }
    }

    /** Este método define a rota inicial quando o Flutter é carregado. */
    override fun getInitialRoute(): String? {
        // Se a gente processou um link no `onCreate`, usa ele como rota inicial.
        // Senão, usa a rota padrão ('/').
        return initialLinkPath ?: super.getInitialRoute()
    }

    /**
     * Função auxiliar para transformar a URI completa no caminho que o go_router entende. Ex: de
     * "comprinhas://join/123" para "/join/123"
     */
    private fun parseDeepLink(uri: Uri): String? {
        if (uri.scheme == "comprinhas") {
            var path = "/" + (uri.host ?: "") + (uri.path ?: "")
            if (uri.query != null && uri.query!!.isNotEmpty()) {
                path += "?" + uri.query
            }
            return path
        }
        return null
    }
}
