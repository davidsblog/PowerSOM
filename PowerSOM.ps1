class Node {
    [int] $private:x = 0
    [int] $private:y = 0
    $private:weight = @() 
    $private:vectors = @()

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

    [float] getPhysicalDistance($node) {
        $dX = ($this.x-$node.x)
        $dY = ($this.y-$node.y)

        return [math]::Sqrt($dX*$dX + $dY*$dY)
    }

    addVector($vector) {
        $this.vectors += ,@($vector)
    }

    [Object] getVectors() {
        return $this.vectors
    }
}

class PowerSOM {
    $private:map = ,@()
    $private:magnitudes = @()
    $private:x = 10
    $private:y = 10
    $private:width = 10
    $private:sigma = 1.0
    $private:learnRate = 0.5

    # Constructors
    PowerSOM($x, $y, $sigma=1.0, $learnRate=0.5) {
        $this.x = $x
        $this.y = $y
        $this.width = ($x, $y | Measure -Max).Maximum/2
        $this.sigma = $sigma
        $this.learnRate = $learnRate
        
        # Initialize map
        $this.map = New-Object 'object[,]' $x, $y
        for($i=0; $i -lt $x; $i++) {
            for($j=0; $j -lt $y; $j++) {
                $this.map[$i, $j] = [Node]::new($i, $j, 0.001)
            } 
        }
    }
    PowerSOM($som) {
        $this.x = $som.x
        $this.y = $som.y
        $this.width = ($this.x, $this.y | Measure -Max).Maximum/2
        $this.sigma = $som.sigma
        $this.learnRate = $som.learnRate
       
        # Initialize map
        $this.map = New-Object 'object[,]' $this.x, $this.y
        for($i=0; $i -lt $this.x; $i++) {
            for($j=0; $j -lt $this.y; $j++) {
                $node = $som.map[$i, $j]
                $this.map[$i, $j] = [Node]::new($i, $j, $node.weight)
            } 
        }

        Write-Host $this.printMap()
    }
    
    initializeWeights($num) {
        for($i = 0; $i -lt $this.x; $i++) {
            for($j = 0; $j -lt $this.y; $j++) {
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

    [Node] findBMU($vector) {
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
        }
        return $bmu
    }

    [float] decayRadius($i, $numIter) {     
        $lambda = $numIter/[Math]::Log($this.width)
        return $this.width*[Math]::Exp(-$i/$lambda)
    }

    [float] decayLearningRate($i, $numIter, $rate) {
        return $rate*[Math]::Exp(-$i/$numIter)
    }

    [float] calculateInfluence($dist) {
        return [Math]::Exp(-($dist*$dist)/(2*$this.width*$this.width))
    }
    
    # Updates the nodes within the radius of a given node
    updateNeighbourhood($iv, $bmu, $radius, $learningRate) {
        
        # Calculate neighbourhood
        foreach($n in $this.map) {
            $w = @()
            $dist = $bmu.getPhysicalDistance($n)
            if ($dist -le $radius) { 
                # Calculate new weight: w' = w + o*l*(v-w)
                $a = $this.calculateInfluence($dist) * $learningRate
                for($i = 0; $i -lt $iv.Count; $i++) {
                    $w += $bmu.weight[$i] + $a*($iv[$i] - $bmu.weight[$i])
                }
                $n.setWeight($w)
            }
        }
    } 

    addVector($node, $vector) {
        $this.map[$node.x, $node.y].addVector($vector)
    }

    [Object] getMap() {
        return $this.map
    }

    ## Public Methods ##

    train($data, $epochs) {
        $this.initializeWeights($data[0].Count)
        Write-Host $data[0].Count

        for($i = 0; $i -lt $epochs; $i++) {
            # Select random input vector
            $inVect = $data[$this.getRandomNum(0..($data.Count-1), $null)]

            # Find winning node
            $bmu = $this.findBMU($inVect)

            # Decay Radius and Learning rate
            $radius = $this.decayRadius(0, $epochs)
            $this.learnRate = $this.decayLearningRate(0, 20, $this.learnRate)

            # Update winning node's neighbours
            $this.updateNeighbourhood($inVect, $bmu, $radius, $this.learnRate)
        }
    }

    [Object] mapData($data, $denormalize) {
        # Map data vectors to their winning node
        for($i = 0; $i -lt $data.Count; $i++) {
            $winner = $this.findBMU($data[$i])

            if ($denormalize) {
                $data[$i] = $this.denormalizeVector($data[$i], $this.magnitudes[$i])
            }
            $this.addVector($winner, $data[$i])
        }
        return $this.getMap()
    }

    [Object] getDistanceMap() {
        $distMap = New-Object 'object[,]' $this.x, $this.y
        $nodeMap = $this.getMap()
        $distance = 0

        # Calculate node distance
        for($i = 0; $i -lt $this.x; $i++) {
            for($j = 0; $j -lt $this.y; $j++) {       
                if($nodeMap[($i-1), $j].weight -ne $null) {
                    $t = $nodeMap[($i-1), $j]
                    $d = $nodeMap[$i, $j].getNodeDistance($t)
                    $distance += [Math]::Pow($d, 2)
                } 
                if($distMap[($i+1), $j].weight -ne $null) {
                    $t = $nodeMap[($i+1), $j]
                    $d = $nodeMap[$i, $j].getNodeDistance($t)
                    $distance += [Math]::Pow($d, 2)
                } 
                if($nodeMap[$i, ($j-1)].weight -ne $null) {
                    $t = $nodeMap[$i, ($j-1)]
                    $d = $nodeMap[$i, $j].getNodeDistance($t)
                    $distance += [Math]::Pow($d, 2)
                } 
                if($nodeMap[$i, ($j+1)].weight -ne $null) {
                    $t = $nodeMap[$i, ($j+1)]
                    $d = $nodeMap[$i, $j].getNodeDistance($t)
                    $distance += [Math]::Pow($d, 2)
                } 
                $distMap[$i, $j] = [Math]::Sqrt($distance)
            }
            $distance = 0
        }

        # Range distance
        $max = ($distMap | Measure -Max).Maximum
        for($i = 0; $i -lt $this.x; $i++) {
            for($j = 0; $j -lt $this.y; $j++) {     
                $distMap[$i, $j] /= $max
            }
        }
        return $distMap
    }

    [Object] getOutliers($signal, $distMap) {
        # Find nodes with distance greater than signal
        $outliers = @()
        for($i = 0; $i -lt $this.x; $i++) {
            for($j = 0; $j -lt $this.y; $j++) {
                if((($distMap[$i, $j]) -ge $signal) -and ($this.map[$i, $j].getVectors().count -gt 1)) {
                    $outliers += ,($this.map[$i, $j].getVectors())
                }
            }
        }
        return $outliers
    }

    [Object] normalizeData($data) {
        for($i = 0; $i -lt $data.Count; $i++) {
            [double] $magnitude = 0

            # Calculate vector magnitude
            for($j = 0; $j -lt $data[$i].Count; $j++) {
                $magnitude += [Math]::Pow($data[$i][$j], 2)
            }
            $this.magnitudes += [Math]::Sqrt($magnitude)

            # Calculate unit vector
            for($j = 0; $j -lt $data[$i].Count; $j++) {
                $data[$i][$j] = $data[$i][$j]/$this.magnitudes[$i]
            }
        }
        return $data
    }

    [Object] denormalizeVector($vector, $magnitude) {
        for($i = 0; $i -lt $vector.count; $i++) {
            $vector[$i] *= $magnitude
        }
        return $vector
    }

    [Object] denormalizeData($data) {
        for($i = 0; $i -lt $data.Count; $i++) {
            for($j = 0; $j -lt $data.Count; $j++) {
                $data[$i][$j] *= $this.magnitudes[$i]
            }
        }
        return $data
    }

    [int] getRandomNum($range, $exclude) {
        return Get-Random -InputObject $range | Where-Object { $exclude -notcontains $_ }
    }

    printMap() {
        for($i = 0; $i -lt $this.x; $i++) {
            for($j = 0; $j -lt $this.y; $j++) {
                Write-Host "X:" $this.map[$i, $j].getX()"    Y:" $this.map[$i, $j].getY()"       w:" $this.map[$i, $j].getWeight()"       V:" $this.map[$i, $j].getVectors()
            }
        }
    }
}
