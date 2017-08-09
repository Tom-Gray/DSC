$configData = @{
    AllNodes = @(
        @{
            NodeName = 'WEB-PROD';
            Role     = 'WebServer';
            siteDirectory = "C:\websites\prod\"
        }
        @{
            NodeName = 'DB-PROD';
            Role     = 'DBServer';
        }
        @{
            NodeName = 'DEV';
            Role     = 'DBServer','WebServer';
            siteDirectory = "C:\websites\dev\"
        }
    )

    Clients  = @{
        WMU  = @{ 
            ClientName      = "WMU";
            ClientDirectory = "C:\website\dev\service\WMU";
        }
        NSBM = @{ 
            ClientName      = "NSBM"; 
            ClientDirectory = "C:\website\dev\service\NSBM"; 
        }
    }
}

configuration PEPiAppServer {
    param(

    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -Module cChoco 
    Import-DscResource -module xWebadministration
    
    node $AllNodes.NodeName {
    
        LocalConfigurationManager
            {
            DebugMode = 'ForceModuleImport'
            } 
    }

    node $AllNodes.Where( { $_.Role -eq 'WebServer' }).NodeName {
    
        $ConfigurationData.Clients.GetEnumerator() | ForEach {
        
            $clientDirectory = $_.Value.ClientDirectory
            
            File $clientDirectory.Replace(':\', '_').Replace('\', '_') {
                DestinationPath = $clientDirectory;
                Ensure          = 'Present'
                Type            = 'Directory';
            }
        }

            
            WindowsFeature Web-AppInit      { Ensure = 'Present'; Name = 'Web-AppInit' }
            WindowsFeature Web-Asp-Net45    { Ensure = 'Present'; Name = 'Web-Asp-Net45' }
            WindowsFeature Web-Http-Tracing { Ensure = 'Present'; Name = 'Web-Http-Tracing' }
            WindowsFeature Web-Mgmt-Service { Ensure = 'Present'; Name = 'Web-Mgmt-Service' }
            WindowsFeature Web-Mgmt-console { Ensure = 'Present'; Name = 'Web-Mgmt-Console' }
            WindowsFeature Web-Net-Ext      { Ensure = 'Present'; Name = 'Web-Net-Ext' }
            WindowsFeature Web-Server       { Ensure = 'Present'; Name = 'Web-Server' }
            WindowsFeature Web-WebSockets   { Ensure = 'Present'; Name = 'Web-WebSockets' }
            WindowsFeature Web-Mgmt-Compat  { Ensure = 'Present'; Name = 'Web-Mgmt-Compat' }
 
            $ConfigurationData.Clients.GetEnumerator() | ForEach {
        
            $clientName = $_.Value.ClientName
            
            xWebAppPool $clientName.Replace(':\', '_').Replace('\', '_') {
            
                Name                           = $clientName
                Ensure                         = 'Present'
                State                          = 'Started'
                autoStart                      = $true
                enable32BitAppOnWin64          = $false
                enableConfigurationOverride    = $true
                managedPipelineMode            = 'Classic' 
                dependsOn                      = "[WindowsFeature]Web-Asp-Net45"               
            }
            }
            
            
            

                

                cChocoInstaller installChoco #ensure choco is intalled
                {
                    InstallDir = "c:\choco"
                }
                cChocoPackageInstaller installChrome
                {
                    Name        = "googlechrome"
                    DependsOn   = "[cChocoInstaller]installChoco"
                    #This will automatically try to upgrade if available, only if a version is not explicitly specified. 
                    AutoUpgrade = $True
                }
                cChocoPackageInstaller SQLSMObjects
                {
                    Name = "sql2014.smo"
                    DependsOn = "[cChocoInstaller]installChoco"
                }

                    cChocoPackageInstaller ReportViewer
                {
                    Name = "reportviewer2010sp1"
                    DependsOn = "[cChocoInstaller]installChoco"
                }
    


        
        

    } #end Role Webserver
    
    node $allnodes.Where( { $_.Role -eq 'DBServer' }).NodeName {
        File ScratchDirectory {
            DestinationPath = "C:\Build";
            Ensure          = 'Present';
            Type            = 'Directory';
        }
    } #end role dbserver

} #end configuration

PEPiAppServer -ConfigurationData $configData  