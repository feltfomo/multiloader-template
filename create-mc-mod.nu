#!/usr/bin/env nu

# downloads one pinned template release and runs its full generator

const release_ref = "v1.2.0"

def fail [message: string, code: int = 1] {
  print --stderr $"error: ($message)"
  exit $code
}

def main [...args: string] {
  let selected_ref = ($env.MULTILOADER_TEMPLATE_REF? | default $release_ref)
  let temp = (^mktemp -d | str trim)
  let archive = ($temp | path join "template.tar.gz")
  let url = $"https://github.com/feltfomo/multiloader-template/archive/refs/tags/($selected_ref).tar.gz"
  let download_url = if $selected_ref == "main" {
    "https://github.com/feltfomo/multiloader-template/archive/refs/heads/main.tar.gz"
  } else {
    $url
  }

  let result = (try {
    ^curl --fail --location --silent --show-error --output $archive $download_url
    ^tar -xzf $archive -C $temp
    let sources = (ls $temp | where type == dir | get name)
    if ($sources | is-empty) { fail "downloaded archive has no template root" }
    let source = ($sources | first)
    nu ($source | path join "new-mc-mod.nu") ...$args
    { ok: true, message: "" }
  } catch {|error|
    { ok: false, message: ($error.msg? | default "generator failed") }
  })

  rm -rf $temp
  if not $result.ok { fail $result.message }
}