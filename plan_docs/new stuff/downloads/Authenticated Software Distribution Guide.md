# **Authenticated Software Distribution Guide**

This guide outlines the primary "trusted" paths for distributing consumer software across the three major OS platforms. Authentication ensures the user's OS trusts your application, preventing security warnings (e.g., "Unknown Publisher").

## **Distribution Workflow Diagram**

flowchart TD  
    subgraph Windows \["Windows"\]  
        W\_Source\[Code\] \--\> W\_Build{Distribution Method}  
        W\_Build \--\>|Microsoft Store| W\_MSIX\[Package as MSIX\]  
        W\_MSIX \--\> W\_StoreSub\[Submit to Partner Center\]  
        W\_StoreSub \--\> W\_User1((Trusted Install))  
          
        W\_Build \--\>|Direct/Web| W\_Sign\[Sign .exe/.msi with Cert\]  
        W\_Sign \--\> W\_Smart\[SmartScreen Filter\]  
        W\_Smart \--\>|EV Cert| W\_Rep1\[Instant Trust\]  
        W\_Smart \--\>|Std Cert| W\_Rep2\[Reputation Build-up\]  
        W\_Rep1 & W\_Rep2 \--\> W\_User2((Trusted Install))  
    end

    subgraph macOS \["macOS"\]  
        M\_Source\[Code\] \--\> M\_Sign\[Sign with Dev ID\]  
        M\_Sign \--\> M\_Path{Distribution Path}  
          
        M\_Path \--\>|Mac App Store| M\_Review\[Apple Review Team\]  
        M\_Review \--\> M\_Sand\[Sandbox Required\]  
        M\_Sand \--\> M\_User1((Trusted Install))  
          
        M\_Path \--\>|Direct/Web| M\_Notary\[Send to Notary Service\]  
        M\_Notary \--\> M\_Staple\[Staple Notarization Ticket\]  
        M\_Staple \--\> M\_Gate\[Passes Gatekeeper\]  
        M\_Gate \--\> M\_User2((Trusted Install))  
    end

    subgraph Linux \["Linux"\]  
        L\_Source\[Code\] \--\> L\_Method{Format}  
          
        L\_Method \--\>|Native (.deb/.rpm)| L\_Repo\[Create Repository\]  
        L\_Repo \--\> L\_GPG\[Sign with GPG Key\]  
        L\_GPG \--\> L\_User1\[User Adds Repo & Key\]  
        L\_User1 \--\> L\_Install1((Trusted Update/Install))  
          
        L\_Method \--\>|Universal| L\_Store{Store}  
        L\_Store \--\>|Snap| L\_Snap\[Snap Store / Canonical\]  
        L\_Store \--\>|Flatpak| L\_Flat\[Flathub / Remotes\]  
        L\_Snap & L\_Flat \--\> L\_Install2((Trusted Install))  
    end

## **1\. Windows (Microsoft)**

Windows relies on **Digital Certificates** (X.509) to establish trust.

### **Channel A: Direct Download (.exe/.msi)**

* **Authentication:** You must purchase a Code Signing Certificate (Standard or EV) from a CA like Sectigo or DigiCert.  
* **Mechanism:**  
  1. **Sign:** Use signtool to sign binaries and the installer.  
  2. **SmartScreen:**  
     * **Standard Cert:** Apps may still trigger warnings until they gain "reputation" (download history).  
       * **EV (Extended Validation) Cert:** Grants immediate reputation (no SmartScreen warnings).  
* **Pros:** Full system access, no store fees.  
* **Cons:** Costly certificates (\~$300-$600/yr), manual update management.

### **Channel B: Microsoft Store**

* **Authentication:** Microsoft vets the developer identity during account creation (\~$19 fee for individuals).  
* **Mechanism:**  
  * Package app as MSIX.  
  * Submit to Partner Center.  
  * Microsoft signs the package upon distribution.  
* **Pros:** Auto-updates, seamless trust, higher visibility.  
* **Cons:** Sandboxing restrictions (unless using full-trust capability), revenue cut (unless using own commerce engine).

## **2\. macOS (Apple)**

Apple enforces strict security via **Gatekeeper**. Apps that are not signed and notarized are effectively blocked by default on modern macOS.

### **Channel A: Mac App Store**

* **Authentication:** Apple Developer Program ($99/yr).  
* **Mechanism:**  
  * App must be sandboxed.  
  * Submitted for manual review by Apple.  
* **Pros:** Highest user trust, handled updates.  
* **Cons:** Strict sandboxing (no file system access outside app container), 15-30% revenue cut.

### **Channel B: Direct Distribution (Notarization)**

* **Authentication:** Apple Developer Program ($99/yr).  
* **Mechanism:**  
  1. **Code Sign:** Sign app with "Developer ID Application" certificate.  
  2. **Notarize:** Upload build to Apple's Notary Service (automated malware check).  
  3. **Staple:** Attach the resulting "ticket" to your app/installer.  
* **Pros:** No sandbox required (unless you choose), avoids App Store review delays.  
* **Cons:** App can still be revoked by Apple remotely if malicious behavior is detected.

## **3\. Linux**

Linux trust is based on **GPG (GNU Privacy Guard)** keys and Repositories.

### **Channel A: Native Repositories (.deb / .rpm)**

* **Authentication:** GPG Keys.  
* **Mechanism:**  
  1. Host a repository (e.g., PPA for Ubuntu, COPR for Fedora, or self-hosted S3 bucket).  
  2. Sign the package metadata with a private GPG key.  
  3. **User Action:** User downloads your Public GPG key and adds your repository to their system sources.  
* **Pros:** Deep system integration, native performance.  
* **Cons:** Dependency hell (must build for different distro versions), requires user to manually add trust (terminal commands).

### **Channel B: Universal Stores (Snap & Flatpak)**

* **Authentication:** Store Publisher Vetting.  
* **Snap (Snap Store):**  
  * Controlled by Canonical.  
  * Developers register and publish "Snaps".  
  * **Verified Accounts:** Major publishers can get a "verified" checkmark.  
* **Flatpak (Flathub):**  
  * Community-driven (but standard).  
  * Apps are verified by linking to a GitHub/GitLab repository or proving domain ownership.  
* **Pros:** Works on almost any distro, auto-updates, sandboxed.  
* **Cons:** Larger download sizes, potential theming/integration issues.