$json = Get-Content "c:\Users\Aiono\Desktop\KinkdomClicker\data\buildings.json" -Raw | ConvertFrom-Json
$out = "`n"
$y = -1000
foreach ($b in $json) {
  $x = -1000
  for ($i = 0; $i -lt 6; $i++) {
    $out += "[node name=`"$($b.id)_$i`" type=`"Marker2D`" parent=`"Canvas/SpawnPoints`"]`nposition = Vector2($x, $y)`n`n"
    $x += 200
  }
  $y += 200
}
Add-Content -Path "c:\Users\Aiono\Desktop\KinkdomClicker\UI\KingdomVisualizer.tscn" -Value $out -Encoding UTF8
Write-Host "Done adding markers"
