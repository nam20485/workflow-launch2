[Blog Homepage](https://aws.amazon.com/cn/blogs/china/) [Version
__](https://aws.amazon.com/cn/blogs/china/manage-ubuntu-desktop-with-gpu-
using-nice-dcv/#)

## [Amazon AWS Official Blog](https://aws.amazon.com/cn/blogs/china/)

# Managing Ubuntu Desktops with GPUs Using NICE DCV

by [AWS Team](https://aws.amazon.com/cn/blogs/china/author/victor-yuan/ "Posts
by AWS Team") on23 March 2022 in [Networking & Content
Delivery](https://aws.amazon.com/cn/blogs/china/category/networking-content-
delivery/ "View all posts in Networking & Content Delivery") [
Permalink](https://aws.amazon.com/cn/blogs/china/manage-ubuntu-desktop-with-
gpu-using-nice-dcv/) [Share](https://aws.amazon.com/cn/blogs/china/manage-
ubuntu-desktop-with-gpu-using-nice-dcv/#)

  * [](https://www.facebook.com/sharer/sharer.php?u=https://aws.amazon.com/cn/blogs/china/manage-ubuntu-desktop-with-gpu-using-nice-dcv/)
  * [](https://twitter.com/intent/tweet/?text=%E4%BD%BF%E7%94%A8NICE%20DCV%20%E7%AE%A1%E7%90%86%E5%B8%A6%E6%9C%89%20GPU%E7%9A%84Ubuntu%E6%A1%8C%E9%9D%A2&via=awscloud&url=https://aws.amazon.com/cn/blogs/china/manage-ubuntu-desktop-with-gpu-using-nice-dcv/)
  * [](https://www.linkedin.com/shareArticle?mini=true&title=%E4%BD%BF%E7%94%A8NICE%20DCV%20%E7%AE%A1%E7%90%86%E5%B8%A6%E6%9C%89%20GPU%E7%9A%84Ubuntu%E6%A1%8C%E9%9D%A2&source=Amazon%20Web%20Services&url=https://aws.amazon.com/cn/blogs/china/manage-ubuntu-desktop-with-gpu-using-nice-dcv/)
  * [](mailto:?subject=%E4%BD%BF%E7%94%A8NICE%20DCV%20%E7%AE%A1%E7%90%86%E5%B8%A6%E6%9C%89%20GPU%E7%9A%84Ubuntu%E6%A1%8C%E9%9D%A2&body=%E4%BD%BF%E7%94%A8NICE%20DCV%20%E7%AE%A1%E7%90%86%E5%B8%A6%E6%9C%89%20GPU%E7%9A%84Ubuntu%E6%A1%8C%E9%9D%A2%0A%0Ahttps://aws.amazon.com/cn/blogs/china/manage-ubuntu-desktop-with-gpu-using-nice-dcv/)
  * 

## **1\. Background**

### **1.****Introduction to****NICE****DCV******

NICE DCV is a high-performance remote display management protocol that allows
users to securely stream remote desktops and applications from the cloud to
clients over the network. By installing NICE DCV on Amazon EC2, customers can
run GPU-enabled graphics applications or HPC programs, replacing expensive
graphics workstations. The NICE DCV streaming protocol is also used in
multiple services, including Amazon Appstream 2.0, AWS Nimble Studio, and AWS
RoboMaker.

In terms of management mode, NICE DCV can use stand-alone mode to connect
directly to EC2 from the client; or use NICE DCV Connection Gateway, NICE DCV
Session Session Manager Broker and NICE DCV Session Manager Agent for multi-
machine session management.

In terms of compatible models, NICE DCV is widely used with EC2 instances
equipped with GPUs for scenarios requiring 3D rendering, such as graphics
workstations. In practice, DCV can also be deployed on non-GPU instances, such
as the C5 series EC2 instances, for remote management. However, this requires
additional configuration of the xDummy Driver to simulate a GPU. For more
information on this configuration, please refer to the official documentation
and will not be described in this article.

This article describes using NICE DCV to connect directly to an EC2 standalone
deployment.

### **2.****Select the appropriate****Nvidia****driver**

Nvidia provides three types of drivers for GPUs, targeting three computing
modes:

  * Telsa driver, general computing type, corresponding to P3/P4 and other models;
  * Grid driver, suitable for graphics workstations and other scenarios, compatible with Nvidia GPU models such as G4/G5;
  * Gaming driver, suitable for games and 3D, compatible with Nvidia GPU models such as G4/G5.

For detailed descriptions of the three drivers, refer to the reference
documentation at the end of this article. Note that these three drivers differ
from the public drivers downloaded from Nvidia's official website for gaming-
grade graphics cards. When using GPU instances in the cloud, please use the
official drivers provided by Amazon Web Services.

In this experiment, an EC2 G4dn instance is used with the Ubuntu Server 20.04
operating system and the Grid driver.

### **3.****Select****DCV****mode**

In NICE DCV usage scenarios, two modes are supported: Console Sessions
connected to the console and Multi-user Virtual Sessions.

**type** | **Console****Mode** | **Virtual****Mode**  
---|---|---  
operating system | Windows and Linux | Linux only  
Multi-user | Single user per EC2 | EC2 can be used by multiple users  
Permissions | Administrator User | Administrator or ordinary user  
Screen Capture | direct | Each user starts an independent X Server (Xdcv)  
GPU support | support | Supported but requires additional installation of DCV-GL driver  
  
The comparison table above shows that to meet the GPU application requirements
of Ubuntu desktop, using the Console Sessions mode is simpler and more direct.

### **4.****Choose a****Linux****desktop manager**

The Linux window manager varies depending on the operating system. For
example, RHEL 7.x/8.x and CentOS 7.x/8.x use GDM as the default desktop
manager and Gnome3 as the graphical desktop. On the Ubuntu Server 20.04 system
provided in this article, GDM3 is the default desktop manager and Gnome3 is
also used as the graphical desktop.

Please note that NICE DCV does not support the Console Sessions mode of the
LightGDM window manager. Therefore, if you install LightGDM and replace the
system default GDM as the window manager, you can only use the Virtual Session
mode.

To simplify deployment and usage, this article uses the GDM that comes with
Ubuntu Server 20.04 as an example and uses the Console Sessions mode for
configuration.

## **2.****Nvidia****driver installation****under****EC2 Linux**************

### **1.****Start****EC2****and install the desktop graphical environment**

First, boot an Ubuntu Server 20.04 operating system, starting with the Ubuntu
Server 20.04 LTS (HVM) version from the official Quick Start image. When
creating a disk, select the GP3 type, with a recommended capacity of 50GB or
more to facilitate installation of various software packages. In addition to
the necessary remote login management, the security rule group also requires
opening TCP port 8443, which is required by the DCV protocol. If you wish to
use the QUIC protocol to improve access speeds in weak networks, you will also
need to open UDP port 8443.

After creating EC2, log in remotely and perform the upgrade and install the
graphical desktop as root:

    
    
    apt-get update && apt-get upgrade -y
    apt install gdm3 ubuntu-desktop mesa-utils net-tools awscli -y
    sed -i 's/'"#WaylandEnable=false"'/'"WaylandEnable=false"'/g' /etc/gdm3/custom.conf
    systemctl set-default graphical.target
    reboot

PowerShell

### **2.****Preparation for****installing****Nvidia Grid driver******

First upgrade the kernel modules.

    
    
    apt-get upgrade -y linux-aws
    reboot

PowerShell

Install the header files for the current kernel for subsequent kernel module
compilation. Then add the Nvidia public driver name to the kernel module
blacklist.

    
    
    apt-get install -y gcc make linux-headers-$(uname -r)
    cat << EOF | sudo tee --append /etc/modprobe.d/blacklist.conf
    blacklist vga16fb
    blacklist nouveau
    blacklist rivafb
    blacklist nvidiafb
    blacklist rivatv
    EOF
    echo GRUB_CMDLINE_LINUX="rdblacklist=nouveau" >> /etc/default/grub
    update-grub

PowerShell

### **3.****Download and install****Nvidia grid****driver**

Use an EC2 instance with S3 access permissions to obtain the Grid driver from
the S3 bucket. The bucket path is s3://ec2-linux-nvidia-drivers/latest/.
Download the driver to the GPU model.

Execute the following command as root:

    
    
    chmod +x NVIDIA-Linux-x86_64*.run
    /bin/sh ./NVIDIA-Linux-x86_64*.run
    reboot

PowerShell

Note that during the installation process, a warning message will be displayed
saying that the libglvnd configuration file path cannot be found. This will
not affect the installation. Press Enter to continue.

**4.****Test that****the GPU****driver is loaded correctly**

After the installation is complete, you need to reboot. After rebooting,
execute the following command to confirm the Nvidia driver status:

`nvidia-smi -q | head`

If the returned information is similar to the following, it means the
installation is successful.

    
    
    oot@ip-172-31-36-85:~# nvidia-smi -q | head
    
    ==============NVSMI LOG==============
    
    Timestamp                                 : Thu Feb 10 08:37:29 2022
    Driver Version                            : 470.82.01
    CUDA Version                              : 11.4
    
    Attached GPUs                             : 1
    GPU 00000000:00:1E.0
        Product Name                          : Tesla T4
    root@ip-172-31-36-85:~#

PowerShell



### **5.****Configure the display**

If it is a single monitor, execute:

    
    
    rm -rf /etc/X11/XF86Config*
    nvidia-xconfig --preserve-busid --enable-all-gpus
    systemctl isolate multi-user.target
    systemctl isolate graphical.target

PowerShell

If you need up to four 4K displays, execute:

    
    
    rm -rf /etc/X11/XF86Config*
    nvidia-xconfig --preserve-busid --enable-all-gpus --connected-monitor=DFP-0,DFP-1,DFP-2,DFP-3
    systemctl isolate multi-user.target
    systemctl isolate graphical.target

PowerShell

### **6.****Verify that hardware acceleration is effective**

Run the following command:

`sudo DISPLAY=:0 XAUTHORITY=$(ps aux | grep "X.*\-auth" | grep -v grep | sed -n 's/.*-auth \([^ ]\+\).*/\1/p') glxinfo | grep -i "opengl.*version"`

If the following result is returned, it means that the hardware acceleration
is working properly:

    
    
    OpenGL core profile version string: 4.6.0 NVIDIA 470.82.01
    OpenGL core profile shading language version string: 4.60 NVIDIA
    OpenGL version string: 4.6.0 NVIDIA 470.82.01
    OpenGL shading language version string: 4.60 NVIDIA
    OpenGL ES profile version string: OpenGL ES 3.2 NVIDIA 470.82.01
    OpenGL ES profile shading language version string: OpenGL ES GLSL ES 3.20

PowerShell

## **3\. Install****DCV****and start the service**

As mentioned above, this article uses the Console Session configuration.

### **1.****Install****DCV Server**

Execute the following command as root:

    
    
    wget https://d1uj6qtbmh3dt5.cloudfront.net/NICE-GPG-KEY
    gpg --import NICE-GPG-KEY

PowerShell

Visit the NICE DCV official website to download the latest version:

[https://download.nice-dcv.com/](https://download.nice-dcv.com/)

After decompression, enter the directory, for example, the file name is `nice-
dcv-2021.3-11591-ubuntu2004-x86_64`. Execute the installation:

    
    
    wget https://d1uj6qtbmh3dt5.cloudfront.net/nice-dcv-ubuntu2004-x86_64.tgz
    tar zxvf nice-dcv-ubuntu2004-x86_64.tgz
    cd nice-dcv-2021.3-11591-ubuntu2004-x86_64
    apt install ./nice-dcv-server_2021.3.11591-1_amd64.ubuntu2004.deb
    usermod -aG video dcv
    systemctl isolate multi-user.target
    systemctl isolate grphical.target
    systemctl enable dcvserver
    systemctl start dcvserver
    

PowerShell

### **2.****Start****DCV Server Session**

Modify the configuration file to achieve automatic startup. Edit the
/etc/dcv/dcv.conf configuration file and find the following section:

`create-session = true`

In the existing configuration file, remove the # comment symbol in front of
the above parameters. Save and exit, then restart the service:

`systemctl restart dcvserver`

To verify that the session has been started successfully, execute the
following command to view the current session:

`dcv list-sessions`

### **3.****Configure****license****​**

Running DCV on EC2 requires license authorization. The authorization method is
to assign an IAM role to EC2, allowing EC2 to read a specific location in S3
to confirm the license status.

Enter the IAM role and edit an IAM Policy with the following content:

    
    
    {
        "Version": "2012-10-17",
        "Statement": [
           {
               "Effect": "Allow",
               "Action": "s3:GetObject",
               "Resource": "arn:aws:s3:::dcv-license.eu-central-1/*"
           }
        ]
    }

PowerShell

Save the above policy as DCV-License. Find the IAM role currently in use by
EC2 and attach this policy to it. Also, please note that you must replace the
final region suffix in the bucket name in the above rule with the region you
are using.

### **4.****Set the****EC2****operating system user password**

Set passwords for the ubuntu user (EC2 AMI built-in user) and the root user on
this machine. Execute the following command:

    
    
    passwd ubuntu
    passwd root

PowerShell

Set passwords for each. The root password will be used for DCV authentication.
The password of the ordinary user ubuntu will be used to log in to the Gnome
desktop (Gnome prohibits root login by default).

## **4\. Log in to the****Linux****desktop**

### **1.****Install the****DCV****client**

Install the client on the computer you want to log in to the DCV desktop. You
can choose the corresponding version for Windows, Linux, and MacOS. Visit the
NICE DCV official website to download the latest version:

[https://download.nice-dcv.com/](https://download.nice-dcv.com/)

### **2.****Log in**

Start the client and enter the public IP corresponding to EC2.

In the DCV login window, enter the username root and password. DCV will then
open Ubuntu's own Gnome desktop. Log in with the username ubuntu and the
corresponding password to start using Ubuntu.

### **3.****Verify that****3D****acceleration is normal**

To verify that 3D acceleration is working properly, you need to install the
glmark2 tool on the EC2 running Ubuntu.

`apt-get install glmark2`

Execute glmark2 to run the benchmark tool. If the output is normal, it means
that 3D acceleration is working properly.

### **4.****Download****3D****demo environment (optional)**

Run the following command to download and install on EC2 running Ubuntu:

    
    
    wget https://assets.unigine.com/d/Unigine_Superposition-1.1.run
    chmod 755 Unigine_Superposition-1.1.run
    ./Unigine_Superposition-1.1.run

PowerShell

After the installation is complete, you can find the folder
Unigine_Superposition-1.1 on the current Ubuntu user's desktop, enter it,
double-click to execute the Superposition main program to start the 3D
Benchmark test.

### **5.****Use****UDP****protocol to optimize access in weak network
environment (optional)**

By default, DCV uses TCP protocol 8443, which has high network overhead. If
the access environment has high latency, such as in a cross-border WAN
scenario, you can enable the QUIC protocol and switch to UDP transmission. In
this case, you need to modify the configuration file to open port 8443 and
confirm that the security rule group has allowed it.

Edit the configuration file `/etc/dcv/dcv.conf`, find the following section
[connectivity], and modify the configuration as follows:

    
    
    enable-quic-frontend=true
    quic-port=8443
    web-port=8443
    

PowerShell

Restart the service to take effect. Execute the following command:

`systemctl restart dcvserver`

### **6.****Allow clipboard copy and paste (optional)**

Edit the configuration file `/etc/dcv/dcv.conf`and add the following
configuration at the end of the file:

    
    
    [clipboard]
    primary-selection-copy=true

PowerShell

Restart the service to take effect.

`systemctl restart dcvserver`

This completes the deployment of an Ubuntu Server 20.04 instance with a GPU,
and users can start remote work through NICE DCV.

## **V. Summary**

The above configuration process deploys a G4dn EC2 GPU instance based on the
Ubuntu Server 20.04 operating system and remotely manages it using NICE DCV.
The deployment process involves installing the graphical environment,
upgrading the kernel, installing the Nvidia driver, and installing the DCV
server. This allows users to access the EC2 console through Console Sessions
and begin using graphical applications. This article uses the relatively
simple GDM3 + Gnome + Console Sessions model. For more complex configurations,
please refer to the official documentation links at the end of this article.

## **6\. Reference Documents:**

Nvidia driver installation on EC2:

[https://docs.aws.amazon.com/zh_cn/AWSEC2/latest/UserGuide/install-nvidia-
driver.html](https://docs.aws.amazon.com/zh_cn/AWSEC2/latest/UserGuide/install-
nvidia-driver.html)

Introduction to NICE DCV Session Mode:

[https://docs.aws.amazon.com/dcv/latest/adminguide/managing-
sessions.html](https://docs.aws.amazon.com/dcv/latest/adminguide/managing-
sessions.html)

Linux desktop manager choices:

[https://docs.aws.amazon.com/dcv/latest/adminguide/setting-up-installing-
linux-prereq.html#linux-prereq-
gui](https://docs.aws.amazon.com/dcv/latest/adminguide/setting-up-installing-
linux-prereq.html#linux-prereq-gui)

NICE DCV INSTALLATION:

[https://docs.aws.amazon.com/dcv/latest/adminguide/setting-up-installing-
linux.html](https://docs.aws.amazon.com/dcv/latest/adminguide/setting-up-
installing-linux.html)

Install xDummy Driver on non-GPU models:

[https://docs.aws.amazon.com/dcv/latest/adminguide/setting-up-installing-
linux-prereq.html#linux-prereq-
nongpu](https://docs.aws.amazon.com/dcv/latest/adminguide/setting-up-
installing-linux-prereq.html#linux-prereq-nongpu)





## About the Author

![](https://s3.cn-north-1.amazonaws.com.cn/awschinablog/Author/lxy.jpg)

### Liu Xinyou

An AWS Solutions Architect, he previously worked at Parallels and Siemens, and
served as Chief Architect of the Managed Services Department at Atos. With
over a decade of experience in data center and internet technologies, he has
long provided IT consulting and services to leading clients in industries such
as manufacturing and automotive. Since joining AWS, he has been responsible
for sectors such as retail, fast-moving consumer goods, food, and
manufacturing. He specializes in hardware and network design.

TAGS: [Amazon EC2](https://aws.amazon.com/cn/blogs/china/tag/amazon-ec2/) ,
[G4dn](https://aws.amazon.com/cn/blogs/china/tag/g4dn/) ,
[GPU](https://aws.amazon.com/cn/blogs/china/tag/gpu/) , [NICE
DCV](https://aws.amazon.com/cn/blogs/china/tag/nice-dcv/) ,
[Ubuntu](https://aws.amazon.com/cn/blogs/china/tag/ubuntu/)

[ Log in to the console
](https://console.aws.amazon.com/console/home?nc1=f_ct&src=footer-signin-
mobile)

### Learn about AWS

  * [What is AWS?](https://aws.amazon.com/cn/what-is-aws/?nc1=f_cc)
  * [What is cloud computing?](https://aws.amazon.com/cn/what-is-cloud-computing/?nc1=f_cc)
  * [AWS accessibility](https://aws.amazon.com/cn/accessibility/?nc1=f_cc)
  * [What is DevOps?](https://aws.amazon.com/cn/devops/what-is-devops/?nc1=f_cc)
  * [What is a container?](https://aws.amazon.com/cn/containers/?nc1=f_cc)
  * [What is a Data Lake?](https://aws.amazon.com/cn/what-is/data-lake/?nc1=f_cc)
  * [What is Artificial Intelligence (AI)?](https://aws.amazon.com/cn/what-is/artificial-intelligence/?nc1=f_cc)
  * [What is Generative AI?](https://aws.amazon.com/cn/what-is/generative-ai/?nc1=f_cc)
  * [What is Machine Learning (ML)?](https://aws.amazon.com/cn/what-is/machine-learning/?nc1=f_cc)
  * [AWS Cloud Security](https://aws.amazon.com/cn/security/?nc1=f_cc)
  * [Latest News](https://aws.amazon.com/cn/new/?nc1=f_cc)
  * [blog](https://aws.amazon.com/cn/blogs/?nc1=f_cc)
  * [Press release](https://press.aboutamazon.com/press-releases/aws "Press Releases")

### AWS resources

  * [getting Started](https://aws.amazon.com/cn/getting-started/?nc1=f_cc)
  * [Training and certification](https://aws.amazon.com/cn/training/?nc1=f_cc)
  * [AWS Solutions Library](https://aws.amazon.com/cn/solutions/?nc1=f_cc)
  * [Architecture Center](https://aws.amazon.com/cn/architecture/?nc1=f_cc)
  * [Product and Technical FAQs](https://aws.amazon.com/cn/faqs/?nc1=f_dr)
  * [Analytical Report](https://aws.amazon.com/cn/resources/analyst-reports/?nc1=f_cc)
  * [AWS Partners](https://aws.amazon.com/cn/partners/work-with-partners/?nc1=f_dr)

### Developers on AWS

  * [Developer Center](https://aws.amazon.com/cn/developer/?nc1=f_dr)
  * [Software Development Kits and Tools](https://aws.amazon.com/cn/developer/tools/?nc1=f_dr)
  * [.NET on AWS](https://aws.amazon.com/cn/developer/language/net/?nc1=f_dr)
  * [Python on AWS](https://aws.amazon.com/cn/developer/language/python/?nc1=f_dr)
  * [Java running on AWS](https://aws.amazon.com/cn/developer/language/java/?nc1=f_dr)
  * [PHP running on AWS](https://aws.amazon.com/cn/developer/language/php/?nc1=f_cc)
  * [JavaScript running on AWS](https://aws.amazon.com/cn/developer/language/javascript/?nc1=f_dr)

### help

  * [Contact Us](https://aws.amazon.com/cn/contact-us/?nc1=f_m)
  * [Get expert help](https://iq.aws.amazon.com/?utm=mkt.foot/?nc1=f_m)
  * [Submit a support ticket](https://console.aws.amazon.com/support/home/?nc1=f_dr)
  * [AWS re:Post](https://repost.aws/?nc1=f_dr)
  * [Knowledge Center](https://repost.aws/knowledge-center/?nc1=f_dr)
  * [AWS Support Overview](https://aws.amazon.com/cn/premiumsupport/?nc1=f_dr)
  * [legal personnel](https://aws.amazon.com/cn/legal/?nc1=f_cc)
  * [Amazon Web Services is hiring](https://aws.amazon.com/cn/careers/)
  * 

