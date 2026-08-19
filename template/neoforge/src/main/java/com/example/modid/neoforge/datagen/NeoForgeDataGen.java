package com.example.modid.neoforge.datagen;

import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.neoforge.data.event.GatherDataEvent;

// the static subscriber disappears entirely when datagen is disabled
@EventBusSubscriber(modid = "modid")
public final class NeoForgeDataGen {
  @SubscribeEvent
  public static void gatherData(GatherDataEvent.Server event) {
    event.createProvider(SampleRecipeProvider.Runner::new);
  }
}
