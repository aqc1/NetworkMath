#Script to get information about a particular PC

#Flag to make sure system is a Windows OS
[Bool] $isWindows = $true

#Attempt to use the Get-ComputerInfo Command
Try{
    
    #Information about entire system
    $System = Get-ComputerInfo
    
    #Windows Information
    $WinProdName = $System.WindowsProductName
    $WinSysRoot = $System.WindowsSystemRoot

    #OS Information
    $OsName = $System.OsName
    $OsServicePackMajor = $System.OsServicePackMajorVersion
    $OsServicePackMinor = $System.OsServicePackMinorVersion
    $OsLang = $System.OsLanguage
    $OsArch = $System.OsArchitecture

    #Account Information
    $OsNumUsers = $System.OsNumberOfUsers
    $OsRegisteredUser = $System.OsRegisteredUser
    $KeyboardLayout = $System.KeyboardLayout
    $Timezone = $System.Timezone

    #Output Results
    Write-Host("Windows Information Information")
    Write-Host("`t[+] Windows Product Name: " + $WinProdName)
    Write-Host("`t[+] Windows System Root: " + $WinSysRoot)

    Write-Host("`nOperating System Information")
    Write-Host("`t[+] Operating System Name: " + $OsName)
    Write-Host("`t[+] Operating System Service Pack: ")
    Write-Host("`t`t[*] Major Pack: " + $OsServicePackMajor)
    Write-Host("`t`t[*] Minor Pack: " + $OsServicePackMinor)
    Write-Host("`t[+] Operating System Language: " + $OsLang)
    Write-Host("`t[+] Operating System Architecture: " + $OsArch)

    Write-Host("`nAccount Information")
    Write-Host("`t[+] Number of Users: " + $OsNumUsers)
    Write-Host("`t[+] Operating System Registered User: " + $OsRegisteredUser)
    Write-Host("`t[+] Keyboard Layout: " + $KeyboardLayout)
    Write-Host("`t[+] Timezone: " + $Timezone)
}

#Get-ComputerInfo Command Not Available
Catch{
    #Possible Errors
    Write-Host("Possible Errors:")
    Write-Host("`t[-] PowerShell Version too old for `'Get-ComputerInfo Command`'")
    Write-Host("`t[-] System is not running a version of the Windows Operating System")
    
    #Test if system has an old version on PowerShell, or is not a Windows OS
    try{
 
        #Old Version of PowerShell, Using CimInstance Instead
        Write-Host("`t`t[*] PowerShell Version: " + $(($PSVersionTable).PSVersion))
        
        #Information about the Operating System
        $AltOs = Get-CimInstance -ClassName Win32_OperatingSystem
        $Caption = $AltOs.Caption
        $AltOsArch = $AltOs.OSArchitecture
        $RegisteredUser = $AltOs.RegisteredUser
        $SysDir = $AltOs.SystemDirectory
        $WinDir = $AltOs.WindowsDirectory

        #Output Results
        Write-Host("`nOperating System Information")
        Write-Host("`t[+] Operating System: " + $Caption)
        Write-Host("`t[+] Operating System Architecture: " + $AltOsArch)
        Write-Host("`t[+] Windows Directory: " + $WinDir)
        Write-Host("`t[+] System32 Directory: " + $SysDir)
        Write-Host("`t[+] Registered USer: " + $RegisteredUser)

    }
    catch{

        #Not a Windows OS
        Write-Host("`t`t[*] System is likely not running a version of Windows")
        $isWindows = $false
    }
}

#Get Other Information with CimInstance
Finally{
    If($isWindows){
        
        #Information that Must be Obtained via CimInstance
        $Bios = Get-CimInstance -ClassName Win32_BIOS
        $UserAccount = Get-CimInstance -ClassName Win32_UserAccount

        #BIOS and SMBIOS Information
        $MachineManufacturer = $Bios.Manufacturer
        $BiosMajor = $Bios.SystemBiosMajorVersion
        $BiosMinor = $Bios.SystemBiosMinorVersion
        $SmbiosPresent = $Bios.SMBIOSPresent
        If($SmbiosPresent){
            $SmbiosVersion = $Bios.SMBIOSBIOSVersion
        }

        #Output Results
        Write-Host("`nBIOS Information")
        Write-Host("`t[+] Machine Manufacturer: " + $MachineManufacturer)
        Write-Host("`t[+] BIOS Version: ")
        Write-Host("`t`t[*] Major Version: " + $BiosMajor)
        Write-Host("`t`t[*] Minor Version: " + $BiosMinor)
        Write-Host("`t[+] SMBIOS Present: " + $SmbiosPresent)
        If($SmbiosPresent){
            Write-Host("`t`t[*] SMBIOS Version: " + $SmbiosVersion)
        }

        Write-Host("`nUser Accounts")
        Write-Host("`t[+] Accounts: ")
        $UserAccount | ForEach-Object{
            Write-Host("`t`t[*] " + $_.Name)
        }
    }
}