# **The "Twin Engines" Cluster: High-Performance 2-Node Proxmox Guide**

## **1\. The Mission**

**Objective:** Build a 2-node Hyper-Converged Infrastructure (HCI) cluster that delivers:

1. **Enterprise-grade Reliability:** Using ZFS for data integrity.  
2. **Blistering Speed:** 25Gbps direct-attached storage replication (faster than most enterprise SANs).  
3. **Gaming/Workstation Power:** GPU passthrough for a "local PC" experience inside a VM.

**Topology Diagram:**

       \[ Internet / Home Router \]  
                  |  
        \+---------+---------+  
        |  1GbE / 10GbE Switch |  \<-- Management & Internet Traffic  
        \+----+---------+----+  
             |         |  
      \+------+         \+------+  
      |                       |  
\[ AFTERBURN \]             \[ MACH \]  
| Xeon W-2245             | Xeon W-2245  
| 64GB ECC RAM            | 64GB ECC RAM  
| RX 6700 XT (GPU)        | (No GPU)  
| NVMe Pool (ZFS)         | NVMe Pool (ZFS)  
| IP: 192.168.1.10        | IP: 192.168.1.11  
\+-------------------------+  
      |  25GbE Port 1  | \<==\[ DIRECT CONNECT DAC CABLE \]==\> |  25GbE Port 1  |  
      |   (MTU 9000\)   |                                    |   (MTU 9000\)   |  
      \+----------------+                                    \+----------------+  
      \* Traffic: Storage Sync (ZFS Replication) & VM Migration ONLY

## **2\. Hardware Bill of Materials (BOM)**

*Quantities listed are PER NODE. You need exactly **two** of everything (except the GPU).*

| Component | Specification | Motivation |  
| CPU | Intel Xeon W-2245 | 8 Cores / 16 Threads @ 3.9GHz Base (4.7GHz Turbo). Why: High clock speed is essential for gaming/desktop VMs. Xeon W supports massive RAM and PCIe lanes. |  
| Motherboard | LGA2066 (Chipset C422) | Look for Supermicro X11SRA or ASUS WS C422. Why: C422 is the workstation chipset designed for Xeon W and ECC reliability. X299 works but can be finicky with ECC RAM. |  
| RAM | 64GB+ DDR4 ECC RDIMM | 4x 16GB or 4x 32GB (2666MHz or 2933MHz). Why: ZFS loves RAM (it uses it for read caching). ECC prevents data corruption. Populate all 4 channels for max bandwidth. |  
| Boot Drive | 128GB+ M.2 or SATA SSD | Cheap, reliable SSD. Why: Keep the OS separate from your VM data. If the OS breaks, your data drives remain untouched. |  
| Data Drive | 1TB+ NVMe SSD (Gen3/4) | High endurance NVMe (e.g., Samsung 970/980 Pro, WD Black, or Enterprise U.2). Why: This will be your nvme-pool. High IOPS for smooth VMs. |  
| Fast Network | Mellanox ConnectX-4 Lx | Model: MCX4121A-ACAT (Dual Port 25GbE SFP28). Why: Industry standard for RDMA/RoCE. Native support in Linux. Cheap on eBay (\~$50). |  
| Cable | SFP28 Passive DAC | 0.5m or 1m Direct Attach Copper. Why: Connects the two Mellanox cards directly. No switch required. Zero latency. |  
| GPU | AMD Radeon RX 6700 XT | Node afterburn Only. Why: Powerful enough for 1440p gaming. "Reset Bug" is manageable (see Section 6). |

## **3\. Assembly & BIOS Configuration**

### **A. Physical Assembly**

1. **RAM:** Install sticks in the slots designated for "Quad Channel" (usually color-coded in the manual).  
2. **PCIe Slots:**  
   * **GPU:** Top x16 slot (Node afterburn only).  
   * **Mellanox NIC:** Any x8 or x16 slot. **Do not** put this in a bottom x4 slot; you will throttle the 25Gbps speed.  
3. **Cabling:**  
   * Plug the **DAC Cable** from afterburn Port 1 directly into mach Port 1\.  
   * Plug standard ethernet cables from motherboard LAN ports to your home router.

### **B. BIOS/UEFI Settings (Critical)**

*Enter BIOS on boot (usually Del or F2).*

1. **Advanced \> CPU Configuration:**  
   * **Intel Virtualization Tech (VT-x):** Enabled  
   * **VT-d (Direct I/O):** Enabled (Mandatory for GPU passthrough).  
2. **PCIe / System Agent Config:**  
   * **Above 4G Decoding:** Enabled (Mandatory for modern GPUs).  
   * **SR-IOV Support:** Enabled (Mandatory for networking features).  
   * **Re-Size BAR:** Disabled (Often causes headaches with Passthrough; start disabled).  
3. **Boot:**  
   * **Secure Boot:** Disabled (Proxmox kernel modules are unsigned).  
   * **CSM (Compatibility Support Module):** Disabled (Use pure UEFI mode).

## **4\. Host Setup: Proxmox VE (PVE)**

### **Step 1: Install PVE 8.x**

1. Download ISO from proxmox.com. Flash to USB (using Rufus/Etcher).  
2. Boot Node 1 (afterburn). Follow installer.  
   * **Target Hard Disk:** Select the *Small* Boot SSD (NOT the NVMe data drive).  
   * **Hostname:** afterburn.local  
   * **IP:** 192.168.1.10 (Example)  
3. Repeat for Node 2 (mach).  
   * **Hostname:** mach.local  
   * **IP:** 192.168.1.11 (Example)

### **Step 2: Post-Install Prep (Shell)**

*Run on BOTH nodes via Web Console or SSH.*

1. **Fix Repositories (Free Version):**  
   \# Disable Enterprise Repo  
   sed \-i 's/^/\#/' /etc/apt/sources.list.d/pve-enterprise.list  
   \# Add No-Subscription Repo  
   echo "deb \[http://download.proxmox.com/debian/pve\](http://download.proxmox.com/debian/pve) bookworm pve-no-subscription" \> /etc/apt/sources.list.d/pve-no-sub.list  
   apt update && apt dist-upgrade \-y  
   reboot

2. Enable IOMMU (Kernel Level):  
   Edit the bootloader config: nano /etc/kernel/cmdline  
   Add intel\_iommu=on to the end of the line.  
   * *Save & Exit (Ctrl+O, Enter, Ctrl+X)*  
   * Apply: proxmox-boot-tool refresh  
   * Reboot.

### **Step 3: The "Fast Lane" Network (25GbE)**

Go to Datacenter \>

$$Node$$  
\> System \> Network in the Web UI.

1. Identify your Mellanox interface (usually named enp3s0 or similar).  
2. **Edit** that interface:  
   * **IPv4/CIDR:**  
     * afterburn: 10.10.10.1/24  
     * mach: 10.10.10.2/24  
   * **Gateway:** *Leave Empty* (Traffic must stay local).  
   * **MTU:** 9000 (Jumbo Frames \- Critical for speed).  
3. **Apply Configuration.**  
4. Test: Open Shell on afterburn and ping mach:  
   ping \-s 8000 10.10.10.2  
   If it works, your 25Gbps storage highway is active.

## **5\. Cluster & Storage Strategy**

### **A. Create the Cluster**

1. **On afterburn:** Datacenter \> Cluster \> **Create Cluster**. Name: TwinEngines.  
2. **On afterburn:** Click **Join Information** \> Copy to clipboard.  
3. **On mach:** Datacenter \> Cluster \> **Join Cluster**. Paste info. Enter afterburn root password.  
   * *Wait 30 seconds. You will now see both nodes in one UI.*

### **B. Configure ZFS Shared Storage (Replication)**

*We are NOT using Ceph (too complex for 2 nodes). We are using **ZFS Replication**. It syncs VMs every X minutes.*

1. **Create ZFS Pool (On Both Nodes):**  
   * Go to$$Node$$  
     \> Disks \> ZFS.  
   * **Create: ZFS**.  
   * Name: nvme-pool (MUST be identical on both nodes).  
   * Select your 1TB NVMe drive.  
   * Check: **Add Storage**.  
   * *Result: You now have nvme-pool available on both afterburn and mach.*  
2. **How Replication Works:**  
   * Create a VM on afterburn using nvme-pool disk.  
   * Go to **VM \> Replication \> Add**.  
   * Target: mach. Schedule: \*/5 (Every 5 minutes).  
   * *Effect:* If afterburn dies, you have a copy of the VM on mach that is at most 5 minutes old. You can simply right-click \-\> Start on mach.

## **6\. The "Beast" VM: Gaming with RX 6700 XT**

The RX 6700 XT has a known "Reset Bug" (it fails to restart properly without a host reboot). We fix this with vendor-reset.

### **A. Install vendor-reset (Node afterburn Only)**

*Run in afterburn Shell:*

\# 1\. Install headers and building tools  
apt install pve-headers-$(uname \-r) git dkms build-essential \-y

\# 2\. Clone the fix  
git clone \[https://github.com/gnif/vendor-reset.git\](https://github.com/gnif/vendor-reset.git)  
cd vendor-reset

\# 3\. Build and Install  
dkms install .

\# 4\. Activate it  
echo "vendor-reset" \>\> /etc/modules  
update-initramfs \-u

### **B. VM Configuration (Windows 10/11)**

1. **Create VM:** Windows 10/11 ISO.  
   * **Machine:** q35  
   * **BIOS:** OVMF (UEFI)  
   * **CPU:** Host type, 8 cores.  
   * **RAM:** 16GB+ (Check "Ballooning" \= OFF for gaming).  
2. **Passthrough:**  
   * Hardware \> Add \> **PCI Device**.  
   * Select 0000:xx:00.0 (Your RX 6700 XT).  
   * Check **All Functions** (Passes audio part too).  
   * Check **PCI-Express**.  
   * *Do NOT check "Primary GPU" yet.*  
3. **Install Windows:**  
   * Install Windows normally using the virtual display (Console).  
   * Enable Remote Desktop (RDP) inside Windows.  
4. **Finalize Passthrough:**  
   * Shutdown VM.  
   * Hardware \> Display \> Set to **None** (Headless).  
   * Edit PCI Device \> Check **Primary GPU**.  
   * Start VM.  
   * *Monitor plugged into the GPU should light up. If not, RDP in and install AMD Drivers.*

## **7\. The "Why" (Motivations)**

1. Why Direct Connect?  
   Switching 25Gbps is expensive. A DAC cable costs $20. By wiring nodes back-to-back, you get massive bandwidth with lower latency than any switch can provide. This makes your ZFS replication nearly instant.  
2. Why ZFS Replication vs Ceph?  
   Ceph is magic, but it requires 3 nodes to be safe and fast. On 2 nodes, write speeds suffer (latency penalty). ZFS Replication gives you native NVMe speeds for your running VMs, with the safety of a backup on the second node. It is the "Keep It Simple, Stupid" approach to High Performance.  
3. Why Proxmox?  
   It handles the "split personality" of this cluster perfectly: It is an Enterprise Hypervisor managing your servers, but it is also a KVM host capable of running a Gaming PC (via Passthrough) with near-native performance. Windows Server cannot do GPU passthrough this easily.