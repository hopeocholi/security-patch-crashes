# security-patch-crashes

🏢 Company Context:
A fintech startup, NovaPay, runs sensitive customer transaction services in a hybrid cloud environment. Internal tools and monitoring dashboards are hosted on Hyper-V virtual machines running Windows Server 2022. A routine security patch applied by automation caused all 6 VMs to crash unexpectedly at exactly midnight over the past 3 nights.

# 🚨 VM Crash Triggered by Midnight Security Patch (NovaPay Case Study)

**Date:** 2025-04-30  
**Reported By:** Operations Lead  
**Issue Type:** Virtualization / Patch Management  
**Urgency:** Critical – System Downtime Affected Transaction Monitoring  

---

## 🧩 Problem Summary

All Hyper-V virtual machines hosting critical applications shut down at **exactly 00:00 AM** each night since a new **KB5031234 security patch** was deployed via WSUS.

**Impacts:**
- Real-time transaction dashboard unavailable
- Monitoring agents stopped reporting
- Service downtime alerts sent to clients

---

## 🧪 Initial Investigation

1. **Reviewed Windows Event Logs**
   - System logs showed:  
     `The process C:\Windows\System32\wuauclt.exe initiated the shutdown of computer...`  
     Code: `Restart required after update`.

2. **Analyzed WSUS Patch Policy**
   - Confirmed automatic restart scheduled post-patch
   - Group Policy misconfigured to **force reboot immediately after update**

3. **Examined Task Scheduler**
   - Found a custom "SecurityReboot" task (created during a test) set to run `shutdown.exe /r` at midnight every day

4. **Review VM Checkpoints and Snapshots**
   - No automatic checkpointing before restart  
   - No rollback possible; crash logs lost

---

## ✅ Resolution Steps

1. **Disabled Faulty Scheduled Task on All VMs**
   - Used remote PowerShell command to disable `SecurityReboot` task across all VMs

2. **Updated Group Policy**
   - Set `No auto-restart with logged on users for scheduled automatic updates installations` to **Enabled**
   - Applied policy via `gpupdate /force`

3. **Created Custom Update Script**
   - Scheduled patching at **2:00 AM on weekends**
   - Configured scripted checkpoint creation before patching (see script below)

4. **Reconfigured WSUS Rules**
   - Removed auto-approval of critical updates for server VMs  
   - Introduced manual testing phase for security patches

5. **Documentation & Change Control**
   - Logged incident in internal ITSM tool  
   - Submitted change request to formalize patch testing process

---

## 🧠 Lessons Learned

- Never apply auto-reboot policies to production VMs without user control
- All scheduled tasks must be tracked and documented during testing
- Use checkpoints before patching virtual machines
- Centralize monitoring of scheduled tasks and Windows Updates

---

## 🛠️ Tools Used

- Hyper-V Manager  
- Windows Event Viewer  
- Task Scheduler  
- PowerShell Remoting  
- WSUS Console  
- Group Policy Editor
