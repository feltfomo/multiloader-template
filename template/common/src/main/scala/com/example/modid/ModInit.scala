package com.example.modid

import org.slf4j.LoggerFactory

// shared, server-safe logic starts here
object ModInit:
  private val modId = "modid"
  private val logger = LoggerFactory.getLogger(modId)

  def init(): Unit =
    logger.info("{} common init", modId)
