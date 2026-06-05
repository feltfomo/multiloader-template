package com.example.modid

import net.neoforged.bus.api.IEventBus
import net.neoforged.fml.ModContainer
import net.neoforged.fml.common.Mod
import com.example.modid.ModidCommon
import com.example.modid.ModidConstants.MOD_ID

@Mod(MOD_ID)
object ModidNeoForge:
  def apply(bus: IEventBus, container: ModContainer): Unit =
    ModidCommon.init()
