# Midnight VM Crashes After a Security Patch: Incident Case Study

A worked incident write-up: six production Hyper-V virtual machines in a fintech environment shut down at exactly midnight for three nights running, taking transaction monitoring offline. This document follows the incident from first report to root cause, fix and process change.

> **Simulated scenario.** The company, timeline and KB number are illustrative. I wrote this case study to practise structured incident handling and change control on a realistic problem; the diagnosis steps, policy settings and script are real Windows Server techniques.

| | |
|---|---|
| **Environment** | Hybrid cloud; internal tools and monitoring dashboards on Hyper-V VMs running Windows Server 2022 |
| **Reported by** | Operations Lead |
| **Issue type** | Virtualisation and patch management |
| **Severity** | Critical: transaction monitoring unavailable |
| **Trigger** | Security update (KB5031234) deployed through WSUS |

## The problem

Every Hyper-V VM hosting a critical application went down at 00:00 each night after the update was approved. The real-time transaction dashboard was unavailable, monitoring agents stopped reporting, and clients received downtime alerts.

## Investigation

1. **Event logs.** The System log showed `wuauclt.exe` initiating a shutdown with the reason *Restart required after update*.
2. **Patch policy.** WSUS was set to restart automatically after installation, and a Group Policy forced the reboot immediately.
3. **Task Scheduler.** A custom task called `SecurityReboot`, left over from testing, ran `shutdown.exe /r` at midnight every day.
4. **Checkpoints.** No checkpoint was taken before the restart, so there was nothing to roll back to and the crash logs were lost.

**Root cause:** two independent mechanisms forcing a restart at the same time (an aggressive update policy and a forgotten test task), with no checkpoint to fall back on.

## Resolution

1. **Disabled the stray task** on all VMs at once using PowerShell remoting.
2. **Changed Group Policy:** enabled *No auto-restart with logged on users for scheduled automatic updates installations* and applied it with `gpupdate /force`.
3. **Moved patching** to 02:00 on weekends, with a checkpoint taken automatically beforehand (script below).
4. **Reconfigured WSUS:** removed auto-approval of critical updates for server VMs and added a manual test stage.
5. **Closed the loop:** logged the incident in the ITSM tool and raised a change request to make patch testing a formal step.

## Pre-patch checkpoint script

[`scripts/create-vm-checkpoint-before-patch.ps1`](scripts/create-vm-checkpoint-before-patch.ps1) creates a named, timestamped checkpoint for every running VM, so a bad update can be rolled back.

```powershell
$VMs = Get-VM | Where-Object { $_.State -eq 'Running' }

foreach ($vm in $VMs) {
    $checkpointName = "$($vm.Name)-PrePatch-$(Get-Date -Format 'yyyyMMdd-HHmm')"
    Checkpoint-VM -VMName $vm.Name -SnapshotName $checkpointName
    Write-Output "Checkpoint created for $($vm.Name): $checkpointName"
}
```

## Lessons learned

- Production VMs should never restart automatically after updates without someone in control of the timing.
- Every scheduled task created during testing needs an owner and a removal date.
- Take a checkpoint before patching virtual machines, every time.
- Monitor scheduled tasks and Windows Update activity centrally, so the next surprise is visible before midnight.

## Tools

Hyper-V Manager · Windows Event Viewer · Task Scheduler · PowerShell Remoting · WSUS · Group Policy Management
