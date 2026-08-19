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
    if ($reply | is-empty) {
      $fallback
    } else {
      $reply in ["y" "yes"]
    }
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

def prune-language [language: string] {
  for module in ["common" "fabric" "neoforge"] {
    let root = ($module | path join "src")
    if ($root | path exists) {
      ^find $root -type d -name $language -prune -print0 | ^xargs -0 -r rm -rf
    }
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
  if ($mod_id | is-empty) {
    $mod_id = (ask "mod id (lowercase)" "mymod" $non_interactive)
  }

  mut mod_group = (env-string "SCAFFOLD_GROUP")
  if ($mod_group | is-empty) {
    $mod_group = (ask "group / package" $"com.example.($mod_id)" $non_interactive)
  }

  let default_name = ($mod_id | ^sed -E 's/(^|_)([a-z])/\U\2/g' | str trim)
  mut mod_name = (env-string "SCAFFOLD_NAME")
  if ($mod_name | is-empty) {
    $mod_name = (ask "display name" $default_name $non_interactive)
  }

  let mod_version = if $non_interactive {
    env-string "SCAFFOLD_VERSION" "1.0.0"
  } else {
    ask "version" (env-string "SCAFFOLD_VERSION" "1.0.0") false
  }
  let mod_authors = if $non_interactive {
    env-string "SCAFFOLD_AUTHORS" "yourname"
  } else {
    ask "authors" (env-string "SCAFFOLD_AUTHORS" "yourname") false
  }
  let mod_license = if $non_interactive {
    env-string "SCAFFOLD_LICENSE" "MIT"
  } else {
    ask "license" (env-string "SCAFFOLD_LICENSE" "MIT") false
  }
  let mod_desc = if $non_interactive {
    env-string "SCAFFOLD_DESC" "A Minecraft mod."
  } else {
    ask "description" (env-string "SCAFFOLD_DESC" "A Minecraft mod.") false
  }

  let kotlin_env = (env-string "SCAFFOLD_KOTLIN")
  let scala_env = (env-string "SCAFFOLD_SCALA")
  let datagen_env = (env-string "SCAFFOLD_DATAGEN")
  let mod_kotlin = if ($kotlin_env | is-empty) {
    ask-bool "add kotlin support" false $non_interactive
  } else {
    truthy $kotlin_env
  }
  let mod_scala = if ($scala_env | is-empty) {
    ask-bool "add scala support" false $non_interactive
  } else {
    truthy $scala_env
  }
  let mod_datagen = if ($datagen_env | is-empty) {
    ask-bool "include datagen" true $non_interactive
  } else {
    truthy $datagen_env
  }

  if not ($mod_id =~ '^[a-z][a-z0-9_]*$') {
    fail $"mod id must match ^[a-z][a-z0-9_]*$ (got ($mod_id))"
  }
  if not ($mod_group =~ '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)*$') {
    fail $"group must look like com.example.($mod_id) (got ($mod_group))"
  }

  let mod_group_path = ($mod_group | str replace -a "." "/")
  print "scaffolding"
  print $"  id       ($mod_id)"
  print $"  name     ($mod_name)"
  print $"  group    ($mod_group)"
  print $"  version  ($mod_version)"
  print $"  authors  ($mod_authors)"
  print $"  license  ($mod_license)"
  print $"  kotlin   ($mod_kotlin)"
  print $"  scala    ($mod_scala)"
  print $"  datagen  ($mod_datagen)"

  let r_name = (sed-replacement $mod_name)
  let r_authors = (sed-replacement $mod_authors)
  let r_license = (sed-replacement $mod_license)
  let r_desc = (sed-replacement $mod_desc)
  let r_version = (sed-replacement $mod_version)

  for file in (text-files) {
    if (is-text $file) {
      let sed_args = [
        "-i"
        "-e" 's|\bmodid\([[:space:]]*=\)|@@KEEP_MODID@@\1|g'
        "-e" ('s|com\.example\.modid|' + $mod_group + '|g')
        "-e" ('s|com/example/modid|' + $mod_group_path + '|g')
        "-e" ('s|\bmodid\b|' + $mod_id + '|g')
        "-e" ('s|\bModid\b|' + $r_name + '|g')
        "-e" ('s|yourname|' + $r_authors + '|g')
        "-e" 's|@@KEEP_MODID@@|modid|g'
        $file
      ]
      ^sed ...$sed_args
    }
  }

  if ("pkl/mod.pkl" | path exists) {
    let pkl_args = [
      "-i"
      "-e" ('s|^name = .*|name = "' + $r_name + '"|')
      "-e" ('s|^version = .*|version = "' + $r_version + '"|')
      "-e" ('s|^license = .*|license = "' + $r_license + '"|')
      "-e" ('s|^description = .*|description = "' + $r_desc + '"|')
      "-e" ('s|^kotlin: Boolean = .*|kotlin: Boolean = ' + ($mod_kotlin | into string) + '|')
      "-e" ('s|^scala: Boolean = .*|scala: Boolean = ' + ($mod_scala | into string) + '|')
      "-e" ('s|^datagen: Boolean = .*|datagen: Boolean = ' + ($mod_datagen | into string) + '|')
      "pkl/mod.pkl"
    ]
    ^sed ...$pkl_args
  }

  let package_dirs = (^find . -type d -path '*/com/example/modid' -print | lines)
  for package_dir in $package_dirs {
    let prefix = ($package_dir | str replace -r '/com/example/modid$' '')
    let new_dir = $"($prefix)/($mod_group_path)"
    mkdir $new_dir
    for entry in (ls -a $package_dir) {
      mv $entry.name $new_dir
    }
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
  let named_paths = (^find ...$named_args | lines)
  for path in $named_paths {
    if ($path | path exists) {
      let parent = ($path | path dirname)
      let renamed = (($path | path basename) | str replace -a "modid" $mod_id)
      mv $path ($parent | path join $renamed)
    }
  }

  if not $mod_kotlin { prune-language kotlin }
  if not $mod_scala { prune-language scala }
  if not $mod_datagen { prune-datagen }

  ^chmod +x gradlew mcw

  print "done, removing scaffold.nu"
  rm -f scaffold.nu
  print ""
  print "next"
  print "  ./mcw :fabric:runClient"
  print "  ./mcw :neoforge:runClient"
  print "  # enter nix develop and use ./gradlew if java is already managed"
}
