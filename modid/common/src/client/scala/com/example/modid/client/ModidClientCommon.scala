package com.example.modid.client

import com.example.modid.ModidCommon

object ModidClientCommon:
  def init(): Unit =
    ModidCommon.logger.info("Modid client init")
