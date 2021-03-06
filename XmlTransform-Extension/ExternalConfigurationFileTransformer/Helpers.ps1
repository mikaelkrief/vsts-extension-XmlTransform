function CreateXmlTransformableObjectFromXmlFile($xmlFile, $vsVersion)
{
    $dllPath = "C:\Program Files (x86)\MSBuild\Microsoft\VisualStudio\v"+$vsVersion+"\Web\Microsoft.Web.XmlTransform.dll"
    Write-Verbose "dllPath for Microsoft.Web.XmlTransform.dll : $dllPath"
    Add-Type -LiteralPath $dllPath
    $xmlobj = New-Object Microsoft.Web.XmlTransform.XmlTransformableDocument;
    $xmlobj.PreserveWhitespace = $true;
    $xmlobj.Load($xmlFile);
    return $xmlobj;
}

function XmlDocTransform($xml, $xdt, $output, $vsVersion)
{
    if (!$xml -or !(Test-Path -path $xml -PathType Leaf)) {
        throw "File not found ! $xml";
    }
    if (!$xdt -or !(Test-Path -path $xdt -PathType Leaf)) {
        throw "File not found ! $xdt";
    }

    $config = CreateXmlTransformableObjectFromXmlFile -xmlFile $xml  -vsVersion $vsVersion
    $transf = New-Object Microsoft.Web.XmlTransform.XmlTransformation($xdt);
    
    if ($transf.Apply($config) -eq $false)
    {
        throw "Transformation failed..."
    }
    $config.Save($output);
}

function GetListConfigFileToTransform($anXml)
{
    return $anXml.SelectNodes("/configuration/*") | where {$_.configSource -Like "*.config"}
}

function GetXmlNameByPath($path)
{
    
    $found = $path -match '[\\]([a-zA-Z0-9]+)[].config]'; 

    if($found)
    {
        return $matches[1]
    }
    else
    {
        Throw "Name cannot be resolved in "+$path
        
    }
    
}

function ResolvePath($thePath)
{

    if (Test-Path -path $thePath)
    {
        return $true
      
    }else
    {
        return $false
        
    } 
    
}

function ConvertConfigPathToXdtPath($myConfigPath, $configurationType)
{
    
    if($myConfigPath -match "(.*\.)")
    {
        $fullConfigDirectory = $matches[1]
    }
    else
    {
        Throw "Path cannot be resolved in "+$myConfigPath  
    }
    
    return "$fullConfigDirectory$configurationType.config" 
}


function DeleteConfig($ouputConfigPath, $configurationType)
{
    
    if($ouputConfigPath -match "(.*\.)")
    {
        $outputConfigDirectory = $matches[1]
    }
    else
    {
        Throw "Path cannot be resolved in "+$ouputConfigPath  
    }
    
    $fileToDelete = "$outputConfigDirectory$configurationType.config" 
    Write-Host "Delete file : "$fileToDelete
    Remove-Item -Path $fileToDelete -Force
}