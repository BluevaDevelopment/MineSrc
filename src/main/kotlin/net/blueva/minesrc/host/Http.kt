/*
 * MineSrc
 * https://github.com/BluevaDevelopment/MineSrc
 *
 * Copyright (c) 2026 Blueva Development
 *
 * SPDX-License-Identifier: MIT
 */
package net.blueva.minesrc.host

import java.io.IOException
import java.net.URI
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardCopyOption
import java.security.MessageDigest
import java.time.Duration
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicLong

/**
 * `http`: requests and file transfers. Transfers run in the background, so a
 * script can draw progress, or keep several going, while it waits on them.
 */
class Http {

    private val client: HttpClient = HttpClient.newBuilder()
        .followRedirects(HttpClient.Redirect.NORMAL)
        .connectTimeout(Duration.ofSeconds(30))
        .build()

    private var userAgent = "minesrc"

    /** Sent with every request; some APIs refuse generic agents. */
    fun userAgent(value: String) {
        userAgent = value
    }

    /** The body of [url] as text, or null when it answers 404. */
    fun get(url: String): String? {
        val response = send(url, HttpResponse.BodyHandlers.ofString())
        if (response.statusCode() == 404) return null
        check(url, response.statusCode())
        return response.body()
    }

    /**
     * Starts downloading [url] into [target]. With an [algorithm] (`sha1`,
     * `sha256`, `sha512`, `md5`) the file must match [hex], or it is discarded.
     */
    fun start(url: String, target: String, algorithm: String?, hex: String?): Transfer {
        val transfer = Transfer()
        Thread.ofVirtual().start { transfer.run(url, Path.of(target), algorithm, hex) }
        return transfer
    }

    inner class Transfer internal constructor() {

        private val done = CountDownLatch(1)
        private val received = AtomicLong()

        @Volatile
        private var total = -1L

        @Volatile
        private var found = true

        @Volatile
        private var failure: String? = null

        /** Waits up to [milliseconds]; true once the transfer is over, either way. */
        fun await(milliseconds: Int): Boolean = done.await(milliseconds.toLong(), TimeUnit.MILLISECONDS)

        fun received(): Long = received.get()

        /** The size the server announced, or -1. */
        fun total(): Long = total

        /** False when the server answered 404. */
        fun found(): Boolean = found

        /** Why the transfer failed, or null. */
        fun failure(): String? = failure

        internal fun run(url: String, target: Path, algorithm: String?, hex: String?) {
            var partial: Path? = null
            try {
                Files.createDirectories(target.parent)
                // Unique, so two transfers of one file never share a partial file.
                partial = Files.createTempFile(target.parent, target.fileName.toString(), ".part")
                val response = send(url, HttpResponse.BodyHandlers.ofInputStream())
                if (response.statusCode() == 404) {
                    response.body().close()
                    found = false
                    return
                }
                check(url, response.statusCode())
                total = response.headers().firstValueAsLong("Content-Length").orElse(-1)

                val digest = algorithm?.let { MessageDigest.getInstance(DIGESTS[it] ?: error("Unknown checksum '$it'")) }
                response.body().use { input ->
                    Files.newOutputStream(partial).use { output ->
                        val buffer = ByteArray(1 shl 16)
                        while (true) {
                            val read = input.read(buffer)
                            if (read < 0) break
                            output.write(buffer, 0, read)
                            digest?.update(buffer, 0, read)
                            received.addAndGet(read.toLong())
                        }
                    }
                }
                if (digest != null) {
                    val actual = digest.digest().joinToString("") { "%02x".format(it) }
                    if (!actual.equals(hex, ignoreCase = true)) {
                        failure = "${target.fileName} from $url does not match its $algorithm (expected $hex, got $actual)"
                        return
                    }
                }
                Files.move(partial, target, StandardCopyOption.REPLACE_EXISTING, StandardCopyOption.ATOMIC_MOVE)
            } catch (exception: Exception) {
                failure = exception.message ?: exception.toString()
            } finally {
                partial?.let { Files.deleteIfExists(it) }
                done.countDown()
            }
        }
    }

    private fun <T> send(url: String, handler: HttpResponse.BodyHandler<T>): HttpResponse<T> {
        val request = HttpRequest.newBuilder(URI.create(url))
            .header("User-Agent", userAgent)
            .timeout(Duration.ofMinutes(5))
            .GET()
            .build()
        var failure: IOException? = null
        repeat(ATTEMPTS) {
            try {
                return client.send(request, handler)
            } catch (exception: IOException) {
                failure = exception
            }
        }
        throw IOException("Could not reach $url: ${failure?.message}", failure)
    }

    private fun check(url: String, status: Int) {
        if (status !in 200..299) throw IOException("$url answered HTTP $status")
    }

    private companion object {
        const val ATTEMPTS = 3
        val DIGESTS = mapOf("md5" to "MD5", "sha1" to "SHA-1", "sha256" to "SHA-256", "sha512" to "SHA-512")
    }
}
