package com.example.modid

import org.slf4j.LoggerFactory

// Optional Kotlin sample. Flip `kotlin = true` in pkl/mod.pkl and this compiles
// into common; kotlin-stdlib is bundled into each loader jar automatically.
// Standalone by design -- the Java core never calls it, so the mod still builds
// with Kotlin off. Wire ExampleKotlin.init() into your own code, or delete this.
object ExampleKotlin {
    private val logger = LoggerFactory.getLogger("modid/kotlin")

    fun greet(): String = "hello from kotlin"

    fun init() = logger.info(greet())
}
