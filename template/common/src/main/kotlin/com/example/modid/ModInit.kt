package com.example.modid

import org.slf4j.LoggerFactory

// shared, server-safe logic starts here
object ModInit {
  private const val MOD_ID = "modid"
  private val logger = LoggerFactory.getLogger(MOD_ID)

  @JvmStatic
  fun init() {
    logger.info("{} common init", MOD_ID)
  }
}
