param(
  [Parameter(Mandatory = $true)]
  [string]$Renderer,
  [string]$Ffmpeg = 'ffmpeg'
)

$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$midi = Join-Path $projectRoot 'assets\audio\only_retro_2.mid'
$wav = "$midi.wav"
$ogg = Join-Path $projectRoot 'assets\audio\only_retro_2.ogg'

if (-not (Test-Path -LiteralPath $midi)) {
  throw "Missing MIDI source: $midi"
}

# The wave-only libADLMIDI player writes <input.mid>.wav beside the MIDI file.
& $Renderer $midi --emu-nuked --gain 1 0 2
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $wav)) {
  throw 'libADLMIDI did not render the MIDI source.'
}

& $Ffmpeg -hide_banner -loglevel error -y -i $wav -c:a libvorbis -q:a 5 $ogg
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $ogg)) {
  throw 'FFmpeg did not create the OGG music asset.'
}

Remove-Item -LiteralPath $wav
Write-Output "Updated $ogg"
