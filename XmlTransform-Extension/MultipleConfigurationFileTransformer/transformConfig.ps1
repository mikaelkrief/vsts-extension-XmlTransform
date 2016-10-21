[CmdletBinding(DefaultParameterSetName='None')]
param
(
    [string][Parameter(Mandatory=$true)]$webConfigRelativePath,
    [string][Parameter(Mandatory=$true)]$outPutRelativePath,
    [string][Parameter(Mandatory=$true)]$vsVersion
)


Trace-VstsEnteringInvocation $MyInvocation
try{

    . "$PSScriptRoot\Helpers.ps1"

    # These variables are provided by TFS
    $buildAgentHomeDirectory = $env:AGENT_HOMEDIRECTORY
    $buildSourcesDirectory = $Env:BUILD_SOURCESDIRECTORY
    $buildStagingDirectory = $Env:BUILD_STAGINGDIRECTORY
    $buildPlatform = $Env:BUILDPLATFORM
    $buildConfiguration = $Env:BUILDCONFIGURATION
        
    Write-Verbose "- TFS Variables -"
    Write-Verbose "buildAgentHomeDirectory :" $buildAgentHomeDirectory
    Write-Verbose "buildSourcesDirectory :" $buildSourcesDirectory
    Write-Verbose "buildStagingDirectory :" $buildStagingDirectory
    Write-Verbose "buildPlatform :" $buildPlatform
    Write-Verbose "buildConfiguration :" $buildConfiguration
    
    Write-Host "Inputs are the following : "
    $webConfig = $webConfigRelativePath
    $configurationType = $buildConfiguration
    $outputPath = $outPutRelativePath
    Write-Host "`n - WebConfig : "$WebConfig"`n - ConfigurationType : "$ConfigurationType"`n - outputPath : "$outputPath"`n"
    

    
    if($webconfig -match "(.*)\\")
    {
        $buildDirectory = $matches[1]
    }
    else
    {
        throw "Build directory cannot be resolved in"+$webConfig
    }

    Write-Host "Parsing $webConfig to xmlObject..."
    $myXml = CreateXmlTransformableObjectFromXmlFile -xmlFile $webConfig
    
    Write-Host "Getting the list of configuration File listed in $webConfig..."
    $sourcesList = GetListConfigFileToTransform -anXml $myXml
    #Add source file if transform origin is checked
   
    $sourcesList  | Foreach-Object{Write-Host "- "$_ }

    foreach  ($source in $sourcesList)
    {
        if($source)
        {
            $name = GetXmlNameByPath -path $source.configSource; 
            $fullConfigPath = $buildDirectory+"\"+$source.configSource;
            $xdtPath = ConvertConfigPathToXdtPath -myConfigPath $fullConfigPath
            
            Write-Host "`n================ "$name" ================`n"   
            write-Host "`nchecking if xdt file for $name exists..."
            
            if(ResolvePath -thePath $xdtPath){
              
                XmlDocTransform -xml $fullConfigPath -xdt $xdtPath -output "$outputPath$name.config" -vsVersion $VSVersion
                
                $innerXml = get-Content "$outputPath$name.config"
                 foreach ($line in $innerXml){
                     Write-Host $line
                 }
                
                
                Write-Host "`n============= process finished for"$name"config file =============`n"
            }
            else
            {
                Write-Host "Xdt not found in $xdtPath"
            }
             
        }
    }
}finally {
    Trace-VstsLeavingInvocation $MyInvocation
}