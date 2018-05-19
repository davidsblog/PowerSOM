Import-Module "..\PowerSOM.ps1"

# Import dataset
$dataset = (Get-Content "Credit_Card_Applications.csv")
$size = $dataset.Count-1
$header = $dataset[0].split(",")
$dataset = $dataset[1..($dataset.Count-1)].split(",")

# Format data into arrays
$data = ,@()
$count = 0
for($i = 0; $i -lt $size; $i++) {
    $row = @()
    for($j = 0; $j -lt $header.Count; $j++) {
        $row += $dataset[$count++]
    }
    if ($i -eq 0) {
        $data = ,@($row)
    } else {
        $data += ,@($row)
    }
}

# Create 10x10 Map 
$som = [PowerSOM]::new(10, 10, 1.0, 0.5)

# Normalize data to match weights
$data = $som.normalizeData($data)

# Train
$som.train($data, 100)
Write-Host "Done Training"

# Map data
$map = $som.mapData($data, $true)
$distMap = $som.getDistanceMap()
Write-Host "Done Mapping"

# Find outlier nodes
Write-Host "Searching for outliers"
$outliers = $som.getOutliers(0.8, $distMap)

# Write outlier vectors to csv
$a = New-Object System.Collections.ArrayList($null)
foreach($node in $outliers) {
    foreach($vector in $node) {
        [Void] $a.Add([system.String]::Join(",", $vector))   
    }
}
if ($a.Length -gt 0) {
    ConvertFrom-Csv $a -Header $header|Export-Csv fraud.csv -NoType -Delimiter ","
    Write-Host "Writing outliers to fraud.csv"
} else {
    Write-Host "No outliers found."
}