package com.example.modid.fabric.datagen;

import net.fabricmc.fabric.api.datagen.v1.DataGeneratorEntrypoint;
import net.fabricmc.fabric.api.datagen.v1.FabricDataGenerator;

// Fabric datagen entrypoint, registered under "fabric-datagen" in fabric.mod.json
// (Pkl renders that entry when datagen is on). Add providers to the pack here.
// Run with: ./gradlew :fabric:runDatagen
public final class FabricDataGen implements DataGeneratorEntrypoint {
  @Override
  public void onInitializeDataGenerator(FabricDataGenerator generator) {
    FabricDataGenerator.Pack pack = generator.createPack();
    pack.addProvider(SampleRecipeProvider::new);
  }
}
