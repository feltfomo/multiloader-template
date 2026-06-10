package com.example.modid.fabric.datagen;

import java.util.concurrent.CompletableFuture;

import net.minecraft.core.HolderLookup;
import net.minecraft.data.recipes.RecipeCategory;
import net.minecraft.data.recipes.RecipeOutput;
import net.minecraft.data.recipes.RecipeProvider;
import net.minecraft.resources.Identifier;
import net.minecraft.world.item.Items;

import net.fabricmc.fabric.api.datagen.v1.FabricPackOutput;
import net.fabricmc.fabric.api.datagen.v1.provider.FabricRecipeProvider;

import com.example.modid.ModInit;

// Sample recipe provider -- a starting point you can delete. It only touches
// vanilla items and saves under the mod id, so it never overwrites a vanilla
// recipe. Replace the body of buildRecipes() with your own.
public final class SampleRecipeProvider extends FabricRecipeProvider {
    public SampleRecipeProvider(FabricPackOutput output, CompletableFuture<HolderLookup.Provider> registries) {
        super(output, registries);
    }

    @Override
    protected RecipeProvider createRecipeProvider(HolderLookup.Provider registries, RecipeOutput output) {
        return new RecipeProvider(registries, output) {
            @Override
            public void buildRecipes() {
                shapeless(RecipeCategory.MISC, Items.DIRT)
                        .requires(Items.COARSE_DIRT)
                        .unlockedBy(getHasName(Items.COARSE_DIRT), has(Items.COARSE_DIRT))
                        .save(output, Identifier.fromNamespaceAndPath(ModInit.MOD_ID, "sample_recipe").toString());
            }
        };
    }

    @Override
    public String getName() {
        return "SampleRecipeProvider";
    }
}
