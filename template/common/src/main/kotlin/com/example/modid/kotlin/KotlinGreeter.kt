package com.example.modid.kotlin

import org.slf4j.LoggerFactory

// Kotlin sample: common-side logic called from the Java entry point (ModInit).
// Kotlin is great for mod logic but is intentionally not used for mixins; its
// compiled output (synthetic classes, null checks, name mangling) fights the
// Mixin bytecode model. Delete this file and the call in ModInit to drop Kotlin.
object KotlinGreeter {
    private val LOGGER = LoggerFactory.getLogger("modid")

    @JvmStatic
    fun greet() {
        LOGGER.info("hello from kotlin — common logic, no mixin needed")
    }
}
