package com.example.modid.neoforge;

import com.example.modid.client.@@CLIENT_INIT_TYPE@@;
import net.neoforged.api.distmarker.Dist;
import net.neoforged.fml.common.Mod;

// a separate client annotation prevents client classes from loading on servers
@Mod(value = "modid", dist = Dist.CLIENT)
public final class NeoForgeClientEntry {
    public NeoForgeClientEntry() {
        @@CLIENT_INIT_CALL@@
    }
}
