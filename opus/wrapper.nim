import nimterop/[build, cimport]
 
## Low-level C-wrapper for opus av1 decoder
## generated with nimterop
##
## Everything is imported, "opus_" prefix is removed

# fetch and build configuration
setDefines(@["opusGit", "opusSetVer=e85ed772", "opusStatic"])

static:
  cDebug()

const
  baseDir = getProjectCacheDir("opus")

getHeader(
  "opus.h",
  giturl = "https://gitlab.xiph.org/xiph/opus.git",
  outdir = baseDir,
)

when defined(windows):
  {.passL: "-fstack-protector"}

cPlugin:
  import strutils

  # Strip prefix from procs
  proc onSymbol*(sym: var Symbol) {.exportc, dynlib.} =
    if sym.name.startsWith("OPUS_"):
      sym.name = sym.name.substr(5)
    if sym.name.startsWith("opus_"):
      sym.name = sym.name.substr(5)
    if sym.name.startsWith("Opus"):
      sym.name = sym.name.substr(4)
      # remove prefixes for brevity

  #[
    if sym.name in ["Decoder"]:
      sym.name &= "Obj"
      # Add "Obj" postfix to objects to be used by a traced
      # reference to have a finalizer
  ]# 
    if sym.name in ["Decoder"]:
      sym.name = "c" & sym.name
      # Add "c" prefix to objects to avoid naming conflicts with
      # wrapping objects

# import symbols
cImport opusPath, recurse=true

