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
            ClientDirectory = "C:\websites\dev\service\WMU";
        }
        NSBM = @{ 
            ClientName      = "NSBM"; 
            ClientDirectory = "C:\websites\dev\service\NSBM"; 
        }
    }
}

configuration PEPiAppServer {
    param(
        $environment = "dev",
        $computername,
        $siteLocation = "C:\websites\"


    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -Module cChoco 
    Import-DscResource -module xWebadministration
    
    

    Node  $computerName { #$AllNodes.Where( { $_.Role -eq 'WebServer' }).NodeName {
    
        $ConfigurationData.Clients.GetEnumerator() | ForEach {
        
            $clientDirectory = $_.Value.ClientDirectory
            
            File $clientDirectory.Replace(':\', '_').Replace('\', '_') {
                DestinationPath = "$clientDirectory-$environment";
                Ensure          = 'Present';
                Type            = 'Directory';
                DependsOn       = "[WindowsFeature]Web-Asp-Net45"
            }
        }

            

            WindowsFeature Web-Asp-Net45         { Ensure = 'Present'; Name = 'Web-Asp-Net45' }
            WindowsFeature Web-Mgmt-Service      { Ensure = 'Present'; Name = 'Web-Mgmt-Service' }
            WindowsFeature Web-Mgmt-console      { Ensure = 'Present'; Name = 'Web-Mgmt-Console' }
            WindowsFeature Web-Net-Ext           { Ensure = 'Present'; Name = 'Web-Net-Ext' }
            WindowsFeature Web-Server            { Ensure = 'Present'; Name = 'Web-Server' }
            WindowsFeature  Web-Dir-Browsing     { Ensure = 'Present'; Name = 'Web-Dir-Browsing' }
            WindowsFeature Web-Http-Errors       { Ensure = 'Present'; Name = 'Web-Http-Errors' }
            WindowsFeature Web-Static-Content    { Ensure = 'Present'; Name = 'Web-Static-Content' }
            WindowsFeature  Web-Http-Redirect    { Ensure = 'Present'; Name = 'Web-Http-Redirect' }
            
 

            
            xWebsite RemoveDefaultSite
        {
            Ensure          = "Present"
            Name            = "Default Web Site"
            State           = "Stopped"
            PhysicalPath    = "C:\inetpub\wwwroot"
            DependsOn       = "[WindowsFeature]Web-Server"
        }

 
            $ConfigurationData.Clients.GetEnumerator() | ForEach {
        
            $clientName = $_.Value.ClientName
            
            xWebAppPool $clientName {
            
                Name                           = "$clientName-$environment"
                Ensure                         = 'Present'
                State                          = 'Started'
                autoStart                      = $true
                managedPipelineMode            = 'Classic' 
                dependsOn                      = "[WindowsFeature]Web-Asp-Net45"               
            } #xWebAppPool

            xWebAppPool "$clientName-WS" {
            
                Name                           = "$clientName-$environment-WS"
                Ensure                         = 'Present'
                State                          = 'Started'
                autoStart                      = $true
                managedPipelineMode            = 'integrated' 
                dependsOn                      = "[WindowsFeature]Web-Asp-Net45"               
            } #xWebAppPool-WS
            } #webappPool Foreach

             xWebsite EnvironmentWebsite
        {
            Ensure          = 'Present'
            Name            = ($environment).toupper()
            State           = 'Started'
            PhysicalPath    = "C:\inetpub\wwwroot\"
            DependsOn       = '[WindowsFeature]Web-Asp-Net45'
        }
            

        $ConfigurationData.Clients.GetEnumerator() | ForEach {
        
            $clientName = $_.Value.ClientName

            xWebApplication $clientName
            {
                Website = $environment
                Ensure = 'Present'
                Name = $clientName
                PhysicalPath = "C:\websites\$environment"
                WebAppPool = "$clientName-$environment"
                ApplicationType = 'ApplicationType'
                AuthenticationInfo = `
                MSFT_xWebApplicationAuthenticationInformation
                {
                    Anonymous = $true
                    Basic     = $false
                    Digest    = $false
                    Windows   = $false
                }
                PreloadEnabled = $true
                ServiceAutoStartEnabled = $true
                ServiceAutoStartProvider = 'ServiceAutoStartProvider'
                EnabledProtocols = @('http','net.tcp')
            }
        }#WebApp foreeach


            File ExampleSiteFile
            {
                DestinationPath    = "C:\websites\$environment\servervariables.aspx"
                Contents = '<%
                            For Each var as String in Request.ServerVariables
                            Response.Write(var & " " & Request(var) & "<br>")
                            Next
                            %>'
                Ensure      =   "Present"
                dependson   =   "[xWebApplication]$clientname"     
                Force       =      $True                       
            }
            
            

                

                cChocoInstaller installChoco #ensure choco is intalled
                {
                    InstallDir = "c:\choco"
                }
                cChocoPackageInstaller installChrome #this is here as an obvious flag that choco is working.
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

PEPiAppServer -ConfigurationData $configData  -environment "dev" -computername 'localhost'