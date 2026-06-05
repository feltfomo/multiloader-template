package com.example.modid.client

import net.neoforged.api.distmarker.Dist
import net.neoforged.fml.common.Mod
import com.example.modid.client.ModidClientCommon
import com.example.modid.ModidConstants.MOD_ID

@Mod(value = MOD_ID, dist = Array(Dist.CLIENT))
object ModidClientNeoForge:
  def apply(): Unit =
    ModidClientCommon.init()
