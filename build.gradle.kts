plugins {
    kotlin("jvm") version "2.4.20"
    id("net.blueva.mawu") version "26.3"
    id("com.gradleup.shadow") version "9.6.1"
    application
}

group = "net.blueva"
version = providers.gradleProperty("version")
    .orElse(providers.environmentVariable("RELEASE_VERSION"))
    .get()

repositories {
    mavenCentral()
    maven("https://repo.blueva.net/releases")
    maven("https://maven.fabricmc.net/")
    maven("https://www.jetbrains.com/intellij-repository/releases")
}

dependencies {
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.11.0")
    implementation("com.jetbrains.intellij.java:java-decompiler-engine:262.10968.63")
    implementation("net.fabricmc:mapping-io:0.9.1")
    implementation("net.fabricmc:tiny-remapper:0.14.1")
    implementation("org.apache.commons:commons-compress:1.28.0")

    testImplementation(kotlin("test"))
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}

mawu {
    // The primitives the Kotlin host installs before any script runs (see host/Host.kt).
    knownGlobals.addAll("use", "host", "term", "http", "fs", "zip", "process", "json", "remap")
}

kotlin {
    jvmToolchain(25)
}

application {
    applicationName = "minesrc"
    mainClass.set("net.blueva.minesrc.MineSrcKt")
}

// `./gradlew run` writes into run/, which git ignores.
tasks.named<JavaExec>("run") {
    val directory = layout.projectDirectory.dir("run").asFile
    workingDir = directory
    doFirst { directory.mkdirs() }
}

// The jar users download: everything inside, runnable with `java -jar minesrc-<version>.jar`.
tasks.shadowJar {
    archiveBaseName.set("minesrc")
    archiveClassifier.set("")
    exclude("META-INF/*.SF", "META-INF/*.DSA", "META-INF/*.RSA", "META-INF/*.EC")
    mergeServiceFiles()
}

tasks.jar {
    // The thin jar only feeds installDist; keep its name apart from the one users get.
    archiveClassifier.set("thin")
}

tasks.build {
    dependsOn(tasks.shadowJar)
}

tasks.processResources {
    filesMatching("minesrc.properties") {
        expand("version" to project.version)
    }
}

tasks.test {
    useJUnitPlatform()
    // The Lua suites under tests/network/ talk to Mojang, PaperMC and SpigotMC, so they only run with -Pnetwork.
    systemProperty("minesrc.network", providers.gradleProperty("network").isPresent)
    // Keeps what the suites download and unpack out of the user's own MineSrc home.
    environment("MINESRC_HOME", layout.buildDirectory.dir("test-home").get().asFile.absolutePath)
}
