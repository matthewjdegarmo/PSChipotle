#Requires -Modules @{ModuleName="Pester";ModuleVersion="5.0.0"}
Remove-Module PSChipotle -ErrorAction SilentlyContinue
Import-Module ([System.IO.Path]::Combine($PSScriptRoot, '..', 'PSChipotle.psd1')) -Force
Describe "PSChipotle Module Public Tests" {
    It "Imports Successfully" {
        Get-Module PSChipotle | Should -Not -BeNullOrEmpty
    }

    Context 'Public Functions' {                
        $PSDefaultParameterValues = @{
            "It:TestCases" = @{ ExcludedFunctions = $script:ExcludedFunctions }
        }
        It 'should import successfully' {
            
            $PublicImportedCommands = (Get-Command -Module PSChipotle).Name
            $PublicFiles = Get-ChildItem ([System.IO.Path]::Combine($PSScriptRoot, '..', 'Functions', 'Public', '*.ps1')) -Exclude *tests.ps1, Aliases.ps1 | ForEach-Object {
                $_
            }
            $PublicImportFailedFunctions = (Compare-Object $PublicImportedCommands $($PublicFiles).BaseName).InputObject


            $PublicImportFailedFunctions = $PublicImportFailedFunctions | Where-Object {$_ -NotIn $script:ExcludedFunctions}
            $PublicImportFailedFunctions | Should -BeNullOrEmpty
        }

        Get-ChildItem ([System.IO.Path]::Combine($PSScriptRoot, '..', 'Functions', 'Public', '*.ps1')) -Exclude *tests.ps1, Aliases.ps1 |
            Where-Object {$_.BaseName -NotIn $script:ExcludedFunctions} | ForEach-Object {
            Context "Test Function: $($_.BaseName)" {
                $PSDefaultParameterValues = @{
                    "It:TestCases" = @{
                        CurrentFunction = $_
                    }
                }
                It "Should register command with Get-Command" {
                    (Get-Command $CurrentFunction.BaseName) | Should -BeOfType [System.Management.Automation.CommandInfo]
                }
                It "Should have comment-based help block" {
                    $CurrentFunction.FullName | Should -FileContentMatch '<#'
                    $CurrentFunction.FullName | Should -FileContentMatch '#>'
                }
                It "Should have SYNOPSIS section in help" {
                    $CurrentFunction.FullName | Should -FileContentMatch '.SYNOPSIS'
                }
                It "Should have DESCRIPTION section in help" {
                    $CurrentFunction.FullName | Should -FileContentMatch '.DESCRIPTION'
                }
                It "Should have EXAMPLE section in help" {
                    $CurrentFunction.FullName | Should -FileContentMatch '.EXAMPLE'
                }
                It "Should have NOTES section in help" {
                    $CurrentFunction.FullName | Should -FileContentMatch '.NOTES'
                }
                It "Should have .PARAMETER help for each defined parameter" {
                    $Params = ((Get-Command $CurrentFunction.BaseName).Parameters).Keys | Where-Object { $_ -notin ([System.Management.Automation.PSCmdlet]::CommonParameters) -and $_ -notin ([System.Management.Automation.PSCmdlet]::OptionalCommonParameters) }
                    $Params | Foreach-Object {
                        $CurrentFunction.FullName | Should -FileContentMatch ".PARAMETER $_"
                    }
                }
                It "Should be an advanced function" {
                    $CurrentFunction.FullName | Should -FileContentMatch 'function'
                    $CurrentFunction.FullName | Should -FileContentMatch 'cmdletbinding'
                    $CurrentFunction.FullName | Should -FileContentMatch 'param'
                }
                It "Should have Begin and End Regions" {
                    $CurrentFunction.FullName | Should -FileContentMatch "#Region"
                    $CurrentFunction.FullName | Should -FileContentMatch "#EndRegion"
                }
                It "Should be valid PowerShell code" {
                    $FileContent = Get-Content -Path $CurrentFunction.FullName -ErrorAction Stop
                    $Errors = $null
                    $null = [System.Management.Automation.PSParser]::Tokenize($FileContent, [ref]$errors)
                    $errors.Count | Should -be 0
                }
            }
        }
    }
    Context 'Aliases' {
        It 'should import successfully' {
            $AliasesPath = [System.IO.Path]::Combine($PSScriptRoot, '..', 'Functions', 'Public', 'Aliases.ps1')
            if (Test-Path $AliasesPath) {
                $ModuleAliases = (Get-Content $AliasesPath | Select-String "Set-Alias").Count
                $ActualAliases = (Get-Command -Module PSChipotle -CommandType Alias).Count
            }
            else {
                $ModuleAliases = 0
                $ActualAliases = 0
            }
            $ActualAliases | Should -Match $ModuleAliases
        }
    }
    Context 'Files' {
        It 'LICENSE should exist' {
            $LicenseFile = [System.IO.Path]::Combine($PSScriptRoot, '..', 'LICENSE')
            $isLicense = Get-ChildItem $LicenseFile
            $isLicense | Should -Be $true
        }
        It 'CHANGELOG.md should exist' {
            $ChangelogFile = [System.IO.Path]::Combine($PSScriptRoot, '..', 'CHANGELOG.md')
            $isChangelog = Get-ChildItem $ChangelogFile
            $isChangelog | Should -Be $true
        }
    }
}
<# Currently no private functions defined.
InModuleScope PSChipotle {
    Describe "PSChipotle Module Private Tests" {
        Context 'Private Functions' {
            It 'should import successfully' {
                $PrivateImportedCommands = (Get-Command -Module PSChipotle).Name
                $PrivateFiles = Get-ChildItem ([System.IO.Path]::Combine($PSScriptRoot,'..','Functions','Private','*.ps1')) -Exclude *tests.ps1, Aliases.ps1 | ForEach-Object {
                                    $_
                                }
                $PrivateImportSuccessfulFunctions = Compare-Object $PrivateImportedCommands $PrivateFiles.BaseName -IncludeEqual -ExcludeDifferent
                $PrivateImportSuccessfulFunctions.InputObject | Should -Be $PrivateFiles.BaseName
            }
        }
    }
}#>

