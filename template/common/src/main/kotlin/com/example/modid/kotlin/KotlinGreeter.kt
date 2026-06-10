package com.example.modid.kotlin

import org.slf4j.LoggerFactory

// Kotlin sample: common-side logic, called from ModInit.
// Delete this file and the call in ModInit to drop Kotlin.
object KotlinGreeter {
    private val LOGGER = LoggerFactory.getLogger("modid")

    @JvmStatic
    fun greet() {
        LOGGER.info("hello from kotlin — common logic, no mixin needed")
    }
}
