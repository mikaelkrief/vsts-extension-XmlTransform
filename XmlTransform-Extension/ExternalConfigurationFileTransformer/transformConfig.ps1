
param
(
    [string][Parameter(Mandatory=$true)]$webConfigRelativePath,
    [string][Parameter(Mandatory=$true)]$outPutRelativePath,
    [string][Parameter(Mandatory=$true)]$vsVersion,
    [string][Parameter(Mandatory=$true)]$cleanOutput

)


    . "$PSScriptRoot\Helpers.ps1"


    $buildConfiguration = $Env:BUILDCONFIGURATION

    if($buildConfiguration -eq " "){
        $buildConfiguration ="release"
    }

    $webConfig = $webConfigRelativePath
    $configurationType = $buildConfiguration
    $outputPath = $outPutRelativePath
    
 
    Write-Verbose "Parameter Values"
    foreach($key in $PSBoundParameters.Keys)
    {
        Write-Verbose ($key + ' = ' + $PSBoundParameters[$key])
    }
    
    if($webconfig -match "(.*)\\")
    {
        $buildDirectory = $matches[1]
    }
    else
    {
        throw "Build directory cannot be resolved in"+$webConfig
    }

    Write-Verbose "Parsing $webConfig to xmlObject..."
    $myXml = CreateXmlTransformableObjectFromXmlFile -xmlFile $webConfig  -vsVersion $vsVersion
    
    Write-Host "Getting the list of configuration File listed in $webConfig..."
    $sourcesList = GetListConfigFileToTransform -anXml $myXml

    $sourcesList  | Foreach-Object{Write-Host "- "$_ }

    foreach  ($source in $sourcesList)
    {
        if($source)
        {
            $name = GetXmlNameByPath -path $source.configSource; 
            $fullConfigPath = $buildDirectory+"\"+$source.configSource;
            $xdtPath = ConvertConfigPathToXdtPath -myConfigPath $fullConfigPath -configurationType $configurationType
            
            Write-Host "Process started for external configuration file $name"   
            Write-Verbose "Checking if xdt file for $name exists..."
            
            if(ResolvePath -thePath $xdtPath){
              
                XmlDocTransform -xml $fullConfigPath -xdt $xdtPath -output "$outputPath$name.config" -vsVersion $vsVersion
                
                $innerXml = get-Content "$outputPath$name.config"
                 foreach ($line in $innerXml){
                     Write-Verbose $line
                 }

                if($cleanOutput  -eq $true){
                    DeleteConfig -configurationType $configurationType -ouputConfigPath "$outputPath$name.config"
                }
                
                
                Write-Host "Process finished for "$name" config file"
            }
            else
            {
                Write-Host "Xdt not found in $xdtPath"
            }
             
        }
    }