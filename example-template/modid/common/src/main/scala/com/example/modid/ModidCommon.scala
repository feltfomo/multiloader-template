package com.example.modid

import org.slf4j.LoggerFactory

object ModidCommon:
  val logger = LoggerFactory.getLogger(ModidConstants.MOD_ID)

  def init(): Unit =
    logger.info("Modid common init")
