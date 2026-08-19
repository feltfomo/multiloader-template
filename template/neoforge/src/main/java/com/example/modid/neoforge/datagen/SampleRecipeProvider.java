package com.example.modid.neoforge.datagen;

import java.util.concurrent.CompletableFuture;

import net.minecraft.core.HolderLookup;
import net.minecraft.data.PackOutput;
import net.minecraft.data.recipes.RecipeCategory;
import net.minecraft.data.recipes.RecipeOutput;
import net.minecraft.data.recipes.RecipeProvider;
import net.minecraft.resources.Identifier;
import net.minecraft.world.item.Items;

// the sample writes only under the generated mod id
public final class SampleRecipeProvider extends RecipeProvider {
    private static final String MOD_ID = "modid";
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
                .save(recipeOutput, Identifier.fromNamespaceAndPath(MOD_ID, "sample_recipe").toString());
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
