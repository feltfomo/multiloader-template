package com.example.modid.client

import net.fabricmc.api.ClientModInitializer
import com.example.modid.client.ModidClientCommon

object ModidClientFabric extends ClientModInitializer:
  override def onInitializeClient(): Unit =
    ModidClientCommon.init()
