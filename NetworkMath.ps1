# Function to Find NetworkID When Given an IPv4 Subnet
Function findNetworkID{
    Param(
        [String] $IPv4
    )
    
    # Split the IPv4 Address and the Subnet Mask
    [String[]] $octetStrings = $IPv4.Split("/")[0].Split(".")
    [Int] $subnetMaskCidr = [Convert]::ToInt32($IPv4.Split("/")[1])

    # Turn Subnet Mask into a Byte String
    [String] $subnetString = ''
    For([Int]$i = 0; $i -lt $subnetMaskCidr; $i = $i + 1){
        $subnetString = $subnetString + '1'
    }
    For([Int]$i = $subnetMaskCidr; $i -lt 32; $i = $i + 1){
        $subnetString = $subnetString + '0'
    }

    # Split IP Address Into Binary Octets
    [String[]] $octets = $octetStrings | ForEach-Object {[Convert]::ToString($_, 2).PadLeft(8, '0')}
    
    # Split Subnet String into Octet Sized Substrings                            
    [String[]] $subnet = @($subnetString.Substring(0,8).PadLeft(8,'0'),
                           $subnetString.Substring(8,8).PadLeft(8,'0'),
                           $subnetString.Substring(16,8).PadLeft(8,'0'),
                           $subnetString.Substring(24).PadLeft(8,'0')) 
                                 
    # Create the NetworkID One Octet at a Time
    # NetworkID = IP -and Subnet Mask
    [String[]] $networkIdOctets = @()
    For([Int]$i = 0; $i -lt 4; $i++){
        $networkIdOctets += [Convert]::ToInt32([Convert]::ToString([Convert]::ToInt32($octets[$i],2) -bAnd [Convert]::ToInt32($subnet[$i],2),2), 2).ToString()
    }
    
    # Join the NetworkID Octets and Return
    [String] $networkID = $networkIdOctets -join "`."
    return $networkID
}


# Function to Find First Usable Address When Given the NetworkID
function findFirstUsable{
    Param(
        [String] $networkID
    )
    
    # Split NetworkID into Octets
    [String[]] $octets = $networkID.Split("`.")

    # Iterate the Last Octet by One
    [Int] $lastOctet = [Convert]::ToInt32($octets[3],10) + 1

    # Join First Three Octets and the New Octet and Return
    [String] $firstUsable = $octets[0] + "`." + $octets[1] + "`." + $octets[2] + "`." + "$lastOctet"
    return $firstUsable
}


# Function to Find the Wildcard Given the IPv4 Subnet
function findWildcard{
    Param(
        [String] $IPv4
    )

    # Split the Subnet Mask from the IPv4 Subnet and Calculate Wildcard
    [Int] $subnetMask = ($IPv4.Split("`.")[3]).Split("/")[1]
    [Int] $wildcardNumber = 32 - $subnetMask

    # Turn Wildcard into a Byte String
    # Done by Creating the Subnet Mask Byte String, Then Reversing the Octets
    [String] $wildcardString = ""
    For([Int]$i = 0; $i -lt $wildcardNumber; $i = $i + 1){
        $wildcardString = $wildcardString + '1'
    }
    For([Int]$i = $wildcardNumber; $i -lt 32; $i = $i + 1){
        $wildcardString = $wildcardString + '0'
    }
    $temp = $wildcardString.ToCharArray()
    [Array]::Reverse($temp)
    $wildcardString = -join($temp)

    # Split the Byte String into Octet Substrings
    [String[]] $wildcardOctets = @($wildcardString.Substring(0,8),
                                   $wildcardString.Substring(8,8),
                                   $wildcardString.Substring(16,8),
                                   $wildcardString.Substring(24))
    
    # Join the Wildcard Octets and Return
    [String] $wildcard = $wildcardOctets -join "`."
    return $wildcard                                                                               
}



# Function to Find the Broadcast Address Given the NeworkID and the Wildcard
function findBroadcast{
    Param(
        [Parameter(Position = 0)]
        [String] $networkID,
        [Parameter(Position = 1)]
        [String] $wildcard
    )
    
    # Split NetworkID and Wildcard into Octets
    [String[]] $networkIdOctets = $networkID.Split("`.")
    [String[]] $wildcardOctets = $wildcard.Split("`.")

    # Calculate Broadcast Address
    # Broadcast = NetworkID -or Wildcard
    [String[]] $broadcastOctets = @()
    for([Int]$i = 0; $i -lt 4; $i++){
        $broadcastOctets += [Convert]::ToInt32([Convert]::ToString($networkIdOctets[$i] -bOr [Convert]::ToInt32($wildcardOctets[$i],2),2), 2).ToString()
    }
  
    # Join Broadcast Octets and Return      
    [String] $broadcast = $broadcastOctets -join "`."
    return $broadcast   
}


# Function to Find Last Usable Address When Given the Broadcast
function findLastUsable{
    Param(
        [String] $broadcast
    )
    
    # Split the Boradcast into Octets
    [String[]] $octets = $broadcast.Split("`.")

    # Decrement Last Octet by One
    [Int] $lastOctet = [Convert]::ToInt32($octets[3],10) - 1

    # Join First Three Octets and the New Octets and Return
    [String] $lastUsable = $octets[0] + "`." + $octets[1] + "`." + $octets[2] + "`." + "$lastOctet"
    return $lastUsable
}

# Function to Find Number of Hosts Available When Given the CIDR Address
function getNumOfHosts{
    Param(
        [String] $IPv4
    )

    # Split Subnet Mask from IPv4 Subnet
    [Int] $subnetMask = [Convert]::ToInt32($IPv4.Split("/")[1])

    # Calculate the Number of Usable Hosts and Return
    # Number of Hosts = (2 ^ (32 - n)) - 2
    If($subnetMask -eq 31){
        return "0 [For Point-to-Point Use Only]"
    }
    If($subnetMask -eq 32){
        return "0 [Isolated]"
    }
    [Int] $hosts = ([Math]::Pow(2, (32 - $subnetMask)) - 2)
    return $hosts.ToString()
}


# Valid IPv4 Regex
[Regex] $IPRegex = "^\d{1,3}(\.\d{1,3}){3}(/\d{1,2})?$"

# Take User Input
[String] $IPv4 = Read-Host("Enter IPv4 Address in CIDR Notation (/24 by Default)")

# Sanitize Input via Regex and Iteration
If($IPv4 -NotMatch $IPRegex){
    # Not an IPv4 Address
    Write-Host("Entered IP Address Not Valid.") 
    Exit
}
Else{
    [Boolean] $hasMask = $IPv4 -Match "/"
    [String[]] $IPOctets = @()
    If($hasMask){
        $IPOctets = $IPv4.Split("/")[0].Split(".")
    }
    Else{
        $IPOctets = $IPv4.Split(".")
    }
    If([Convert]::ToInt32($IPOctets[0]) -lt 1){
        # First Octet cannot be < 1
        Write-Host("Entered IP has Invalid Octets")  
        Exit
    }
    $IPOctets | 
        ForEach-Object {
            If([Convert]::ToInt64($_) -gt 255){
                # Octets Cannot be > 255
                Write-Host("Entered IP has Invalid Octets") 
                Exit
            }
        }
    If(-not($hasMask)){
        $IPv4 += "/24"
    }
    Else{
        [Int64] $convertedMask = [Convert]::ToInt64($IPv4.Split("/")[1])
        # Subnet Mask Cannot be > 32 or < 1
        If($convertedMask -gt 32 -or $convertedMask -lt 1){  
            $temp = $IPv4.Split("/")[0]
            $IPv4 = $temp + "/24"
        }
    }
}

# Perform Calculations
[String] $networkID = findNetworkID $IPv4 
[String] $wildcard = findWildcard $IPv4
[String] $broadcast = findBroadcast $networkID $wildcard
[String] $firstUsable = findFirstUsable $networkID
[String] $lastUsable = findLastUsable $broadcast
[String] $hostNum = getNumOfHosts $IPv4

# Output Results
Write-Host("IPv4                 " + $IPv4)
Write-Host("NetworkID            " + $networkID)
Write-Host("First Usable Address " + $firstUsable)
Write-Host("Last Usable Address  " + $lastUsable)
Write-Host("Broadcast            " + $broadcast)
Write-Host("Number of Hosts      " + $hostNum)
