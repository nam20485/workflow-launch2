# **Google Cloud "Clean Break" Migration Guide**

**Objective:** Establish intel-agency.com as a primary Google Cloud Organization to guarantee automated KYC (Know Your Customer) approval for the Google for Startups Cloud Program.

## **Phase 1: Domain Decoupling (The Old Workspace)**

*Before you can use intel-agency.com to create a new Workspace, you must release it from your current odbdesignserver.com Workspace.*

* \[ \] **Step 1: Backup Data (Optional but Recommended)**  
  If you have any crucial emails currently sitting in the nmiller@intel-agency.com inbox, back them up using Google Takeout or forward them to another address. Deleting the user/domain will temporarily purge access.  
* \[ \] **Step 2: Delete Users on the Secondary Domain**  
  Log into admin.google.com using your odbdesignserver.com admin credentials. Go to **Directory \> Users**. Delete nmiller@intel-agency.com and any other users specifically tied to the @intel-agency.com domain.  
* \[ \] **Step 3: Remove the Domain**  
  Go to **Account \> Domains \> Manage Domains**. Locate intel-agency.com (currently listed as a Secondary Domain) and click **Remove**.  
* \[ \] **Step 4: Wait for Propagation**  
  *Crucial:* It can take anywhere from 1 hour to 24 hours for Google's global servers to recognize the domain has been released.

## **Phase 2: The New Workspace Setup**

*Establishing the new root identity for the company.*

* \[ \] **Step 1: Sign up for Google Workspace**  
  Go to the [Google Workspace signup page](https://workspace.google.com/pricing.html) and select the **Business Starter** plan ($6/user/month).  
* \[ \] **Step 2: Use Your Existing Domain**  
  During setup, when asked if you have a domain, select "Yes, I have one I can use" and enter intel-agency.com.  
* \[ \] **Step 3: Create the Admin Account**  
  Create your new primary account. You can use nmiller@intel-agency.com or admin@intel-agency.com. This will become your Google Cloud Super Admin.  
* \[ \] **Step 4: Verify Domain Ownership**  
  Follow the prompts to add a TXT record to your domain's DNS settings (wherever you bought the domain, e.g., GoDaddy, Namecheap, Route53) to prove you own it.  
* \[ \] **Step 5: Update MX Records**  
  Update your DNS MX records as prompted to ensure your new Workspace can send and receive email.

## **Phase 3: Generating the Pristine GCP Organization**

*Creating the infrastructure layer.*

* \[ \] **Step 1: Log into Google Cloud**  
  Open an Incognito window and navigate to console.cloud.google.com. Log in using your new nmiller@intel-agency.com Workspace account.  
* \[ \] **Step 2: Accept Terms & Generate Org**  
  Accept the Google Cloud Terms of Service. By simply logging in with a verified Workspace admin account, Google automatically generates a brand new Google Cloud Organization named **intel-agency.com**.  
* \[ \] **Step 3: Verify the Organization**  
  In the top navigation bar of the GCP Console, click the project selector dropdown. You should now see intel-agency.com listed as an Organization node (with a little building icon).  
* \[ \] **Step 4: Create the Billing Account**  
  Go to **Billing \> Manage Billing Accounts** and click **Create Account**.  
  * Name it "Intel Agency Main Billing" (or similar).  
  * Tie it to the intel-agency.com organization.  
  * Enter your LLC's credit card and legal details ("Artificial Intelligence Agency LLC").  
* \[ \] **Step 5: Document the New Billing ID**  
  Copy the new 18-character alphanumeric Billing ID (e.g., XXXXXX-XXXXXX-XXXXXX). This is what you will use on your startup application.

## **Phase 4: The Re-Application**

*Putting it all together for approval.*

* \[ \] **Step 1: Deploy the AegisCore Website**  
  Ensure your agency\_site.jsx updates (removing the consulting language, adding the Pricing tiers) are pushed live to https://intel-agency.com.  
* \[ \] **Step 2: Submit the Application**  
  Go to the Google for Startups Cloud Program page and submit a brand new application.  
  * **Company Name:** Artificial Intelligence Agency LLC  
  * **Website:** https://intel-agency.com  
  * **Email:** nmiller@intel-agency.com  
  * **Billing ID:** \[Your New Billing ID from Phase 3\]

**Result:** When the automated filters check your application, your Email Domain, Website Domain, and Google Cloud Organization Domain will all return a 100% match, while the website perfectly reflects a digital-native SaaS infrastructure product.