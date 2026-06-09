package com.example.modid

import net.neoforged.api.distmarker.Dist
import net.neoforged.bus.api.IEventBus
import net.neoforged.fml.common.Mod
import com.example.modid.ModidCommon
import com.example.modid.client.ModidClientCommon
import com.example.modid.ModidConstants.MOD_ID

@Mod(MOD_ID)
class ModidNeoForge(modBus: IEventBus, dist: Dist):
  ModidCommon.init()
  if dist == Dist.CLIENT then ModidClientCommon.init()
