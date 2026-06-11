package com.example.modid.neoforge.datagen;

import java.util.concurrent.CompletableFuture;

import net.minecraft.core.HolderLookup;
import net.minecraft.data.PackOutput;
import net.minecraft.data.recipes.RecipeCategory;
import net.minecraft.data.recipes.RecipeOutput;
import net.minecraft.data.recipes.RecipeProvider;
import net.minecraft.resources.Identifier;
import net.minecraft.world.item.Items;

import com.example.modid.ModInit;

// Sample recipe provider -- a starting point you can delete. It only touches
// vanilla items and saves under the mod id, so it never overwrites a vanilla
// recipe. Replace the body of buildRecipes() with your own. The nested Runner
// is what GatherDataEvent hands off to; it just builds this provider.
public final class SampleRecipeProvider extends RecipeProvider {
    private final RecipeOutput recipeOutput;

    public SampleRecipeProvider(HolderLookup.Provider registries, RecipeOutput output) {
        super(registries, output);
        this.recipeOutput = output;
    }

    @Override
    protected void buildRecipes() {
        shapeless(RecipeCategory.MISC, Items.DIRT)
                .requires(Items.COARSE_DIRT)
                .unlockedBy(getHasName(Items.COARSE_DIRT), has(Items.COARSE_DIRT))
                .save(recipeOutput, Identifier.fromNamespaceAndPath(ModInit.MOD_ID, "sample_recipe").toString());
    }

    public static final class Runner extends RecipeProvider.Runner {
        public Runner(PackOutput output, CompletableFuture<HolderLookup.Provider> registries) {
            super(output, registries);
        }

        @Override
        protected RecipeProvider createRecipeProvider(HolderLookup.Provider registries, RecipeOutput output) {
            return new SampleRecipeProvider(registries, output);
        }

        @Override
        public String getName() {
            return "SampleRecipeProvider";
        }
    }
}
