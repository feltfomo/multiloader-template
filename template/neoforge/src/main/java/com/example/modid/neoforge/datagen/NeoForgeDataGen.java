package com.example.modid.neoforge.datagen;

import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.neoforge.data.event.GatherDataEvent;

import com.example.modid.ModInit;

// Datagen lives entirely on this side: a static subscriber that hands the recipe
// runner to the serverData run. Recipes are datapack data, so we listen on
// GatherDataEvent.Server. NeoForge runs a single event bus now, so the
// subscriber needs only the mod id, no bus argument. Nothing wires into
// NeoForgeEntry, so turning datagen off is a clean delete of this package.
@EventBusSubscriber(modid = ModInit.MOD_ID)
public final class NeoForgeDataGen {
    @SubscribeEvent
    public static void gatherData(GatherDataEvent.Server event) {
        event.createProvider(SampleRecipeProvider.Runner::new);
    }
}
