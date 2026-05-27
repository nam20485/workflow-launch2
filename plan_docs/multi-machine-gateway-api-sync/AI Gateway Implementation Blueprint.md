# **Master Implementation Blueprint: Multi-Machine AI Gateway & Secrets Sync**

This blueprint outlines the path to transition from fragmented machine-specific API configurations into a centralized, zero-trust AI Gateway hosted on your Dell Precision 5820 Linux Workstation, accessible from anywhere via Tailscale.

## **1\. High-Level Architecture & Stack**

### **The Target State**

\+------------------------------------------------------------------------------------+  
|                         DELL PRECISION 5820 (Linux Workstation)                    |  
|                                                                                    |  
|   \+-----------------------+                    \+-------------------------------+   |  
|   |   Infisical Vault     | \--(In-Memory)---\>  |            LiteLLM            |   |  
|   | (Phase 2: Self-hosted)|                    |      (Port 4000 Engine)       |   |  
|   \+-----------------------+                    \+-------------------------------+   |  
|               ^                                                ^                   |  
\+---------------|------------------------------------------------|-------------------+  
                |                                                |  
                |          Encrypted Tailscale Tunnel            | (OpenAI API  
                |                                                |  Endpoints)  
                v                                                v  
\+------------------------------------------------------------------------------------+  
|                                CLIENT ENVIRONMENTS                                 |  
|                                                                                    |  
|   \+-----------------------+                    \+-------------------------------+   |  
|   |   Windows Laptop      |                    |     Dell 5820 Local Host      |   |  
|   | (Cursor, Goose, Kilo) |                    |     (Goose, OpenCode CLI)     |   |  
|   \+-----------------------+                    \+-------------------------------+   |  
\+------------------------------------------------------------------------------------+

### **The Technology Stack**

* **VPN Layer:** **Tailscale** (Creates a secure, zero-config overlay network with unique 100.x.y.z IPs).  
* **Gateway Proxy:** **LiteLLM** (Runs as a lightweight container; standardizes all model calls into a unified, OpenAI-compatible API).  
* **Containerization:** **Docker & Docker Compose** (Wraps the gateway and vault for perfect portability).  
* **Secret Management:**  
  * **Phase 1 (POC):** **Doppler** (Free, zero-knowledge SaaS for instant, frictionless API variable streaming).  
  * **Phase 2 (Hardened):** **Infisical** (Self-hosted on the 5820, keeping 100% of keys entirely off third-party cloud infrastructure).  
* **Config Control:** **Chezmoi** (Optional, for syncing local CLI configurations like Goose or Kilo across hosts).

## **2\. Phase 1: The Quick-and-Dirty POC (Velocity First)**

**Objective:** Get LiteLLM running on your Dell 5820, route your Alibaba Model Studio and OpenRouter tokens through it, and query those models from your Windows laptop over Tailscale.

                    \+------------------------------------+  
                    |        DELL 5820 WORKSTATION       |  
                    |                                    |  
                    |   \+----------------------------+   |  
\[Doppler Vault\] \======\> | LiteLLM Docker Container   |   |  
  (SaaS Secrets)    |   | (Port 4000:4000)           |   |  
                    |   \+----------------------------+   |  
                    \+------------------------------------+  
                                      ^  
                                      | Tailscale IP: 100.x.y.z:4000  
                                      |  
                            \[ Windows Laptop \]  
                          (Cursor, Goose, Kilo)

### **Step 1: Secure the Tunnel with Tailscale**

1. **On the 5820 Workstation (Linux):** Install Tailscale:  
   curl \-fsSL \[https://tailscale.com/install.sh\](https://tailscale.com/install.sh) | sh  
   sudo tailscale up

2. **On the Windows Laptop:** Download and install the Tailscale Windows Client. Log in with the same account.  
3. **Verify Connection:** Find your 5820's Tailscale IP (starts with 100.) and ping it from your Windows terminal:  
   ping 100.x.y.z

### **Step 2: Establish the Code Repository**

On your 5820 workstation, set up the project folder to track your config files securely via Git:

mkdir \-p \~/ai-gateway  
cd \~/ai-gateway  
git init

Create a .gitignore to ensure we never leak environment details:

\# \~/ai-gateway/.gitignore  
.env  
.doppler  
\*.log

### **Step 3: Write the LiteLLM Model Routing Config**

This file maps your actual raw API endpoints to clean custom model aliases. Create litellm-config.yaml:

\# \~/ai-gateway/litellm-config.yaml  
model\_list:  
  \# Route 1: Alibaba Model Studio Trial 1  
  \- model\_name: qwen-coder-trial-1  
    litellm\_params:  
      model: openai/qwen2.5-coder-72b-instruct  
      api\_key: os.environ/ALIBABA\_API\_KEY\_1  
      api\_base: \[https://dashscope.aliyuncs.com/compatible-mode/v1\](https://dashscope.aliyuncs.com/compatible-mode/v1)

  \# Route 2: Alibaba Model Studio Trial 2  
  \- model\_name: qwen-coder-trial-2  
    litellm\_params:  
      model: openai/qwen2.5-coder-72b-instruct  
      api\_key: os.environ/ALIBABA\_API\_KEY\_2  
      api\_base: \[https://dashscope.aliyuncs.com/compatible-mode/v1\](https://dashscope.aliyuncs.com/compatible-mode/v1)

  \# Route 3: OpenRouter fallback bucket (allows wildcard routing to any model)  
  \- model\_name: openrouter-fallback  
    litellm\_params:  
      model: openrouter/\*  
      api\_key: os.environ/OPENROUTER\_API\_KEY

general\_settings:  
  master\_key: os.environ/LITELLM\_MASTER\_KEY

### **Step 4: Setup the Quick Doppler Secret Vault**

1. Go to [Doppler.com](https://www.doppler.com/) and create a free personal developer account.  
2. Create a project called ai-gateway.  
3. In the dev environment configuration, add your secrets:  
   * LITELLM\_MASTER\_KEY \= (Create a secure master API key, e.g., sk-my-gateway-key-2026)  
   * ALIBABA\_API\_KEY\_1 \= (Your first Alibaba Studio token)  
   * ALIBABA\_API\_KEY\_2 \= (Your second Alibaba Studio token)  
   * OPENROUTER\_API\_KEY \= (Your OpenRouter API token)  
4. Install the Doppler CLI on your 5820 host:  
   curl \-Ls \[https://cli.doppler.com/install.sh\](https://cli.doppler.com/install.sh) | sh  
   doppler login  
   doppler setup \--project ai-gateway \--config dev

### **Step 5: Write the Docker Compose Blueprint**

This spins up LiteLLM and dynamically pipes your Doppler secrets directly into the container's memory space. Create docker-compose.yml:

\# \~/ai-gateway/docker-compose.yml  
services:  
  litellm:  
    image: ghcr.io/berriai/litellm:main-stable  
    container\_name: litellm-gateway  
    ports:  
      \- "0.0.0.0:4000:4000" \# Expose to all network interfaces (Local & Tailscale)  
    volumes:  
      \- ./litellm-config.yaml:/app/config.yaml  
    environment:  
      \- LITELLM\_MASTER\_KEY=${LITELLM\_MASTER\_KEY}  
      \- ALIBABA\_API\_KEY\_1=${ALIBABA\_API\_KEY\_1}  
      \- ALIBABA\_API\_KEY\_2=${ALIBABA\_API\_KEY\_2}  
      \- OPENROUTER\_API\_KEY=${OPENROUTER\_API\_KEY}  
    command: \[ "--config=/app/config.yaml" \]  
    restart: unless-stopped

### **Step 6: Deploy the POC Gateway**

Run Docker Compose *inside* the Doppler environment wrapper. This injects the cloud secrets instantly into Docker's runtime environment, meaning no .env text files ever touch your hard drive:

doppler run \-- docker compose up \-d

### **Step 7: Complete the Connection Tests**

#### **Test 1: Query Local Host (Directly on 5820\)**

Run this from your 5820 terminal to verify the container is running and translating calls to Alibaba correctly:

curl \-X POST \[http://127.0.0.1:4000/v1/chat/completions\](http://127.0.0.1:4000/v1/chat/completions) \\  
  \-H "Content-Type: application/json" \\  
  \-H "Authorization: Bearer sk-my-gateway-key-2026" \\  
  \-d '{  
    "model": "qwen-coder-trial-1",  
    "messages": \[{"role": "user", "content": "Write a python one-liner to print hello"}\]  
  }'

#### **Test 2: Query over Tailscale (From your Windows Laptop)**

Open a PowerShell or Bash terminal on your Windows laptop and run the exact same curl request, changing only the target IP:

curl \-X POST \[http://100.\](http://100.)x.y.z:4000/v1/chat/completions ^  
  \-H "Content-Type: application/json" ^  
  \-H "Authorization: Bearer sk-my-gateway-key-2026" ^  
  \-d "{\\"model\\": \\"qwen-coder-trial-1\\", \\"messages\\": \[{\\"role\\": \\"user\\", \\"content\\": \\"Test cross-network connection\\"}\]}"

## **3\. Phase 2: The Zero-Trust Privacy Masterpiece (No-Cloud Sovereignty)**

**Objective:** Pull your secrets down from Doppler's cloud and host your own secure secret vault (**Infisical**) locally on the 5820 workstation. Connect the local systems together so secrets never leave your physical machine.

\+-------------------------------------------------------------------------+  
|                          DELL 5820 WORKSTATION                          |  
|                                                                         |  
|  \+------------------------+                  \+-----------------------+  |  
|  |       Infisical        | \--(In-Memory)--\> |        LiteLLM        |  |  
|  | (Self-Hosted Database) |                  |  (Port 4000 Engine)   |  |  
|  \+------------------------+                  \+-----------------------+  |  
\+-------------------------------------------------------------------------+

### **Step 1: Launch Self-Hosted Infisical**

1. Clone the offical docker-compose template for Infisical onto your 5820 workstation:  
   git clone \[https://github.com/Infisical/infisical.git\](https://github.com/Infisical/infisical.git) \~/infisical-vault  
   cd \~/infisical-vault

2. Run the Infisical initialization. This starts the PostgreSQL database, Redis caching layers, and the secure dashboard interface completely offline on your 5820:  
   docker compose up \-d

3. Open your browser on the 5820 and head to http://localhost:8080 (or access it over Tailscale on your Windows laptop at http://100.x.y.z:8080). Create your admin account and make a new project: ai-gateway.

### **Step 2: Set Up Local Token Injection**

1. Install the Infisical CLI tool on your 5820:  
   curl \-1sLf '\[https://dl.cloudsmith.io/public/infisical/infisical-cli/cfg/setup/bash.deb.sh\](https://dl.cloudsmith.io/public/infisical/infisical-cli/cfg/setup/bash.deb.sh)' | sudo \-E bash  
   sudo apt-get install \-y infisical

2. Login to your *self-hosted* vault instance:  
   infisical login \--domain http://localhost:8080

3. Push your API credentials into your local, self-hosted vault via the GUI or CLI:  
   infisical secrets set LITELLM\_MASTER\_KEY=sk-my-gateway-key-2026  
   infisical secrets set ALIBABA\_API\_KEY\_1=your\_key\_1  
   infisical secrets set ALIBABA\_API\_KEY\_2=your\_key\_2  
   infisical secrets set OPENROUTER\_API\_KEY=your\_key\_3

### **Step 3: Bind LiteLLM to Infisical**

Navigate back to your project directory cd \~/ai-gateway and change your docker launch mechanics. You no longer use Doppler Cloud. Instead, the local Infisical daemon intercepts the compose call, pulls keys from your local PostgreSQL secrets DB, and injects them to RAM:

infisical run \--domain http://localhost:8080 \-- docker compose up \-d

### **Step 4: Write automated boot scripts**

To ensure that any hardware reboot or power outage recovers seamlessly, write a system service file. Create a file at /etc/systemd/system/ai-gateway.service:

\[Unit\]  
Description=Zero-Trust Local AI Gateway Service  
After=docker.service tailscaled.service  
Requires=docker.service

\[Service\]  
Type=simple  
WorkingDirectory=/home/YOUR\_LINUX\_USER/ai-gateway  
ExecStart=/usr/bin/infisical run \--domain http://localhost:8080 \-- /usr/bin/docker compose up  
ExecStop=/usr/bin/docker compose down  
Restart=always  
RestartSec=5

\[Install\]  
WantedBy=multi-user.target

Reload and enable the systemd service:

sudo systemctl daemon-reload  
sudo systemctl enable ai-gateway.service  
sudo systemctl start ai-gateway.service

## **4\. Client Configurations (The Final Connection)**

Now that your self-hosted server is serving model traffic flawlessly on port 4000, configure your primary development environments on your laptops:

### **1\. Cursor IDE Setup (Windows & Linux)**

1. Open Cursor's settings by clicking the gear icon in the top right.  
2. Go to **Models** \> **OpenAI API Key**.  
3. Toggle "Override OpenAI Base URL".  
   * **On 5820 Host:** Change to http://127.0.0.1:4000/v1  
   * **On Windows Laptop:** Change to http://100.x.y.z:4000/v1 (Your Tailscale IP)  
4. Input your custom key: sk-my-gateway-key-2026.  
5. Under "Models", add qwen-coder-trial-1, qwen-coder-trial-2, or write openrouter-fallback to call anything.

### **2\. Goose CLI Setup (Unified Terminal)**

Goose uses standard profiles. You can write this configuration file once, and sync it across both systems using Chezmoi or git:

\# \~/.goose/profiles.yaml  
profiles:  
  qwen-central:  
    provider: openai  
    api\_key: sk-my-gateway-key-2026  
    \# On Windows: base\_url: "\[http://100.\](http://100.)x.y.z:4000/v1"  
    \# On 5820 Host: base\_url: "\[http://127.0.0.1:4000/v1\](http://127.0.0.1:4000/v1)"  
    base\_url: "\[http://127.0.0.1:4000/v1\](http://127.0.0.1:4000/v1)"  
    models:  
      \- qwen-coder-trial-1  
      \- qwen-coder-trial-2

## **5\. Security & Maintenance Checklist**

* \[ \] **Firewall Hardening (UFW on Linux):** Verify that port 4000 is blocked on your public network interface but wide open on the Tailscale interface (tailscale0).  
* \[ \] **Check Trial Credits:** Watch your Alibaba model limits. When trial 1 runs out, simply point your client configurations to use qwen-coder-trial-2 instead. No file editing is required.  
* \[ \] **Offline Resilience:** If working purely offline on the 5820 workstation, your system remains functional since all databases and gateway components live local to your hardware loopback adapter.