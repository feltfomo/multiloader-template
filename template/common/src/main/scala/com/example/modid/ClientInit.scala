package com.example.modid.client

import org.slf4j.LoggerFactory

// physical-client logic starts here
object ClientInit:
  private val logger = LoggerFactory.getLogger("modid/client")

  def init(): Unit =
    logger.info("modid client init")
