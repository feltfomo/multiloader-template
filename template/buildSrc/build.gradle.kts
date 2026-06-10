plugins {
    `kotlin-dsl`
}

repositories {
    mavenCentral()
}

dependencies {
    // Embed the Pkl evaluator so the build reads mod.pkl directly, with no
    // `pkl` binary on PATH. This is what lets identity live in one file.
    implementation("org.pkl-lang:pkl-core:0.31.1")
}
