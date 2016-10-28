
param
(
    [string][Parameter(Mandatory=$true)]$webConfigRelativePath,
    [string][Parameter(Mandatory=$true)]$outPutRelativePath,
    [string][Parameter(Mandatory=$true)]$vsVersion,
    [string][Parameter(Mandatory=$true)]$cleanOutput

)


    . "$PSScriptRoot\Helpers.ps1"


    $buildConfiguration = $Env:BUILDCONFIGURATION
    
    $b_clean = [boolean]$cleanOutput
    Write-Verbose "b_clean : $b_clean"

    if($buildConfiguration -eq " "){
        $buildConfiguration ="release"
    }
    
    #Write-Host "Inputs are the following : "
    $webConfig = $webConfigRelativePath
    $configurationType = $buildConfiguration
    $outputPath = $outPutRelativePath
    
    #Write-Host "`n - WebConfig : "$WebConfig"`n - ConfigurationType : "$ConfigurationType"`n - outputPath : "$outputPath"`n - vsVersion : "$vsVersion"`n"
    
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

    Write-Host "Parsing $webConfig to xmlObject..."
    $myXml = CreateXmlTransformableObjectFromXmlFile -xmlFile $webConfig  -vsVersion $vsVersion
    
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
            $xdtPath = ConvertConfigPathToXdtPath -myConfigPath $fullConfigPath -configurationType $configurationType
            
            Write-Host "`n================ "$name" ================`n"   
            write-Host "`nchecking if xdt file for $name exists..."
            
            if(ResolvePath -thePath $xdtPath){
              
                XmlDocTransform -xml $fullConfigPath -xdt $xdtPath -output "$outputPath$name.config" -vsVersion $vsVersion
                
                $innerXml = get-Content "$outputPath$name.config"
                 foreach ($line in $innerXml){
                     Write-Host $line
                 }

                if($b_clean){
                   DeleteConfig -configurationType $configurationType -ouputConfigPath "$outputPath$name.config"
                }
                
                
                Write-Host "`n============= process finished for"$name"config file =============`n"
            }
            else
            {
                Write-Host "Xdt not found in $xdtPath"
            }
             
        }
    }