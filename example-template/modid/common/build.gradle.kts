// Compiled against vanilla MC only — no Fabric, no NeoForge.
plugins {
    id("java-library")
    id("org.jetbrains.kotlin.jvm")
    id("scala")
    id("net.fabricmc.fabric-loom")
}

val minecraftVersion: String = providers.gradleProperty("minecraft_version").get()
val scalaVersion: String     = providers.gradleProperty("scala_version").get()

java.toolchain.languageVersion = JavaLanguageVersion.of(25)

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_25)
    }
}

dependencies {
    minecraft("com.mojang:minecraft:$minecraftVersion")
    implementation("org.scala-lang:scala3-library_3:$scalaVersion")
}

sourceSets {
    val main by getting
    create("client") {
        compileClasspath += main.compileClasspath + main.output
        runtimeClasspath += main.runtimeClasspath + main.output
    }
}

sourceSets.configureEach {
    java.srcDir("src/$name/java")
    scala.srcDir("src/$name/scala")
    resources.srcDir("src/$name/resources")
}

kotlin {
    sourceSets.configureEach {
        kotlin.srcDir("src/$name/kotlin")
    }
}

// Scala goes last so it can see Java and Kotlin classes at compile time
tasks.named("compileClientScala") { dependsOn("compileClientKotlin", "compileClientJava") }
tasks.named("compileScala")       { dependsOn("compileKotlin", "compileJava") }

tasks.withType<JavaCompile>().configureEach {
    options.encoding = "UTF-8"
    options.release  = 25
}

tasks.withType<ProcessResources>().configureEach {
    duplicatesStrategy = DuplicatesStrategy.EXCLUDE
}
