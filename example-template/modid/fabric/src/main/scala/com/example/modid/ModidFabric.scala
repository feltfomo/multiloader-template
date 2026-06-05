package com.example.modid

import net.fabricmc.api.ModInitializer
import com.example.modid.ModidCommon

object ModidFabric extends ModInitializer:
  override def onInitialize(): Unit =
    ModidCommon.init()
