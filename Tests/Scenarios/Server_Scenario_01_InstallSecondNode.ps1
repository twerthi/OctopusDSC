$pass = ConvertTo-SecureString "SuperS3cretPassw0rd!" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("OctoAdmin", $pass)

Push-Location "$env:programfiles\Octopus Deploy\Octopus"
$MasterKey = .\octopus.server.exe show-master-key --instance=OctopusServer
Pop-Location
$SecureMasterKey = ConvertTo-SecureString $MasterKey -AsPlainText -Force
$MasterKeyCred = New-Object System.Management.Automation.PSCredential  ("notused", $SecureMasterKey)

Configuration Server_Scenario_01_InstallSecondNode
{
    Import-DscResource -ModuleName OctopusDSC
    
    Node "localhost"
    {
        LocalConfigurationManager
        {
            DebugMode = "ForceModuleImport"
            ConfigurationMode = 'ApplyOnly'
        }

        cOctopusServer OctopusServer
        {
            Ensure = "Present"
            State = "Started"

            Name = "HANode"

            # The url that Octopus will listen on
            WebListenPrefix = "http://localhost:81"

            SqlDbConnectionString = "Server=(local)\SQLEXPRESS;Database=Octopus;Trusted_Connection=True;"

            OctopusMasterKey = $MasterKeyCred

            # The admin user to create
            OctopusAdminCredential = $cred

            # dont mess with stats
            AllowCollectionOfAnonymousUsageStatistics = $false

            HomeDirectory = "C:\ChezOctopusSecondNode"
        }
    }
}