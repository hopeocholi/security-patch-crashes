# Create a Hyper-V checkpoint for every running VM before patching,
# so a faulty update can be rolled back.

$VMs = Get-VM | Where-Object { $_.State -eq 'Running' }

foreach ($vm in $VMs) {
    $checkpointName = "$($vm.Name)-PrePatch-$(Get-Date -Format 'yyyyMMdd-HHmm')"
    Checkpoint-VM -VMName $vm.Name -SnapshotName $checkpointName
    Write-Output "Checkpoint created for $($vm.Name): $checkpointName"
}
