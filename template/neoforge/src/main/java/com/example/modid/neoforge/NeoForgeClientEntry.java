package com.example.modid.neoforge;

import com.example.modid.ModInit;
import com.example.modid.client.ClientInit;
import net.neoforged.api.distmarker.Dist;
import net.neoforged.fml.common.Mod;

// NeoForge client shim. Second @Mod with the same id, scoped to the physical
// client via dist = CLIENT. Mirrors the Fabric client shim (ClientModInitializer).
@Mod(value = ModInit.MOD_ID, dist = Dist.CLIENT)
public final class NeoForgeClientEntry {
    public NeoForgeClientEntry() {
        ClientInit.init();
    }
}