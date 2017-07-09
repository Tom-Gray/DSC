#generic dsc iis config
Configuration IISConfig
{
  param ([string[]]$computerName = 'localhost')
  Node $computerName
  {
    WindowsFeature Web-AppInit { Ensure = 'Present'; Name = 'Web-AppInit' }
    WindowsFeature Web-Asp-Net45 { Ensure = 'Present'; Name = 'Web-Asp-Net45' }
    WindowsFeature Web-Http-Tracing { Ensure = 'Present'; Name = 'Web-Http-Tracing' }
    WindowsFeature Web-Mgmt-Service { Ensure = 'Present'; Name = 'Web-Mgmt-Service' }
    WindowsFeature Web-Mgmt-console { Ensure = 'Present'; Name = 'Web-Mgmt-Console' }
    WindowsFeature Web-Net-Ext { Ensure = 'Present'; Name = 'Web-Net-Ext' }
    WindowsFeature Web-Server { Ensure = 'Present'; Name = 'Web-Server' }
    WindowsFeature Web-WebSockets { Ensure = 'Present'; Name = 'Web-WebSockets' }
    WindowsFeature Web-Mgmt-Compat { Ensure = 'Present'; Name = 'Web-Mgmt-Compat' }
  }
}

IISConfig -ComputerName "localhost" -OutputPath "C:\build\" 

Start-DscConfiguration "C:\build" -wait -Verbose