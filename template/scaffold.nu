#!/usr/bin/env nu

# rewrites the copied template once, then removes itself

def fail [message: string, code: int = 1] {
  print --stderr $"error: ($message)"
  exit $code
}

def env-string [name: string, fallback: string = ""] {
  $env | get -o $name | default $fallback
}

def ask [label: string, fallback: string, non_interactive: bool] {
  if $non_interactive {
    $fallback
  } else {
    let reply = (input $"($label) [($fallback)]: ")
    if ($reply | is-empty) { $fallback } else { $reply }
  }
}

def truthy [value: string] {
  $value in ["1" "true" "TRUE" "yes" "YES" "y" "Y"]
}

def ask-bool [label: string, fallback: bool, non_interactive: bool] {
  if $non_interactive {
    $fallback
  } else {
    let hint = if $fallback { "Y/n" } else { "y/N" }
    let reply = (input $"($label) [($hint)]: " | str downcase)
    if ($reply | is-empty) { $fallback } else { $reply in ["y" "yes"] }
  }
}

def sed-replacement [value: string] {
  $value | ^sed -e 's/[&|\]/\\&/g' | str trim
}

def text-files [] {
  let args = [
    "." "-type" "f"
    "-not" "-path" "./.git/*"
    "-not" "-path" "*/build/*"
    "-not" "-path" "*/.gradle/*"
    "-not" "-path" "*/.kotlin/*"
    "-not" "-name" "gradle-wrapper.jar"
    "-not" "-name" "scaffold.nu"
    "-print"
  ]
  ^find ...$args | lines
}

def is-text [file: string] {
  let result = (do { ^grep -Iq . $file } | complete)
  $result.exit_code == 0
}

def remove-path [path: string] {
  if ($path | path exists) { rm -rf $path }
}

def prune-archetype [language: string, side: string] {
  if $language != "java" {
    remove-path "common/src/main/java/com/example/modid/ModInit.java"
    remove-path "common/src/client/java/com/example/modid/client/ClientInit.java"
  }
  if $language != "kotlin" { remove-path "common/src/main/kotlin" }
  if $language != "scala" { remove-path "common/src/main/scala" }

  if $side == "client" {
    remove-path "common/src/main/java/com/example/modid/ModInit.java"
    remove-path "common/src/main/kotlin/com/example/modid/ModInit.kt"
    remove-path "common/src/main/scala/com/example/modid/ModInit.scala"
    remove-path "common/src/main/java/com/example/modid/mixin/BootstrapMixin.java"
    remove-path "fabric/src/main/java/com/example/modid/fabric/FabricEntry.java"
    remove-path "neoforge/src/main/java/com/example/modid/neoforge/NeoForgeEntry.java"
  }

  if $side == "server" {
    remove-path "common/src/client"
    remove-path "common/src/main/kotlin/com/example/modid/ClientInit.kt"
    remove-path "common/src/main/scala/com/example/modid/ClientInit.scala"
    remove-path "fabric/src/client"
    remove-path "neoforge/src/main/java/com/example/modid/neoforge/NeoForgeClientEntry.java"
  }
}

def prune-datagen [] {
  for module in ["fabric" "neoforge"] {
    let root = ($module | path join "src")
    if ($root | path exists) {
      ^find $root -type d -name datagen -prune -print0 | ^xargs -0 -r rm -rf
    }
  }
  rm -rf fabric/src/main/generated neoforge/src/generated
}

def main [--non-interactive(-y)] {
  let root = ($env.FILE_PWD? | default $env.PWD)
  cd $root

  mut mod_id = (env-string "SCAFFOLD_ID")
  if ($mod_id | is-empty) { $mod_id = (ask "mod id (lowercase)" "mymod" $non_interactive) }

  mut mod_group = (env-string "SCAFFOLD_GROUP")
  if ($mod_group | is-empty) {
    $mod_group = (ask "group / package" $"com.example.($mod_id)" $non_interactive)
  }

  let default_name = ($mod_id | ^sed -E 's/(^|_)([a-z])/\U\2/g' | str trim)
  mut mod_name = (env-string "SCAFFOLD_NAME")
  if ($mod_name | is-empty) { $mod_name = (ask "display name" $default_name $non_interactive) }

  let mod_version = if $non_interactive { env-string "SCAFFOLD_VERSION" "1.0.0" } else { ask "version" (env-string "SCAFFOLD_VERSION" "1.0.0") false }
  let mod_authors = if $non_interactive { env-string "SCAFFOLD_AUTHORS" "yourname" } else { ask "authors" (env-string "SCAFFOLD_AUTHORS" "yourname") false }
  let mod_license = if $non_interactive { env-string "SCAFFOLD_LICENSE" "MIT" } else { ask "license" (env-string "SCAFFOLD_LICENSE" "MIT") false }
  let mod_desc = if $non_interactive { env-string "SCAFFOLD_DESC" "A Minecraft mod." } else { ask "description" (env-string "SCAFFOLD_DESC" "A Minecraft mod.") false }

  let side_env = (env-string "SCAFFOLD_SIDE")
  let mod_side = if ($side_env | is-empty) { ask "side (both, client, server)" "both" $non_interactive } else { $side_env }
  let language_env = (env-string "SCAFFOLD_LANGUAGE")
  let mod_language = if ($language_env | is-empty) { ask "language (java, kotlin, scala)" "java" $non_interactive } else { $language_env }

  if not ($mod_id =~ '^[a-z][a-z0-9_]*$') { fail $"mod id must match ^[a-z][a-z0-9_]*$ (got ($mod_id))" }
  if not ($mod_group =~ '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)*$') { fail $"group must look like com.example.($mod_id) (got ($mod_group))" }
  if not ($mod_side in ["both" "client" "server"]) { fail $"side must be both, client, or server (got ($mod_side))" }
  if not ($mod_language in ["java" "kotlin" "scala"]) { fail $"language must be java, kotlin, or scala (got ($mod_language))" }

  let datagen_env = (env-string "SCAFFOLD_DATAGEN")
  let datagen_default = $mod_side != "client"
  let mod_datagen = if ($datagen_env | is-empty) { ask-bool "include server datagen" $datagen_default $non_interactive } else { truthy $datagen_env }
  if ($mod_side == "client" and $mod_datagen) { fail "the bundled datagen starter emits server data, use --no-datagen for client mods" }

  let mod_group_path = ($mod_group | str replace -a "." "/")
  let init_type = if $mod_language == "scala" { "ModInit$" } else { "ModInit" }
  let client_type = if $mod_language == "scala" { "ClientInit$" } else { "ClientInit" }
  let init_call = if $mod_language == "scala" { "ModInit$.MODULE$.init();" } else { "ModInit.init();" }
  let client_call = if $mod_language == "scala" { "ClientInit$.MODULE$.init();" } else { "ClientInit.init();" }

  print "scaffolding"
  print $"  id        ($mod_id)"
  print $"  name      ($mod_name)"
  print $"  group     ($mod_group)"
  print $"  version   ($mod_version)"
  print $"  authors   ($mod_authors)"
  print $"  license   ($mod_license)"
  print $"  side      ($mod_side)"
  print $"  language  ($mod_language)"
  print $"  datagen   ($mod_datagen)"

  let replacements = {
    name: (sed-replacement $mod_name)
    authors: (sed-replacement $mod_authors)
    license: (sed-replacement $mod_license)
    desc: (sed-replacement $mod_desc)
    version: (sed-replacement $mod_version)
    init_type: (sed-replacement $init_type)
    client_type: (sed-replacement $client_type)
    init_call: (sed-replacement $init_call)
    client_call: (sed-replacement $client_call)
  }

  for file in (text-files) {
    if (is-text $file) {
      let sed_args = [
        "-i"
        "-e" 's|\bmodid\([[:space:]]*=\)|@@KEEP_MODID@@\1|g'
        "-e" ('s|com\.example\.modid|' + $mod_group + '|g')
        "-e" ('s|com/example/modid|' + $mod_group_path + '|g')
        "-e" ('s|\bmodid\b|' + $mod_id + '|g')
        "-e" ('s|\bModid\b|' + $replacements.name + '|g')
        "-e" ('s|yourname|' + $replacements.authors + '|g')
        "-e" ('s|@@MOD_INIT_TYPE@@|' + $replacements.init_type + '|g')
        "-e" ('s|@@CLIENT_INIT_TYPE@@|' + $replacements.client_type + '|g')
        "-e" ('s|@@MOD_INIT_CALL@@|' + $replacements.init_call + '|g')
        "-e" ('s|@@CLIENT_INIT_CALL@@|' + $replacements.client_call + '|g')
        "-e" 's|@@KEEP_MODID@@|modid|g'
        $file
      ]
      ^sed ...$sed_args
    }
  }

  let pkl_args = [
    "-i"
    "-e" ('s|^name = .*|name = "' + $replacements.name + '"|')
    "-e" ('s|^version = .*|version = "' + $replacements.version + '"|')
    "-e" ('s|^license = .*|license = "' + $replacements.license + '"|')
    "-e" ('s|^description = .*|description = "' + $replacements.desc + '"|')
    "-e" ('s|^side = .*|side = "' + $mod_side + '"|')
    "-e" ('s|^language = .*|language = "' + $mod_language + '"|')
    "-e" ('s|^datagen = .*|datagen = ' + ($mod_datagen | into string) + '|')
    "pkl/mod.pkl"
  ]
  ^sed ...$pkl_args

  prune-archetype $mod_language $mod_side
  if not $mod_datagen { prune-datagen }

  let package_dirs = (^find . -type d -path '*/com/example/modid' -print | lines)
  for package_dir in $package_dirs {
    let prefix = ($package_dir | str replace -r '/com/example/modid$' '')
    let new_dir = $"($prefix)/($mod_group_path)"
    mkdir $new_dir
    for entry in (ls -a $package_dir) { mv $entry.name $new_dir }
    rm -r $package_dir
  }

  ^find . -depth -type d -path '*/com/example' -empty -delete
  ^find . -depth -type d -path '*/com' -empty -delete

  let named_args = [
    "." "-depth" "-name" "*modid*"
    "-not" "-path" "./.git/*"
    "-not" "-path" "*/build/*"
    "-not" "-path" "*/.gradle/*"
    "-not" "-path" "*/.kotlin/*"
    "-print"
  ]
  for path in (^find ...$named_args | lines) {
    if ($path | path exists) {
      let parent = ($path | path dirname)
      let renamed = (($path | path basename) | str replace -a "modid" $mod_id)
      mv $path ($parent | path join $renamed)
    }
  }

  ^chmod +x gradlew mcw

  print "done, removing scaffold.nu"
  rm -f scaffold.nu
  print ""
  print "next"
  if $mod_side != "server" {
    print "  ./mcw :fabric:runClient"
    print "  ./mcw :neoforge:runClient"
  } else {
    print "  ./mcw :fabric:runServer"
    print "  ./mcw :neoforge:runServer"
  }
  print "  # enter nix develop and use ./gradlew if java is already managed"
}
