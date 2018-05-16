class Node {
    [int]$x = 0
    [int]$y = 0
    $weight = @() 

    Node($x, $y, $weight) {
        $this.x = $x
        $this.y = $y
        $this.weight = $weight
    }

    [int] getX() {
        return $this.x
    }

    [int] getY() {
        return $this.y
    }

    setWeight($weight) {
        $this.weight = $weight
    }

    [Object] getWeight() {
        return $this.weight
    }

    [float] getDistance($vector) {
        [float]$distance = 0
        for($i = 0; $i -lt $this.weight.Count; $i++) {
            $distance += ($vector[$i] - $this.weight[$i]) * ($vector[$i] - $this.weight[$i])
        }
        return [math]::Sqrt($distance)
    }

    [float] getNodeDistance($node) {
        [float]$distance = 0
        for($i = 0; $i -lt $this.weight.Count; $i++) {
            $distance += ($node.weight[$i] - $this.weight[$i]) * ($node.weight[$i] - $this.weight[$i])
        }
        return [math]::Sqrt($distance)
    }
}

class Map {
    $map = ,@()
    $x
    $y

    Map($x = 10, $y = 10) {
        $this.x = $x
        $this.y = $y

        $this.map = New-Object 'object[,]' $x, $y

        # Initialize map
        for($i=0; $i -lt $x; $i++) {
            $row = @()
            for($j=0; $j -lt $y; $j++) {
                #$row += [Node]::new($i, $j, 0.001)
                $this.map[$i, $j] = [Node]::new($i, $j, 0.001)
            } 
        }
        #Write-Host $this.map 
    }
    
    

    initializeWeights($num) {
        for($i = 0; $i -lt $this.x; $i++) {
            for($j = 0; $j -lt $this.y; $j++) {
                # Write-Host $this.map[$i, $j]
                $this.map[$i, $j].setWeight($this.getRandomWeightVector($num))
            }
        }
    }

    [Object] getRandomWeightVector($num) {
        $arr = @()
        for($i = 0; $i -lt $num; $i++) {
             $arr += Get-Random -Minimum 0.0 -Maximum 1.0
        }
        return $arr
    }

    findBMU($vector) {
        # Calculate shortest distance to input vector
        $bmu = $this.map[0, 0]
        $minDist = $null

        foreach($node in $this.map) {
            
            $distance = $node.getDistance($vector)

             

            if ($minDist -eq $null) {
                $minDist = $distance
                $bmu = $node
            } elseif ($distance -lt $minDist) {
                # Current shortest distance
                $minDist = $distance
                $bmu = $node
            }
            
            Write-Host "Dist:" $distance "    Bmu:" $bmu.getX() $bmu.getY()
        }
        Write-Host $bmu.getX() $bmu.getY()
    }

    [float] calculateRadius($i, $numIter) {
        $r = ($this.x, $this.y | Measure -Max).Maximum/2
        $lambda = $numIter/[Math]::Log($r)
        return $r*[Math]::Exp(-$i/$lambda)
    }

    [float] calculateLearningRate($i, $numIter, $rate) {
        $lambda = $numIter/[Math]::Log($rate)
        return $rate*[Math]::Exp(-$i/$lambda)
    }
    
    # Updates the nodes within the radius of a given node
    updateNeighbourhood($iv, $bmu, $radius, $learningRate) {
        # Calculate neighbourhood
        foreach($n in $this.map) {
            # Check if the node is in the neighbourhood
            if ($bmu.getNodeDistance($n) -le $radius) {
                # Update weight
                $w = $n.getWeight() + $learningRate*(
            }
        }
    } 

    printMap() {
        <#foreach($node in $this.map) {
            Write-Host "X:" $node.getX() "    Y:" $node.getY() "    W:" $node.getWeight()
        }#>

        for($i = 0; $i -lt $this.x; $i++) {
            Write-Host "i: $i"
            for($j = 0; $j -lt $this.y; $j++) {
                Write-Host "j: $j"
                Write-Host "X:" $this.map[$i, $j].getX()"    Y:" $this.map[$i, $j].getY()"    W:" $this.map[$i, $j].getWeight()
            }
        }
    }
}

class PowerSOM {
    $x
    $y
    $len
    $sigma = 1.0
    $learnRate = 0.5
    $map

    # Constructor
    PowerSOM($x, $y, $len, $sigma=1.0, $learnRate=0.5) {
        $this.x = $x
        $this.y = $y
        $this.len = $len
        $this.sigma = $sigma
        $this.learnRate = $learnRate

        $this.map = [Map]::new($x, $y)
    }

    activate($x) {
        
    }

    train($data, $numIter) {
        $this.map.initializeWeights($data[0].Count)
        $this.map.printMap()

        # Select random vector
        $inVect = $data[$this.getRandomNum(0..($data.Count-1), $null)]
        Write-Host $inVect

        $bmu = $this.map.findBMU($inVect)
        $radius = $this.map.calculateRadius(0, $numIter)
        $this.map.updateNeighbourhood($bmu, $radius)

        <# Testing decay function
        for($i = 0; $i -lt 20; $i++) {
            Write-Host $this.map.calculateRadius($i, 5)
        }#>



        # Capture vector
    }

    [int] getRandomNum($range, $exclude) {
        $RandomRange = $range | Where-Object { $exclude -notcontains $_ }

        return Get-Random -InputObject $RandomRange
    }
}

$data = ((1, 2, 3, 4), 
        (5, 6, 7, 8),
        (9, 10, 11, 12),
        (13, 14, 15, 16))
 
Write-Host $data.Count

$som = [PowerSOM]::new(4, 4, 10, 1.0, 0.5)
$som.train($data)